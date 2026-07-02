function appData = stopSolver_Callback(src, ~, appData)
    % % Find the main figure window that contains the button
    % fig = ancestor(src, 'figure');
    % 
    % % Pull the current appData struct out of the figure's UserData
    % appData = get(fig, 'UserData');
    
    % Update the state
    appData.stopRequested = true;
    
    % Update the UI components (using the handles stored in appData)
    set(appData.hStatusText, 'String', 'STOPPING...', ...
        'ForegroundColor', 'r', 'Visible', 'on');
    
    % % VERY IMPORTANT: Save the modified appData back into the figure
    % set(fig, 'UserData', appData);
    
    % Force the UI to refresh
    drawnow;
end