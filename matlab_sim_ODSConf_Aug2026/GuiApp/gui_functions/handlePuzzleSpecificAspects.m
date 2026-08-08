function [appData] = handlePuzzleSpecificAspects(appData)

    % Set specific parameters for specific puzzles.
    if(ismember(appData.puzzle_id, appData.user_params.list_tough_challenges))
        if(appData.user_params.flag_use_disqualified_db)
            idx = find(strcmp(appData.puzzle_id, appData.user_params.list_tough_challenges));
            appData.user_params.target_inflation_width = appData.user_params.list_inflation_width(idx);
        end
    end

end
