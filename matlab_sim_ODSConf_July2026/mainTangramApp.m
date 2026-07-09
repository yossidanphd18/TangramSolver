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
  
    % Force web mode (for sanity test)
    params.use_web_mode = use_web_mode;

    % Path of installed Gurobi for Matlab. Refer to
    % https://www.gurobi.com/academics for getting a free academic license and installation.
    params.gurobi_path = 'C:/gurobi1203/win64/matlab/';

    % Force N minutes max for all solvers.
    params.time_limit_secs = 30*60;
    
    % Execute GA , SA, MISOCP solvers (flags 0/1)?
    params.enable_misocp_solver = 1;
    params.enable_ga_solver = 0;
    params.enable_sa_solver = 0;
    
    % force disble extra viz, figures, display
    params.force_disable_viz = 0;
 
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

    % multi-resolution is experimental WIP.
    % prep for multi-resolution change to e.g. 0.9
    params.scale_gain = 1.0;

    % Do we use the non-overlap constraints or not ?
    params.flag_use_disqualified_db = 0;
    params.flag_disqualified_as_lin_cons = 0;

    params.list_tough_challenges = {'shape2', 'shape8', 'shape34', 'shape35', 'shape36', 'shape59', 'shape26', 'shape34', 'shape40', 'shape47',  'shape61'};
    params.list_selected_challenges = {'shape2', 'shape26'};
    params.hardestList = {'shape2','shape34', 'shape35' ,'shape36', 'shape41','shape47','shape43', 'shape50','shape59','shape61'};

    % debug only
	params.list_only_selected_shapes = 0;
	params.list_sleceted_index = 56:56;
	    
    % experimental only (WIP).
    params.target_inflation_width = 0.0;
    params.flag_quantize_pix_area = 0;
    % use 1 only for debug !!! injecting the true solution to the solver!
    params.inject_true_sol = 0;

    % instanciate.
    PolygonsAppClass(params);
end