function [GP] = getSpecificOptParams(GP)

    assert(GP.flag_which_part == 2, 'Only part 2 should get here.');

    %======================================================================
    % flags
    %======================================================================
    if(~isfield(GP,'flag_use_integer_ai'))
        error('Please set flag_use_integer_ai in GP struct!');
        % GP.flag_use_integer_ai = 1;
    end

    if(strcmp(GP.challenge_type,'polygons'))
        GP.MIN_q = 0;
        GP.MAX_Zi = max(GP.npcs+3,10);
        GP.MAX_q = 1e4;
    end
    
	GP.lambda_q = 1e3;

    % specificPuzzlesList = {'shape52', 'shape34', 'shape61'};
    % if ismember(GP.puzzle_id, specificPuzzlesList)
    %     GP.lambda_q = 1.0;
    % end

end