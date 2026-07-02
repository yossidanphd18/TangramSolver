function appData = timerBlink_Wrapper(~, ~, appData) 
    % 1. Logic Only
    appData = toggleBlink(appData); 
    % (appData now contains the updated blinkCounter)
end