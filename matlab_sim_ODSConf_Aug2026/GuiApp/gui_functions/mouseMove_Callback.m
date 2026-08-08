function appData = mouseMove_Callback(src, ~, appData)

    if appData.isDragging
        ax = appData.ax_poly_handle; 
        cp = get(ax, 'CurrentPoint');
        idx = appData.dragPolygonIndex;
        appData.Polygons{idx}.T = appData.initialPolyT + ([cp(1,1), cp(1,2)] - appData.startDragMousePoint);
        appData.Polygons{idx}.Vertices = transformPolygon(appData.Polygons{idx}.OriginalVertices, ...
            appData.Polygons{idx}.T(1), appData.Polygons{idx}.T(2), ...
            appData.Polygons{idx}.Theta, appData.Polygons{idx}.FlipID);
        appData = updateVisualizationAndArea(appData);
        drawnow limitrate;
    end

end