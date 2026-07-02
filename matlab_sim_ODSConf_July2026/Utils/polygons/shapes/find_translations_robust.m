function [valid_region, is_line] = find_translations_robust(Gx, Gy, Px, Py, boundary_only, inflate_tol)
    G = polyshape(Gx, Gy);
    P = polyshape(Px, Py);
    
    % 1. Buffer G for the tolerance
    G_buffered = polybuffer(G, inflate_tol);
    
    % 2. Get the "Bounding Box" of possible translations
    % We don't need to check the whole world, just where P overlaps G.
    [Gx_min, Gx_max, Gy_min, Gy_max] = deal(min(Gx), max(Gx), min(Gy), max(Gy));
    [Px_min, Px_max, Py_min, Py_max] = deal(min(Px), max(Px), min(Py), max(Py));
    
    % 3. Optimization: Instead of Minkowski, we find the "Shrunk" G
    % For concave shapes, the most robust way to find the region where P fits
    % is to erode G by the "radius" of P, but that's complex.
    % Faster approach: Use your intersection method, but ADD an edge check.
    
    pts = P.Vertices;
    % Initial guess using vertex-only intersection (your original method)
    valid_region = translate(G_buffered, -pts(1,1), -pts(1,2));
    for i = 2:size(pts, 1)
        shifted_G = translate(G_buffered, -pts(i,1), -pts(i,2));
        valid_region = intersect(valid_region, shifted_G);
    end
    
    % % 4. THE FIX: Prune "Corner Cutters"
    % % Some points in feasible_poly might have vertices inside G but edges outside.
    % % We sample the edges of P to ensure the body is inside.
    % if ~isempty(valid_region.Vertices)
    %     % Sample points along the edges of P
    %     num_samples = 5; % Check 5 points per edge
    %     sample_pts = [];
    %     for i = 1:size(pts,1)
    %         p1 = pts(i,:);
    %         p2 = pts(mod(i, size(pts,1))+1, :);
    %         t = linspace(0, 1, num_samples)';
    %         sample_pts = [sample_pts; (1-t)*p1 + t*p2];
    %     end
    % 
    %     % Test the center of the feasible_poly (or a grid of its points)
    %     % against the sample points. If any sample point of P falls outside G,
    %     % that translation is invalid.
    %     % For your grid search, we can let getCoveredArea handle the final check.
    % end

    is_line = (area(valid_region) < 1e-3) && (valid_region.NumRegions > 0);

    dbg = 1;
end