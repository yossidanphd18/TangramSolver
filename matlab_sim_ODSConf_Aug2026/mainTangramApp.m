function mainTangramApp(use_web_mode)
    % use_web_mode : a boolean flag.
    %
    % Auto-detection logic
    % isdeployed: True if running as a compiled CTF/EXE
    % ctfroot: On a Web Server, the path contains 'webapps'
    is_on_web_server = isdeployed && ~isempty(strfind(ctfroot, 'webapps'));

    if nargin < 1
        use_web_mode = is_on_web_server;
    end
    
    nrounds = 3;
    % seeds = zeros(1, nrounds);
    % seeds(1) = 1841; % this is the seed I used recently.
    % seeds(2:nrounds) = randi([1, 10000], 1, nrounds-1);   
    seeds = [1841, 5440, 1518];
    assert(length(seeds) >= nrounds , 'Not enough seeds provided for N rounds!');

    params.nrounds = nrounds;
    params.my_seeds = seeds;
    params.single_iter_per_puzzle = (nrounds == 1);
    clear seeds  
    clear nrounds

    % Do we choose only K puzzles (randomly)
    params.choose_N_selected_puzzles = 0;
    params.num_choose = 17;

    % revision ID (e.g. for GA/SA parameters).
    params.perams_revision_id = 'ods2026_rev1';
	
    % Force web mode (for sanity test)
    params.use_web_mode = use_web_mode;

    % preparations for multi-resolution change to e.g. 0.9.
    % (scale_gain != 1.0 is WIP not supported yet).
    params.scale_gain = 1.0;
    
    % Path of installed Gurobi for Matlab. Refer to
    % https://www.gurobi.com/academics for getting a free academic license and installation.
    params.gurobi_path = 'C:/gurobi1203/win64/matlab/';

    params.challenges_path = ['./Challenges_scale_',num2str(params.scale_gain,'%.1f'),'/polygons/'];

    % Force N minutes max for all solvers.
    params.time_limit_secs = 30*60;
    
    % Execute GA , SA, MISOCP solvers (flags 0/1)?
    params.enable_misocp_solver = 1;
    params.enable_ga_solver = 1;
    params.enable_sa_solver = 1;
   
    % force disble extra viz, figures, display
    params.force_disable_viz = 1;
 
    % GA/SA viz
    params.enable_ga_or_sa_fig = 0;
    params.enable_ga_or_sa_display = 0;

    params.gurobi_display = 1;
    params.gurobi_logfile = 1;
    
    if(use_web_mode || params.force_disable_viz)
        params.show_final_result_figure = 0;
        params.show_sanity_test_figure	= 0;
        params.enable_first_feasibility_check = 0;
    else
        params.show_final_result_figure = 1;
        params.show_sanity_test_figure	= 1;
        params.enable_first_feasibility_check = 1;
    end

    % Do we use the non-overlap constraints or not ?    
    params.flag_use_disqualified_db = 0;
 
    params.flag_disable_inflation = 1;
    params.use_inflated_goal_in_solver = 0;

    % Force consume all time budget in GA/SA ?
    params.flag_force_consume_all_time_budget = 1;

    % If set to 1 we encode ||Z||^2 <= q^2 
    % otherwise we encode ||Z||^2 <= q 
    %
    % For shapes 34, 52, 61 we've set this to 0.
    params.encode_Z_leq_q_as_convex_soc = 1;

    params.list_tough_challenges = {};
    params.list_inflation_width = [];

    if(params.flag_use_disqualified_db)
        params.target_inflation_width = 0.8;
    else
        params.target_inflation_width = 0.0;   
    end

    if(params.flag_disable_inflation)
        params.target_inflation_width = 0.0;
        params.use_inflated_goal_in_solver = 0;
    end

    % Note that we used that in previous runs (even when NonOverLap constraints disabled).
    % This is used only for finding translation options (dictionary), so we want to be over-sized and not miss options.
    % Verified 28/July on {'square1', 'shape31', 'shape33', 'shape60', ...
    % 'shape41', 'shape47', 'shape56', 'shape58_err'}.
    params.target_inflation_width = 0.8;

    assert((params.target_inflation_width >= 0.0 && params.target_inflation_width < 1.3), 'inflation width should be limited.');

    %----------------------------------------------

    % This seems less efficient or successful. Keep it Disabled!
    params.flag_disqualified_as_lin_cons = 0;

    % debug only
	params.list_only_selected_shapes = 0;
	params.list_sleceted_index = 56:56;
	    
    % experimental only (WIP).
    params.flag_quantize_pix_area = 0;
    
    % use 1 only for debug !!! injecting the true solution to the solver!
    params.inject_true_sol = 0;

    assert(params.flag_disqualified_as_lin_cons == 0, 'flag_disqualified_as_lin_cons should be 0 (bad results if 1)');
    assert(params.scale_gain == 1.0, 'scale_gain should be 1.0. As multi-scale is not mature enough.');
    assert(params.inject_true_sol == 0, 'inject_true_sol must be 0! Injecting true solution is just for internal debug!!!');

    % instanciate.
    PolygonsAppClass(params);
end