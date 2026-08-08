function appData = updateVisualizationAndArea(appData)
    cla(appData.ax_poly_handle); cla(appData.ax_heat_handle);
    hold(appData.ax_poly_handle, 'on');
    
    % Show the Goal on the GUI - if there are holes, show them too.
    if isfield(appData, 'Goal') && ~isempty(appData.Goal.Vertices)
        % Create a polyshape for the goal.
        goalShape = polyshape(appData.Goal.Vertices(:,1), appData.Goal.Vertices(:,2));        
        % Handle holes.
        num_holes = length(appData.Goal.Holes);        
        if(num_holes > 0)
            assert(num_holes <= 1, 'May need to handle more than 1 hole.');
            holeShape = appData.Goal.Holes{1};
            % Subtract the hole from the main goal shape
            goalShape = subtract(goalShape, holeShape);
        end

        plot(appData.ax_poly_handle, goalShape, 'FaceColor', [0.3 0.3 0.3], ...
             'EdgeColor', [1 1 0], 'LineStyle', ':', 'LineWidth', 2);
    end

    % Show the Goal on the GUI - if there are holes, show them too.
    if(appData.user_params.use_inflated_goal_in_solver)
         % If inflated then goalShape.Vertices contains the inflation, so
         % this leak into the solver through "combinedImg".
         goalMask = calculateCoveredArea(goalShape.Vertices, appData.Grid.xmin, appData.Grid.xmax, appData.Grid.ymin, appData.Grid.ymax, appData.user_params.flag_quantize_pix_area);
         combinedImg = goalMask;
         num_holes = length(appData.Goal.Holes);  
         for nh = 1:num_holes
             holesMask = calculateCoveredArea(appData.GoalHoles{nh}.Vertices, appData.Grid.xmin, appData.Grid.xmax, appData.Grid.ymin, appData.Grid.ymax, appData.user_params.flag_quantize_pix_area);
             combinedImg = goalMask - holesMask;
         end   
    else
        % Generate the Goal 2D Array "combinedImg" from transformed Tiles.
        % Now for each of our Tiles poly.Vertices is NOT inflated, so the inflation will not be 
        % included (note that holes will be included).
        combinedImg = zeros(appData.GridHeight, appData.GridWidth);
        for k = 1:length(appData.Polygons)
            poly = appData.Polygons{k};
            lw = 0.5; if k == appData.ActivePolygonIndex, lw = 2.5; end 
            
            if appData.showSolution
                patch('Faces', 1:size(poly.Vertices,1), 'Vertices', poly.Vertices, ...
                    'FaceColor', poly.Color, 'FaceAlpha', 0.6, 'EdgeColor', 'w', ...
                    'LineWidth', lw, 'Parent', appData.ax_poly_handle);
            end
            mask = calculateCoveredArea(poly.Vertices, appData.Grid.xmin, appData.Grid.xmax, appData.Grid.ymin, appData.Grid.ymax, appData.user_params.flag_quantize_pix_area);
            combinedImg = combinedImg + mask;
        end
    end
    
    % remove any hint from the problem, i.e. inner pixels should
    % all be 1. Only on edges its ok to leave fractional values (e.g. if
    % the edge is diagonal, or txy is fractional).
    [Gx, Gy] = gradient(combinedImg);
    gradMag = sqrt(Gx.^2 + Gy.^2);
    edgeMask = (gradMag > 0);
    insideMask = combinedImg & ~edgeMask;
    combinedImg(insideMask) = 1.0;
    % assure range is [0.0, 1.0]
    combinedImg = max(0, min(combinedImg, 1.0));
 
    appData.CombinedEdgeMask = double(insideMask);
    appData.CombinedAreasInsideMask = double(insideMask);
    appData.CombinedAreas = combinedImg;

    if appData.showSolution
        imagesc(appData.ax_heat_handle, appData.CombinedAreas); colormap(appData.ax_heat_handle, hot); 
    else
        imagesc(appData.ax_heat_handle, zeros(appData.GridHeight, appData.GridWidth));
    end
    set(appData.ax_heat_handle, 'YDir', 'normal');
end