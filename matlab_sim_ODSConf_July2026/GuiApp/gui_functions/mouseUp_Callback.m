function appData = mouseUp_Callback(src, ~, appData)
    % % Find the main figure window that contains the button
    % fig = ancestor(src, 'figure');
    % 
    % % Pull the current appData struct out of the figure's UserData
    % appData = get(fig, 'UserData');

    appData.isDragging = false;

    % % VERY IMPORTANT: Save the modified appData back into the figure
    % set(fig, 'UserData', appData);
end
