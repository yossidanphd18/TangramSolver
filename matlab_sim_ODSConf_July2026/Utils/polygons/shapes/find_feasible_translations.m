function [feasible_txy] = find_feasible_translations(Gxy, Pxy, boundary_only, grid_x_range, grid_y_range, grid_step, inflate_tol, PreveScaleHints)
    % 1. Get initial candidates
    [valid_region, ~] = find_translations_robust(Gxy(:,1), Gxy(:,2), Pxy(:,1), Pxy(:,2), boundary_only, inflate_tol);
    [mask_full, xx, yy] = getCoveredArea(valid_region, grid_x_range(1), grid_x_range(2), grid_y_range(1), grid_y_range(2), grid_step, boundary_only);
    candidate_txy = [xx(mask_full), yy(mask_full)];
    
    if isempty(candidate_txy)
        feasible_txy = [];
        return;
    end

    % 2. Setup polyshapes
    G_poly = polyshape(Gxy(:,1), Gxy(:,2));
    if inflate_tol ~= 0
        G_poly = polybuffer(G_poly, inflate_tol);
    end
    P_poly = polyshape(Pxy(:,1), Pxy(:,2));
    % P_ref_orig = Pxy(1,:); 

    % 3. Strict Filtering Loop using Area Subtraction
    keep = false(size(candidate_txy, 1), 1);
    yd_dbg_i = 1;
    area_TH = 1e-2;
    for i = 1:size(candidate_txy, 1)
        % Move P to candidate position
        % shift = candidate_txy(i,:) - P_ref_orig;
        shift = candidate_txy(i,:);

        P_moved = translate(P_poly, shift(1), shift(2));
        
        % BODY CHECK: Subtract G from P. 
        % If P is inside G, the subtraction P - G should result in zero area.
        remnant = subtract(P_moved, G_poly);

        % exclude if far from previous scale solution.
        exclude_this_option = 0;
        if(~isempty(PreveScaleHints.txy_prev_scale) && (norm(shift - PreveScaleHints.txy_prev_scale) > PreveScaleHints.norm_thresh))
            exclude_this_option = 1;
        end

        if(i == yd_dbg_i)
            dbg = 1;
        end

        % We use a tiny epsilon for area to account for floating point noise
        if ((area(remnant) < area_TH) && (~exclude_this_option))
            keep(i) = true;
        end
    end
    
    feasible_txy = candidate_txy(keep, :);
end