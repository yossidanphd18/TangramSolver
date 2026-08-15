function appData = timerBlink_Wrapper(~, ~, appData) 
    appData = toggleBlink(appData); 
    % (appData now contains the updated blinkCounter)
end