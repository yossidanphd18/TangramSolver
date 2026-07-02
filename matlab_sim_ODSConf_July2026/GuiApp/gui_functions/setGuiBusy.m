function appData = setGuiBusy(appData, isBusy)
    % Determine the state string
    state = 'on'; 
    if isBusy, state = 'off'; end
    
    % Use the handle stored in appData instead of the local variable
    allBtns = findall(appData.hControlPanel, 'Style', 'pushbutton');
    
    % Filter out the stop button so it stays enabled during 'Busy' mode
    otherUI = setdiff(allBtns, appData.hStopBtn);
    
    % Get popup menus from the same panel
    allMenus = findall(appData.hControlPanel, 'Style', 'popupmenu');
    
    % Apply the enable/disable state
    set([otherUI; allMenus], 'Enable', state);
    
    if isBusy
        set(appData.hStopBtn, 'Enable', 'on');
        set(appData.hStatusText, 'Visible', 'on');
        drawnow; 
        
        % Manage the timer (stored in appData)
        appData.blinkCounter = 0; 
        start(appData.blinkTimer);
    else
        set(appData.hStopBtn, 'Enable', 'off');
        stop(appData.blinkTimer); 
        set(appData.hStatusText, 'Visible', 'off');
    end
    
    drawnow;
end