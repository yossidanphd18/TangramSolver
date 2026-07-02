function [gurobi_params] = getGurobiSpecificParams(GP)
    
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
        gurobi_params.logfile = [GP.db_save_folder_path , ['gurobi_logfile', char(datetime('now'), '_yyyyMMdd_HHmmss'), '.txt']];
    end

    % if(GP.isWeb)
    %     gurobi_params.OutputFlag = 0;
    %     gurobi_params.LogFile = '';
    % else
    %     gurobi_params.OutputFlag = 1; % Normal output for your laptop
    %     gurobi_params.logfile = [GP.db_save_folder_path , ['gurobi_logfile', char(datetime('now'), '_yyyyMMdd_HHmmss'), '.txt']];
    % end

    gurobi_params.nonconvex = 2;    
    gurobi_params.MIPFocus = 1 ;
    gurobi_params.ImproveStartGap = 0.59 ;
    
    gurobi_params.IntFeasTol = 1e-6 ;
    gurobi_params.FeasibilityTol = 1e-5 ;
    gurobi_params.OptimalityTol = 1e-5 ;
    gurobi_params.Presolve = 1;         % Conservative presolve effort
    gurobi_params.PrePasses = 3;        % Limit the number of presolve passes
    gurobi_params.PreQLinearize = 1;    % Force quadratic linearization early     
    
	gurobi_params.Heuristics = GP.gurobi_params.Heuristics;
    gurobi_params.MIPGap = 0.0001; % 0.01%
    
    scale_TH = 1.0;
    if(GP.user_params.scale_gain == 1.0)
         gurobi_params.MIPGap = 0.0001; % 0.01%
    elseif(GP.user_params.scale_gain < scale_TH)
        gurobi_params.MIPGap = 0.0015; % 0.15%
    else
        gurobi_params.MIPGap = 0.0001; % 0.01%
        gurobi_params.Heuristics = 0.7;   % Spend 70% of time on heuristics
        gurobi_params.Cuts = 2;           % Aggressive cut generation
        gurobi_params.NumericFocus = 1;   % Improve numerical precision
        gurobi_params.PreSolve = 2;
    end

    % For challenges that were found to take long time:
     if(GP.is_tough_challenge || (GP.user_params.scale_gain ~= 1.0))
        gurobi_params.NonConvex = 2;
        gurobi_params.Method = 1;
        gurobi_params.MIPGap = 0.05; % Stops when within 5% of the optimal solution

        gurobi_params.Presolve = 1;
        gurobi_params.PrePasses = 3;       % Force it to do only 1 quick pass
        gurobi_params.PreQLinearize = 1;   % Don't spend time aggressively linearizing the quadratic part

        gurobi_params.Heuristics = 0.1;
        % gurobi_params.Cuts = 2;           % Force aggressive cut generation for packing structure
        
        % --- CRITICAL ADDITIONS FOR TOUGH TILING PROBLEMS ---
        gurobi_params.ImproveStartGap = 0.59 ;
        % gurobi_params.Symmetry = 2;       % Aggressive symmetry breaking (Crucial for Tiling)
        % gurobi_params.VarBranch = 3;      % Strong branching (Prevents exploring bad layout paths)
        % gurobi_params.PreSOS2BigM = 0;    % Tighten SOS formulations automatically

        % --- PHILOSOPHICAL SHIFT FOR TERMINATION ---
        gurobi_params.MIPFocus = 1;

        % --- TOLERANCE RECOVERY (Fixing 1e-2 risks) ---
        gurobi_params.IntFeasTol = 1e-6;
        gurobi_params.FeasibilityTol = 1e-5;
        gurobi_params.OptimalityTol = 1e-5;  
     end

    gurobi_params.TimeLimit = GP.user_params.time_limit_secs; % max solve time in seconds.
    
    gurobi_params = handleSelectedPuzzles(GP, gurobi_params);

    dbg = 1;
end

function  gurobi_params = handleSelectedPuzzles(GP, gurobi_params)
    if strcmp(GP.puzzle_id, 'shape26')
        gurobi_params.MIPFocus = 2;       % Focus on the lower bound / optimality
        gurobi_params.Presolve = 2;       % Aggressive presolve
        gurobi_params.Cuts = 2;           % Aggressive cuts
        gurobi_params.Heuristics = 0.05;  % Reduce heuristic overhead since you find solutions easily
    elseif strcmp(GP.puzzle_id, 'shape2')
        gurobi_params.MIPFocus = 3;       % Keep focusing on the lower bound
        gurobi_params.Presolve = 1;       % Use moderate presolve to keep the 835 QC structure
        gurobi_params.Cuts = 3;           % Aggressive cutting planes everywhere
        gurobi_params.VarBranch = 0;      % Revert to automatic branching to speed up node throughput
        gurobi_params.ScaleFlag = 2;      % Maintain aggressive scaling
    elseif strcmp(GP.puzzle_id, 'shape35')
        gurobi_params.MIPFocus = 1;       
        gurobi_params.PrePasses = 3;
        gurobi_params.MIPGap = 0.05;
        gurobi_params.Method = 1;
        gurobi_params.Heuristics = 0.1;
        gurobi_params.PreQLinearize = 1;
        gurobi_params.Presolve = 1;
        gurobi_params.ImproveStartGap = 0.59;
    end
end

