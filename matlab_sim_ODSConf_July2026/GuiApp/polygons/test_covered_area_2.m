clc; clear; close all;

SCALE = 25;

% --- Goal  Coordinates ---
%Gx = [0, 2/sqrt(2) + sqrt(2)/4, 2/sqrt(2) + sqrt(2)/4, 1/sqrt(2)] * SCALE;
%Gy = [0, 0,                              1/sqrt(2),                   1/sqrt(2)] * SCALE;

Gx = [67          121.800775541957          121.800775541957           88.920310216783];
Gy = [ 67                        67           88.920310216783           88.920310216783];

% --- Polygon  Coordinates ---
%Px = [0, 1/sqrt(2), 1/sqrt(2)] * SCALE;
%Py = [0, 0,             1/sqrt(2)] * SCALE;
%Py = Py*0.5;

Px = [67                      82.5                     90.25                     74.75];
Py = [67                        67                     74.75                     74.75];

% 1. Get your valid region (assume it returns a polyshape or line)
boundary_only_1 = false;
[valid_region_1, is_line] = find_translations_robust(Gx, Gy, Px, Py, boundary_only_1);

boundary_only_2 = true;
[valid_region_2, is_line] = find_translations_robust(Gx, Gy, Px, Py, boundary_only_2);

% 2. Define grid parameters
g_xmin = 0;  g_xmax = max(Gx)+5;
g_ymin = 0;  g_ymax = max(Gy)+5;
g_step = 1; % Grid resolution (distance between dots)

% 3. Get filled mask (Interior + Edges)
[mask_full, X, Y] = getCoveredArea3b(valid_region_1, g_xmin, g_xmax, g_ymin, g_ymax, g_step, boundary_only_1);

% 4. Get edges only mask
[mask_edge, X, Y] = getCoveredArea3b(valid_region_2, g_xmin, g_xmax, g_ymin, g_ymax, g_step, boundary_only_2);

% --- 4. Visualization 1 ---
figure('Color', 'w'); hold on; axis equal; box on;

pp = polyshape(Px, Py);
plot(pp, 'FaceColor',  [0.5 0.6 0.9], 'EdgeColor', 'b', 'LineWidth', 1.5);

gg = polyshape(Gx, Gy);
plot(gg, 'FaceColor', [0.5 0.6 0.9], 'EdgeColor', 'm', 'LineWidth', 1.5);

% Plot the smooth polygon boundary
plot(valid_region_1, 'FaceColor', [0.9 0.9 0.9], 'EdgeColor', 'k', 'LineWidth', 1.5);

% Plot the Grid Points
% We plot FALSE points as small gray dots
plot(X(~mask_full), Y(~mask_full), '.', 'Color', [0.8 0.8 0.8]);

% We plot TRUE points (covered) as bold red dots
plot(X(mask_full), Y(mask_full), 'o', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r', 'MarkerSize', 4);

title(sprintf('Rasterization of Valid Region (Step Size = %d)', g_step));
xlabel('X Grid'); ylabel('Y Grid');
legend('Translated Poly', 'Goal Region', 'Valid Region (Poly)', 'Grid Outside', 'Grid Inside (Covered)');
xlim([g_xmin g_xmax]); ylim([g_ymin g_ymax]);

% Display Matrix Info
fprintf('Grid Dimensions: %d x %d\n', size(mask_full));
fprintf('Total Points: %d\n', numel(mask_full));
fprintf('Points Inside: %d\n', sum(mask_full(:)));

% --- 4. Visualization 2 ---
figure('Color', 'w'); hold on; axis equal; box on;

pp = polyshape(Px, Py);
plot(pp, 'FaceColor',  [0.5 0.6 0.9], 'EdgeColor', 'b', 'LineWidth', 1.5);

gg = polyshape(Gx, Gy);
plot(gg, 'FaceColor', [0.5 0.6 0.9], 'EdgeColor', 'm', 'LineWidth', 1.5);

% Plot the smooth polygon boundary
plot(valid_region_2, 'FaceColor', [0.9 0.9 0.9], 'EdgeColor', 'k', 'LineWidth', 1.5);

% Plot the Grid Points
% We plot FALSE points as small gray dots
plot(X(~mask_edge), Y(~mask_edge), '.', 'Color', [0.8 0.8 0.8]);

% We plot TRUE points (covered) as bold red dots
plot(X(mask_edge), Y(mask_edge), 'o', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r', 'MarkerSize', 4);

title(sprintf('Rasterization of Valid Region (Step Size = %d)', g_step));
xlabel('X Grid'); ylabel('Y Grid');
legend('Translated Poly', 'Goal Region', 'Valid Region (Poly)', 'Grid Outside', 'Grid Inside (Covered)');
xlim([g_xmin g_xmax]); ylim([g_ymin g_ymax]);

% Display Matrix Info
fprintf('Grid Dimensions: %d x %d\n', size(mask_edge));
fprintf('Total Points: %d\n', numel(mask_edge));
fprintf('Points Inside: %d\n', sum(mask_edge(:)));


function [valid_region, is_line] = find_translations_robust(Gx, Gy, Px, Py, boundary_only)
    G = polyshape(Gx, Gy);
    P = polyshape(Px, Py);
    
    % 1. Buffer G to handle the tolerance
    G_buffered = polybuffer(G, 0.02);
    
    % 2. Minkowski Subtraction: Find the Feasible Region (where P is inside G)
    pts = P.Vertices;
    feasible_poly = translate(G_buffered, -pts(1,1), -pts(1,2));
    
    for i = 2:size(pts, 1)
        shifted_G = translate(G_buffered, -pts(i,1), -pts(i,2));
        feasible_poly = intersect(feasible_poly, shifted_G);
    end
    
    % 3. Determine if we return the full area or just the perimeter
    if boundary_only
        % Extract boundary coordinates and re-wrap in a polyshape
        [bx, by] = boundary(feasible_poly);
        valid_region = polyshape(bx, by);
    else
        valid_region = feasible_poly;
    end
    
    % 4. Area check for "is_line" 
    % (Based on the original feasible area before extracting boundary)
    is_line = (area(feasible_poly) < 1e-3) && (feasible_poly.NumRegions > 0);
end

% function [valid_poly, is_line] = find_translations_robust(Gx, Gy, Px, Py)
%     G = polyshape(Gx, Gy);
%     P = polyshape(Px, Py);
% 
%     % 1. Buffer G to handle your specific tolerance needs
%     G_buffered = polybuffer(G, 0.02);
% 
%     % 2. Minkowski Subtraction (Correctly finds where P is inside G)
%     pts = P.Vertices;
%     valid_poly = translate(G_buffered, -pts(1,1), -pts(1,2));
% 
%     for i = 2:size(pts, 1)
%         shifted_G = translate(G_buffered, -pts(i,1), -pts(i,2));
%         valid_poly = intersect(valid_poly, shifted_G);
%     end
% 
%     % 3. Area check for "is_line"
%     is_line = (area(valid_poly) < 1e-3) && (valid_poly.NumRegions > 0);
% end

function [mask, X, Y] = getCoveredArea3b(valid_region, g_xmin, g_xmax, g_ymin, g_ymax, step, edges_only)
% GETCOVEREDAREA2 Rasterizes a polyshape into a boolean grid mask with strict boundaries.
%
% Usage:
%   [mask, X, Y] = getCoveredArea2(valid_region, xmin, xmax, ymin, ymax, step, edges_only)

    if nargin < 7
        edges_only = false;
    end

    % 1. Create the Grid
    [X, Y] = meshgrid(g_xmin:step:g_xmax, g_ymin:step:g_ymax);
    
    % Initialize empty mask
    mask = false(size(X));

    % 2. Check Input Validity
    is_poly = isa(valid_region, 'polyshape');
    if is_poly
        % Check if the polygon is effectively a line (area ~ 0)
        is_degenerate_line = area(valid_region) <= (eps * perimeter(valid_region));
        [bx, by] = boundary(valid_region);
    else
        % It's a point list (Nx2 matrix) -> Treat as line
        is_degenerate_line = true; 
        if isempty(valid_region), return; end
        bx = valid_region(:,1);
        by = valid_region(:,2);
    end

    % --- LOGIC SPLIT ---

    % CASE A: Standard Area (edges_only = false AND it has actual area)
    % Use strict geometric inclusion. No "thick" buffering.
    if ~edges_only && is_poly && ~is_degenerate_line
        
        % Flatten grid for checking
        in_vec = isinterior(valid_region, X(:), Y(:));
        
        % Reshape back to grid
        mask = reshape(in_vec, size(X));
        
        return; % Done! We don't run the edge thickener logic.
    end

    % CASE B: Line Mode (edges_only = true OR it is a zero-area line)
    % We must use distance checking because 'isinterior' is empty for lines.
    
    if isempty(bx), return; end

    % Threshold: Tightened to 0.5 to reduce "bleeding" into neighbor pixels
    % 0.5 is the minimum needed to ensure a line doesn't slip between grid points.
    dist_threshold = step * 0.5; 

    for i = 1:length(bx)-1
        p1 = [bx(i), by(i)];
        p2 = [bx(i+1), by(i+1)];
        
        % Bounding box optimization
        min_x = min(p1(1), p2(1)) - step;
        max_x = max(p1(1), p2(1)) + step;
        min_y = min(p1(2), p2(2)) - step;
        max_y = max(p1(2), p2(2)) + step;
        
        roi_idx = (X >= min_x & X <= max_x) & (Y >= min_y & Y <= max_y);
        
        if ~any(roi_idx(:)), continue; end
        
        x_roi = X(roi_idx);
        y_roi = Y(roi_idx);
        
        dists = point_to_segment_dist(x_roi, y_roi, p1, p2);
        
        current_mask_vals = mask(roi_idx);
        mask(roi_idx) = current_mask_vals | (dists <= dist_threshold);
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