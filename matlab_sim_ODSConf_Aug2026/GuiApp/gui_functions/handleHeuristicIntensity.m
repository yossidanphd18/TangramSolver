function [appData] = handleHeuristicIntensity(appData)
    % 1. Read the intensity from the slider
    % Works for both uicontrol and uislider via dot notation
    heurIntensity = appData.hHeurSlider.Value;
    
    % 2. Logic for tough problems
    if (ismember(appData.puzzle_id, appData.user_params.list_tough_challenges) && (heurIntensity < 0.7))
        appData.heurIntensity = 0.7;
        is_tough_card = 1;
    else
        appData.heurIntensity = 0.05;
        is_tough_card = 0;
    end
    
    % 3. Update the slider knob position
    appData.hHeurSlider.Value = heurIntensity;
    
    % 4. Update the text label using your isWeb flag
    newText = sprintf('Value: %.2f', heurIntensity);
    
    if appData.isWeb  % Checking your specific flag
        % Web Mode: Use 'Text' property for uilabel
        appData.hHeurValueText.Text = newText;
    else
        % Desktop Mode: Use 'String' property for uicontrol
        appData.hHeurValueText.String = newText;
    end
    
    % 5. Force UI Refresh
    drawnow;
    
    if(is_tough_card)
        fprintf('\n---> Forcing high heuristic intensity %.2f to %s (tough card)\n', ...
            heurIntensity, appData.puzzle_id);
    end
end
