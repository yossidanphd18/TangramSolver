function [appData] = setToughnessFlag(appData)
    appData.run_params.is_tough_challenge = ismember(appData.puzzle_id, appData.user_params.list_tough_challenges);
end
