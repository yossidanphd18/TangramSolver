function [gurobi_params, GP] = getGurobiSpecificParams(GP)
    
    if(GP.isWeb || ~GP.user_params.gurobi_display)
        % gurobi_params.OutputFlag = 0;
        gurobi_params.OutputFlag = 1;
        gurobi_params.LogToConsole = 0;
    else
        gurobi_params.OutputFlag = 1;
    end

    if(GP.isWeb || ~GP.user_params.gurobi_logfile)
        gurobi_params.LogFile = '';
    else
        logfile_suffix = ['_iter_', num2str(GP.iter_number),'.txt'];
        gurobi_params.logfile = [GP.db_save_folder_path , ['gurobi_logfile', char(datetime('now'), '_yyyyMMdd_HHmmss'), logfile_suffix]];
    end

    gurobi_params.TimeLimit = GP.user_params.time_limit_secs; % max solve time in seconds.
    gurobi_params.FeasibilityTol = 1e-5 ;
    gurobi_params.IntFeasTol = 1e-6 ;
    gurobi_params.MIPGap = 0.001;
    gurobi_params.OptimalityTol = 1e-5 ;
    gurobi_params.Method = 1;
	gurobi_params.Heuristics = GP.gurobi_params.Heuristics;
    gurobi_params.MIPFocus = 1 ;
    
    if(~GP.user_params.encode_Z_leq_q_as_convex_soc)
        gurobi_params.NonConvex = 2;
    end

    gurobi_params.PreQLinearize = 1;    % Force quadratic linearization early     
    gurobi_params.PrePasses = 3;        % Limit the number of presolve passes
    gurobi_params.Presolve = 1;         % Conservative presolve effort

    gurobi_params.ImproveStartGap = 0.59 ;
    
    [gurobi_params, GP] = handleSelectedPuzzles(gurobi_params, GP);

end

function [gurobi_params, GP] = handleSelectedPuzzles(gurobi_params, GP)

    toughPuzzlesList = {'shape58', 'shape38', 'shape61'};

    if ismember(GP.puzzle_id, toughPuzzlesList)
        gurobi_params.MIPGap = 0.1;
        gurobi_params.ImproveStartGap = 0.59;
    end

	% Try different params with this puzzle.
    % if(strcmp(GP.puzzle_id,'shape35'))
    %     gurobi_params.Heuristics = 0.4;
    %     % gurobi_params.Method = 2;
    %     % gurobi_params.MIPFocus = 1 ;       
    %     % gurobi_params.NonConvex = 2;
    %     % gurobi_params.TimeLimit = 35 * 60;
    % end

    % An exaple where we observed that no need for more than ~10 mins, 
    % even if Gap is ~70-80%!
    if(strcmp(GP.puzzle_id,'shape58'))
        gurobi_params.TimeLimit = 10 * 60;
    end
end

