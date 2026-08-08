function appData = mouseMove_Callback(src, ~, appData)

    % % Find the main figure window that contains the button
    % fig = ancestor(src, 'figure');
    % % Pull the current appData struct out of the figure's UserData
    % appData = get(fig, 'UserData');

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
    % % VERY IMPORTANT: Save the modified appData back into the figure
    % set(fig, 'UserData', appData);
end