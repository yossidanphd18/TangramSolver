function appData = toggleBlink(appData)
    if ishandle(appData.hStatusText)
        appData.blinkCounter = appData.blinkCounter + 1;
        if appData.blinkCounter <= 20
            set(appData.hStatusText, 'Visible', 'on');
        elseif appData.blinkCounter <= 25
            set(appData.hStatusText, 'Visible', 'off');
        else
            appData.blinkCounter = 0;
        end
    end
end