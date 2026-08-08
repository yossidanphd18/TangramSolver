function [valid_region, is_line] = find_translations_minkowski(Gx, Gy, Px, Py, GoalHoles, inflate_tol, flag_use_convex_hull)
    % FIND_TRANSLATIONS_MINKOWSKI Computes the valid region where 
    % a convex tile P fits entirely inside G.
    % 
    % Optional inputs:
    %   inflate_tol          - buffering distance on G (default = 0)
    %   flag_use_convex_hull - if true, uses the convex hull of G (default = true)
    
    if nargin < 6, inflate_tol = 0; end
    if nargin < 7, flag_use_convex_hull = true; end
    
    % Initialize polyshapes
    G = polyshape(Gx, Gy);
    P = polyshape(Px, Py);
    
    % Optional convex hull approximation on G
    if flag_use_convex_hull
        [k_hull, ~] = convhull(G.Vertices(:,1), G.Vertices(:,2));
        G = polyshape(G.Vertices(k_hull, 1), G.Vertices(k_hull, 2));
    end
    
    % Optional tolerance buffering on G
    if inflate_tol ~= 0
        G = polybuffer(G, inflate_tol);
    end
    
    % Subtract the holes from G.
    goalShape = polyshape(Gx, Gy);
    num_holes = length(GoalHoles);
    for nh = 1:num_holes
	    holeShape = GoalHoles{nh};
	    % Subtract the hole from the main goal shape
	    goalShape = subtract(goalShape, holeShape);
    end
    Gx = goalShape.Vertices(:,1);
    Gy = goalShape.Vertices(:,2);
    G = polyshape(Gx, Gy);

    % Get vertices of P
    pts = P.Vertices;
    num_pts = size(pts, 1);
    
    % --- RIGOROUS CONTAINMENT (Vertex-shifting intersection) ---
    valid_region = translate(G, -pts(1,1), -pts(1,2));
    for i = 2:num_pts
        shifted_G = translate(G, -pts(i,1), -pts(i,2));
        valid_region = intersect(valid_region, shifted_G);
    end
    
    % Check if the resulting valid region is degenerated into a line/point
    is_line = (area(valid_region) < 1e-3) && (valid_region.NumRegions > 0);

    % --- VISUALIZATION ---
    enable_viz = 0;
    if(enable_viz)
        figure('Name', 'Minkowski Valid Region Visualization', 'Position', [100, 100, 1100, 500]);
        
        % Subplot 1: Container G (and its Convex Hull if enabled) and Tile P
        subplot(1, 2, 1);
        plot(G, 'FaceColor', [0.8 0.8 0.8], 'FaceAlpha', 0.6, 'EdgeColor', 'k', 'LineWidth', 1.5);
        hold on;
        
        if valid_region.NumRegions > 0
            [cX, cY] = centroid(valid_region);
            P_translated = translate(P, cX, cY);
            plot(P_translated, 'FaceColor', [0.3 0.6 0.9], 'FaceAlpha', 0.6, 'EdgeColor', 'b', 'LineWidth', 1.5);
            title(sprintf('Container G (Hull=%d) & Tile P (At valid pose)', flag_use_convex_hull));
        else
            plot(P, 'FaceColor', [0.9 0.4 0.3], 'FaceAlpha', 0.6, 'EdgeColor', 'r', 'LineWidth', 1.5);
            title('Container G & Tile P (No Valid Translation)');
        end
        
        hold off;
        xlabel('X'); ylabel('Y');
        legend({'Container G', 'Tile P (at valid pose)'}, 'Location', 'best');
        grid on;
        axis equal;
        
        % Subplot 2: Valid Translation Region Domain
        subplot(1, 2, 2);
        if valid_region.NumRegions > 0
            plot(valid_region, 'FaceColor', [0.4 0.8 0.4], 'FaceAlpha', 0.6, 'EdgeColor', [0 0.5 0], 'LineWidth', 1.5);
            hold on;
            if exist('cX', 'var')
                plot(cX, cY, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
                legend({'Valid Region', 'Centroid Translation Point'}, 'Location', 'best');
            end
            hold off;
            title(sprintf('Valid Translation Region (Convex Hull Mode: %d)', flag_use_convex_hull));
        else
            title('Valid Translation Region (Empty)');
        end
        xlabel('Translation X'); ylabel('Translation Y');
        grid on;
        axis equal;

        dbg = 1;
    end
end