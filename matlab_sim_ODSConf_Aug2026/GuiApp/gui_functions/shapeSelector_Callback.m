function appData = shapeSelector_Callback(h, ~, appData)

    % % Get the figure handle and pull appData out
    % fig = ancestor(h, 'figure');
    % appData = get(fig, 'UserData');

    % Update logic based on the dropdown selection
    appData.puzzle_id = h.String{h.Value};
    appData.showSolution = false;
    % Update the UI button appearance
    set(appData.hShowBtn, 'String', 'SHOW SOLUTION', 'BackgroundColor', [0.2 0.4 0.6]);
    
    % No need - its salled in loadInitialPolygons()
    % [appData] = handlePuzzleSpecificAspects(appData);

    appData = updateProblemParams(appData);

    appData = loadInitialPolygons(appData);
    
    appData = handleSavedDB(appData, false);

    % % write back the appData to the figure.
    % set(fig, 'UserData', appData);
end