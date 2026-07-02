function appData = updateVisualizationAndArea(appData)
    cla(appData.ax_poly_handle); cla(appData.ax_heat_handle);
    hold(appData.ax_poly_handle, 'on');
    
    if isfield(appData, 'Goal') && ~isempty(appData.Goal.Vertices)
        patch('Faces', 1:size(appData.Goal.Vertices,1), 'Vertices', appData.Goal.Vertices, ...
            'FaceColor', [0.3 0.3 0.3], 'EdgeColor', [1 1 0], 'LineStyle', ':', ...
            'LineWidth', 2, 'Parent', appData.ax_poly_handle);
    end
    
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
    
    % remove any hint from the problem, i.e. inner pixels should
    % all be 1. Only on edges its ok to leave fractional values (e.g. if
    % the edge is diagonal, or txy is fractional).
    [Gx, Gy] = gradient(combinedImg);
    gradMag = sqrt(Gx.^2 + Gy.^2);
    edgeMask = (gradMag > 0);
    insideMask = combinedImg & ~edgeMask;
    combinedImg(insideMask) = 1.0;

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