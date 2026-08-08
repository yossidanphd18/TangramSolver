function [appData] = prepareRunParams(appData)
    
    challenge_type = appData.challenge_type;
    puzzle_id = appData.puzzle_id;

    %=================================
    % set simulation parameters
    %=================================
    run_params = [];
    run_params.user_params = appData.user_params;

    run_params.challenge_type = challenge_type;
    run_params.puzzle_id = puzzle_id;
    run_params.challenge_db_save_folder_path = appData.challenge_db_save_path;

    % run_params.flag_use_disqualified_db = 0; % updated later
    run_params.flag_use_integer_ai = 1;
    run_params.flag_show_final_result_figure = 1;
    run_params.apply_dim_reduction = 0; % don't reduce model (not working good).
    run_params.reduced_dim = 700;
    run_params.flag_which_part = 2; % historical, only 2 allowed.

    % run_params.flag_have_true_ref = 1;
    %
    % to force a constraint <true_sol, ai> = npcs.
    % run_params.flag_use_true_rots = 0; 
    %
    % run_params.flag_use_true_sol_hint = 0;

    %--------------------------------------------------
    % Prepare also GA Params
    %--------------------------------------------------
	revision_id = run_params.user_params.perams_revision_id;
	
	if(strcmp(revision_id, 'ods2026_rev2'))
		ga_params.mutation_prob = 0.1;           % Lowered from 0.3 for a more stable search convergence
		ga_params.PopulationSize = 500;          % Reduced from 2000 to drastically speed up evaluation time per generation
		ga_params.MaxTime = run_params.user_params.time_limit_secs; % Kept at 30 minutes (1800s)
		ga_params.MaxGenerations = 10000;        % Kept as an upper safety bound (MaxTime will trigger first)
		ga_params.FunctionTolerance = 1e-6;      % Relaxed from 1e-12 to prevent getting stuck chasing floating-point geometry noise
		ga_params.MaxStallGenerations = 200;     % Reduced from 1000 to exit early if progress stalls, freeing up time
	else
		ga_params.mutation_prob = 0.3;
		ga_params.PopulationSize = 2000;  % Larger populations take longer but explore more
		ga_params.MaxTime = run_params.user_params.time_limit_secs;
		ga_params.MaxGenerations = 1e4; % inf;
		ga_params.FunctionTolerance = 1e-12; % 1e-7;  % Require higher precision before stopping
		ga_params.MaxStallGenerations = 1000; % 500; % Wait longer for improvement before quitting
	end
	
	ga_params.flag_use_disqualified_db = run_params.user_params.flag_use_disqualified_db;
	ga_params.flag_force_consume_all_time_budget = run_params.user_params.flag_force_consume_all_time_budget;	
    run_params.ga_params = ga_params;

    %--------------------------------------------------
    % Prepare also SA Params
    %--------------------------------------------------
	if(strcmp(revision_id, 'ods2026_rev2'))
		sa_params.InitialTemperature = 800;      % Good high starting temp for broad exploration
		sa_params.ReannealInterval = 1000;       % Reannealing frequency
		sa_params.MaxTime = run_params.user_params.time_limit_secs; % 30 minutes limit (1800s)
		sa_params.MaxIterations = inf;           % Bounded by MaxTime
		sa_params.MaxStallIterations = 5e4;      % Reduced from 1e7 to allow reasonable early exit on stagnation
		sa_params.FunctionTolerance = 1e-6;      % Relaxed from 1e-12 to prevent chasing floating-point noise
		sa_params.MaxFunctionEvaluations = inf;  % Bounded by MaxTime
	else
		sa_params.InitialTemperature = 800;
		sa_params.ReannealInterval = 1000;
		sa_params.MaxTime = run_params.user_params.time_limit_secs;
		sa_params.MaxIterations = inf; % inf;
		sa_params.MaxStallIterations = 1e7; % 1e6; % 500;
		sa_params.FunctionTolerance = 1e-12; % 1e-10;
		sa_params.MaxFunctionEvaluations = inf;
	end
	
    sa_params.flag_use_disqualified_db = run_params.user_params.flag_use_disqualified_db;
    sa_params.flag_force_consume_all_time_budget = run_params.user_params.flag_force_consume_all_time_budget;

    run_params.sa_params = sa_params;

    %--------------------------------------------------
    % Prepare also Per-Solver Params
    %--------------------------------------------------
    run_params.isWeb = appData.isWeb;
    run_params.ga_params.isWeb = appData.isWeb;
    run_params.ga_params.enable_fig = appData.user_params.enable_ga_or_sa_fig;
    run_params.ga_params.enable_display = appData.user_params.enable_ga_or_sa_display;

    run_params.sa_params.isWeb = appData.isWeb;
    run_params.sa_params.enable_fig = appData.user_params.enable_ga_or_sa_fig;
    run_params.sa_params.enable_display = appData.user_params.enable_ga_or_sa_display;
    
    run_params.gurobi_params.isWeb = appData.isWeb;
    run_params.gurobi_params.gurobi_display = appData.user_params.gurobi_display;
    run_params.gurobi_params.gurobi_logfile = appData.user_params.gurobi_logfile;
    run_params.gurobi_params.params_set_id = 1;
	run_params.gurobi_params.Heuristics = appData.hHeurSlider.Value;

    % forward also user params
    run_params.show_sanity_test_figure = appData.user_params.show_sanity_test_figure;
    
    %--------------------------------------------------
    % Params checkers
    %--------------------------------------------------
    run_params_checkers(run_params);

    % Update the parameters.
    appData.run_params = run_params;  
end
