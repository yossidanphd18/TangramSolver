function [sim_params] = prepareSimParams(challenge_type, puzzle_id, scale_gain, time_limit_secs, challenge_db_save_path)

    % sim_params.challenge_type = 'polygons';
    % sim_params.challenge_type = 'pentominos';
    
    %=================================
    % set simulation parameters
    %=================================
    sim_params = [];

    sim_params.scale_gain = scale_gain;

    sim_params.challenge_type = challenge_type;
    sim_params.puzzle_id = puzzle_id;
    sim_params.challenge_db_save_folder_path = challenge_db_save_path;

    % sim_params.flag_use_disqualified_db = 0; % updated later
    sim_params.flag_use_integer_ai = 1;
    sim_params.flag_show_final_result_figure = 1;
    sim_params.apply_dim_reduction = 0; % don't reduce model (not working good).
    sim_params.reduced_dim = 700;
    sim_params.flag_which_part = 2; % historical, only 2 allowed.

    % use 1 only for debug !!! injecting the true solution to the solver!
    sim_params.inject_true_sol = 0;

    % sim_params.flag_have_true_ref = 1;
    %
    % to force a constraint <true_sol, ai> = npcs.
    % sim_params.flag_use_true_rots = 0; 
    %
    % sim_params.flag_use_true_sol_hint = 0;

    sim_params.TimeLimit = time_limit_secs;

    %--------------------------------------------------
    % Prepare also GA Params
    %--------------------------------------------------
    ga_params.mutation_prob = 0.3;
    ga_params.PopulationSize = 2000;  % Larger populations take longer but explore more
    ga_params.MaxTime = sim_params.TimeLimit;
    if(1)
        ga_params.MaxGenerations = 1e4; % inf;
        ga_params.FunctionTolerance = 1e-12; % 1e-7;  % Require higher precision before stopping
        ga_params.MaxStallGenerations = 1000; % 500; % Wait longer for improvement before quitting
    else
        ga_params.MaxGenerations = 1000;
        ga_params.FunctionTolerance = 1e-7;  % Require higher precision before stopping
        ga_params.MaxStallGenerations = 500; % Wait longer for improvement before quitting
    end
    sim_params.ga_params = ga_params;

    %--------------------------------------------------
    % Prepare also SA Params
    %--------------------------------------------------
    sa_params.InitialTemperature = 800;
    sa_params.ReannealInterval = 1000;
    sa_params.MaxTime = sim_params.TimeLimit;

    if(1)
        sa_params.MaxIterations = inf; % inf;
        sa_params.MaxStallIterations = 1e7; % 1e6; % 500;
        sa_params.FunctionTolerance = 1e-14; % 1e-10;
        sa_params.MaxFunctionEvaluations = inf;
    else
        sa_params.MaxIterations = 20000;
        sa_params.MaxStallIterations = 500;
        sa_params.FunctionTolerance = 1e-10;        
    end
    sim_params.sa_params = sa_params;

    %--------------------------------------------------
    % Prepare also Gurobi Params
    %--------------------------------------------------
    % sim_params.gurobi_params_set_id = 1;
    
    sim_params.gurobi_params.gurobi_display = 1;
    sim_params.gurobi_params.gurobi_logfile = 1;
    sim_params.gurobi_params.params_set_id = 1;

    %--------------------------------------------------
    % Params checkers
    %--------------------------------------------------
    sim_params_checkers(sim_params);
    
end
