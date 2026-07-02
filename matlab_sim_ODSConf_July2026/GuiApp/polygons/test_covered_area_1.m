clc; clear; close all;

SCALE = 25;

% --- Goal  Coordinates ---
Gx = [0, 2/sqrt(2) + sqrt(2)/4, 2/sqrt(2) + sqrt(2)/4, 1/sqrt(2)] * SCALE;
Gy = [0, 0,                              1/sqrt(2),                   1/sqrt(2)] * SCALE;

% --- Polygon  Coordinates ---
Px = [0, 1/sqrt(2), 1/sqrt(2)] * SCALE;
Py = [0, 0,             1/sqrt(2)] * SCALE;
Py = Py*0.5;

% 1. Get your valid region (assume it returns a polyshape or line)
[valid_region, is_line] = find_translations_robust(Gx, Gy, Px, Py);

% 2. Define grid parameters
g_xmin = 0;  g_xmax = max(Gx)+5;
g_ymin = 0;  g_ymax = max(Gy)+5;
g_step = 1; % Grid resolution (distance between dots)

% 3. Get filled mask (Interior + Edges)
edges_only = false;
[mask_full, X, Y] = getCoveredArea3(valid_region, g_xmin, g_xmax, g_ymin, g_ymax, g_step, edges_only);

% 4. Get edges only mask
edges_only = true;
[mask_edge, X, Y] = getCoveredArea3(valid_region, g_xmin, g_xmax, g_ymin, g_ymax, g_step, edges_only);

% --- 4. Visualization 1 ---
figure('Color', 'w'); hold on; axis equal; box on;

pp = polyshape(Px, Py);
plot(pp, 'FaceColor',  [0.5 0.6 0.9], 'EdgeColor', 'b', 'LineWidth', 1.5);

gg = polyshape(Gx, Gy);
plot(gg, 'FaceColor', [0.5 0.6 0.9], 'EdgeColor', 'm', 'LineWidth', 1.5);

% Plot the smooth polygon boundary
plot(valid_region, 'FaceColor', [0.9 0.9 0.9], 'EdgeColor', 'k', 'LineWidth', 1.5);

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
plot(valid_region, 'FaceColor', [0.9 0.9 0.9], 'EdgeColor', 'k', 'LineWidth', 1.5);

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