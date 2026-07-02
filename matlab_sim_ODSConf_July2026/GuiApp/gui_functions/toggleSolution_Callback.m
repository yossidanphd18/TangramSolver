function appData = toggleSolution_Callback(src, ~, appData)
    % % Find the main figure window that contains the button
    % fig = ancestor(src, 'figure');
    % 
    % % Pull the current appData struct out of the figure's UserData
    % appData = get(fig, 'UserData');

    appData.showSolution = ~appData.showSolution;
    if appData.showSolution
        set(src, 'String', 'HIDE SOLUTION', 'BackgroundColor', [0.6 0.2 0.2]);
    else
        set(src, 'String', 'SHOW SOLUTION', 'BackgroundColor', [0.2 0.4 0.6]);
    end

    appData = updateVisualizationAndArea(appData);

    % % VERY IMPORTANT: Save the modified appData back into the figure
    % set(fig, 'UserData', appData);
end