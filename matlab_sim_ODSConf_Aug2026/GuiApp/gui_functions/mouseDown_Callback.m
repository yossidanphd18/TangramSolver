function appData = mouseDown_Callback(src, ~, appData)
    % % Find the main figure and pull the appData
    % fig = ancestor(src, 'figure');
    % appData = get(fig, 'UserData');

    % Safety Check: Only allow interaction if appropriate
    % (Note: Ensure your logic matches whether dragging is allowed during solution mode)
    if ~appData.showSolution, return; end 

    % Get click coordinates relative to the polygon axis
    ax = appData.ax_poly_handle; 
    cp = get(ax, 'CurrentPoint');
    x_click = cp(1,1); 
    y_click = cp(1,2);
    
    poly_idx = 0;
    
    % Hit-testing: Check if click is inside any polygon (top-to-bottom)
    for k = length(appData.Polygons):-1:1
        if inpolygon(x_click, y_click, appData.Polygons{k}.Vertices(:, 1), appData.Polygons{k}.Vertices(:, 2))
            poly_idx = k; 
            break;
        end
    end
    
    % If a polygon was clicked, initiate dragging state
    if poly_idx > 0
        appData.isDragging = true;
        appData.dragPolygonIndex = poly_idx;
        appData.startDragMousePoint = [x_click, y_click];
        appData.initialPolyT = appData.Polygons{poly_idx}.T;
        appData.ActivePolygonIndex = poly_idx;
        
        % Refresh UI to show the selected piece (e.g., thicker border)
        appData = updateVisualizationAndArea(appData);
    end

    % % Save the modified appData back into the figure
    % set(fig, 'UserData', appData);
end