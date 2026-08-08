function [mask, X, Y] = getCoveredArea4(valid_region, g_xmin, g_xmax, g_ymin, g_ymax, step, edges_only)
    if nargin < 7, edges_only = false; end

    % 1. Create the Grid
    [X, Y] = meshgrid(g_xmin:step:g_xmax, g_ymin:step:g_ymax);
    mask = false(size(X));

    % 2. Check Input Validity
    is_poly = isa(valid_region, 'polyshape');
    if is_poly
        % Area threshold: if area is zero (or near zero), isinterior will always fail.
        is_degenerate_line = area(valid_region) <= (1e-6 * perimeter(valid_region));
        [bx, by] = boundary(valid_region);
    else
        is_degenerate_line = true; 
        if isempty(valid_region), return; end
        bx = valid_region(:,1);
        by = valid_region(:,2);
    end

    % --- LOGIC SPLIT ---

    % CASE A: Standard Area 
    % We only use isinterior if the user wants full area AND it actually has area.
    if ~edges_only && is_poly && ~is_degenerate_line
        in_vec = isinterior(valid_region, X(:), Y(:));
        mask = reshape(in_vec, size(X));
        
        % Optimization: If isinterior found points, we are done.
        % If it's so thin that isinterior missed everything, we fall through to line logic.
        if any(mask(:)), return; end
    end

    % CASE B: Line/Edge Mode
    % If we are here, it's either edges_only=true OR a zero-area polygon.
    if isempty(bx), return; end

    % Distance threshold: 0.5 * step ensures we catch the grid points nearest the line.
    dist_threshold = step * 0.51; 

    for i = 1:length(bx)-1
        p1 = [bx(i), by(i)];
        p2 = [bx(i+1), by(i+1)];
        
        % Bounding box optimization for speed
        min_x = min(p1(1), p2(1)) - dist_threshold;
        max_x = max(p1(1), p2(1)) + dist_threshold;
        min_y = min(p1(2), p2(2)) - dist_threshold;
        max_y = max(p1(2), p2(2)) + dist_threshold;
        
        roi_idx = (X >= min_x & X <= max_x) & (Y >= min_y & Y <= max_y);
        if ~any(roi_idx(:)), continue; end
        
        x_roi = X(roi_idx);
        y_roi = Y(roi_idx);
        
        dists = point_to_segment_dist(x_roi, y_roi, p1, p2);
        mask(roi_idx) = mask(roi_idx) | (dists <= dist_threshold);
    end
end

function d = point_to_segment_dist(px, py, p1, p2)
    vx = p2(1) - p1(1);
    vy = p2(2) - p1(2);
    len_sq = vx^2 + vy^2;
    if len_sq == 0
        d = sqrt((px - p1(1)).^2 + (py - p1(2)).^2);
        return;
    end
    t = ((px - p1(1)) * vx + (py - p1(2)) * vy) / len_sq;
    t = max(0, min(1, t));
    cx = p1(1) + t * vx;
    cy = p1(2) + t * vy;
    d = sqrt((px - cx).^2 + (py - cy).^2);
end