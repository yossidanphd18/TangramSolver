clc; clear; close all;

% % --- Goal  Coordinates ---
% SCALE = 25;
% Gx = [0, 2/sqrt(2) + sqrt(2)/4, 2/sqrt(2) + sqrt(2)/4, 1/sqrt(2)] * SCALE;
% Gy = [0, 0,                              1/sqrt(2),                   1/sqrt(2)] * SCALE;
% 
% % --- Polygon  Coordinates ---
% Px = [0, 1/sqrt(2), 1/sqrt(2)] * SCALE;
% Py = [0, 0,             1/sqrt(2)] * SCALE;
% Py = Py*0.5;

Gx = [40, 75.3553, 75.3553, 54.1421];
Gy = [40, 40, 54.1421, 54.1421];
Px = [40, 25.85, 40];
Py = [40, 25.85, 25.85];

% 1. Get your valid region (assume it returns a polyshape or line)
[valid_region, is_line] = find_translations_robust(Gx, Gy, Px, Py);

% 2. Define grid parameters
g_xmin = 0;  g_xmax = max(Gx)+5;
g_ymin = 0;  g_ymax = max(Gy)+5;
g_step = 1; % Grid resolution (distance between dots)

% 3. Get filled mask (Interior + Edges)
edges_only = false;
[mask_full, X, Y] = getCoveredArea4(valid_region, g_xmin, g_xmax, g_ymin, g_ymax, g_step, edges_only);

% 4. Get edges only mask
edges_only = true;
[mask_edge, X, Y] = getCoveredArea4(valid_region, g_xmin, g_xmax, g_ymin, g_ymax, g_step, edges_only);

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
