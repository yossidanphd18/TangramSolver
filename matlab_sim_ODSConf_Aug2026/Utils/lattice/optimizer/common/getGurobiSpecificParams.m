function [gurobi_params] = getGurobiSpecificParams(flag_which_part, flag_use_special_gurobi_params)

    gurobi_params.nonconvex = 2;
    gurobi_params.logfile = ['gurobi_logfile', datestr(now,'_mm_dd_yyyy_HHMMSS'), '.txt'];
    %
    % Set the TimeLimit in seconds (45 minutes * 60 seconds)
    gurobi_params.TimeLimit = 2700;

    % gurobi_params.logfile = 'gurobi_log_1.txt';
    % gurobi_params.Method = 1;
    % gurobi_params.MIPGapAbs = 1e-6;
    % gurobi_params.MIPFocus = 2;
    % gurobi_params.Threads = 1;
    % gurobi_params.presolve = 2;
    
    %     if(flag_which_part == 2)
    %         gurobi_params.Method = 1;
    %         gurobi_params.MIPFocus = 2;
    %     end
    
    %     if(flag_use_special_gurobi_params)
    %         % gurobi_params.numericfocus = 3;
    %         % gurobi_params.FeasibilityTol = 5*1e-3;
    %         gurobi_params.NodeFileStart = 0.5;
    %         gurobi_params.Threads = 4;
    %         gurobi_params.PreSparsify = 1;    
    %     end

end
