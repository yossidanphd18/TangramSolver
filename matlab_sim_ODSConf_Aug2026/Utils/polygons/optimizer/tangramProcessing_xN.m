function [run_params, ResPack] = tangramProcessing_xN(run_params)

    [Challenges, TilesInfo, FlipsRotsTiles] = create_challenges(run_params);
        
    if(run_params.show_sanity_test_figure)
        apply_sanity_check('FeasibleSolutionExists', Challenges, TilesInfo, FlipsRotsTiles);
    end

    %================================================
    % Select tests set (only one at this stage)
    %================================================
    selected_tests = [1];
    Challenges.Names{selected_tests};
    Grids = {Challenges.Grids{selected_tests}};
    Goals = {Challenges.Goals{selected_tests}};
    
    assert(length({Challenges.Names{selected_tests}})==1, 'We should process 1 file only in this loop. Need to refactor the code if not!');
  
	% prepare output folder
	[run_params] = prepare_output_folders(run_params);

	%=================================================
	% start processing...
	%=================================================
	test_id = 1;

	Grid = Grids{test_id};
	Goal = Goals{test_id};

	%=================================================
	% Stage1- Get problem and challenge/goal specs
	%=================================================
	[ProblemSpec] = create_problem_spec(run_params.challenge_type, Goal, TilesInfo, Grid, FlipsRotsTiles);    
	
	%=================================================
	% Set global parameters (w.r.t. given flags).
	%=================================================    
	[GP] = setGlobalParams(ProblemSpec, run_params);
		
	%=================================================
	% Prepare images and goal images/arrays
	%=================================================    
	ProblemSpec.TilesInfo = TilesInfo;
	[GP, TImages, TBasisDictionary, TDisqualifiedDB] = prepareShapesAndGoal(ProblemSpec, GP);

	fprintf("\n---> saving Model data (in case of crash)...\n");
	save( fullfile(GP.db_save_folder_path, 'GP'), 'GP', '-v7.3');
	save( fullfile(GP.db_save_folder_path, 'TImages'), 'TImages', '-v7.3');
	save( fullfile(GP.db_save_folder_path, 'TBasisDictionary'), 'TBasisDictionary', '-v7.3');
	save( fullfile(GP.db_save_folder_path, 'TDisqualifiedDB'), 'TDisqualifiedDB', '-v7.3');
	save( fullfile(GP.db_save_folder_path, 'ProblemSpec'), 'ProblemSpec', '-v7.3');
	save( fullfile(GP.db_save_folder_path, 'run_params'), 'run_params', '-v7.3');
	
	pause(0.5);

	% Keep pristine copies to safely reset each iteration without slow disk I/O
	GP_orig             = GP;
	TImages_orig        = TImages;
	TBasisDict_orig     = TBasisDictionary;
	TDisqualifiedDB_orig= TDisqualifiedDB;
	
	%====================================================================
	% Solve each puzzle N times (for better statistics)
	%====================================================================
	nrepeats = run_params.user_params.nrounds;

	assert(length(run_params.user_params.my_seeds) >= nrepeats, 'Not enough seeds provided for N rounds!');

	% Save the rng state before modifying it
	old_rng_state = rng;
    
    for nr = 1:nrepeats
		
		% Restore fresh parameters and data structures per iteration
		GP                  = GP_orig;
		TImages             = TImages_orig;
		TBasisDictionary    = TBasisDict_orig;
		TDisqualifiedDB     = TDisqualifiedDB_orig;
		
		round_tag_str = ['_iter_', num2str(nr)];

        curr_iter_seed = run_params.user_params.my_seeds(nr);
        GP.curr_iter_seed = curr_iter_seed;
        GP.iter_number = nr;
   
		% Set random seed for this iteration
		rng(curr_iter_seed);
        
		%====================================================================
		% feasibility check using basis-vectors dictionary approach
		%====================================================================
		if(run_params.user_params.inject_true_sol)
			error('Forcing error - Dont inject true solution unless youre debugging!');
			[~, x_my_sol] = checkIfFeasibleSol(GP, TBasisDictionary);
		else
			x_my_sol = [];
		end

		if(run_params.user_params.enable_misocp_solver)
			fprintf('\n********************************************************');
			fprintf("\n---> starting Gurobi MISOCP solver (round %d)...\n", nr);
			
			t_start_gurobi_optim = tic;
			[ResPackMISOCP, GP] = applyGurobiOptimization(GP, TImages, TBasisDictionary, TDisqualifiedDB, x_my_sol);      			
			t_end_gurobi_optim_secs = toc(t_start_gurobi_optim);
			ResPackMISOCP.opt_duration_secs = t_end_gurobi_optim_secs;
			ResPackMISOCP.KPIs.opt_duration_mins = secs2mins(t_end_gurobi_optim_secs);
	
			fprintf("\n---> saving Solver results data...\n");
			save(fullfile(GP.db_save_folder_path, ['ResPack_MISOCP', round_tag_str]), 'ResPackMISOCP', '-v7.3');
			fprintf("\n---> Done Gurobi MISOCP solver (round %d)...\n", nr);
			fprintf('********************************************************\n\n\n');
		end 

		%==================================================================
		% Apply GA solver alternative (for reference A)
		%==================================================================
		if(run_params.user_params.enable_ga_solver)
			fprintf('\n********************************************************');
			fprintf("\n---> Running GA Optimizer (round %d)...\n", nr);
			
			[best_indices_ga, x_sol_ga, KPIs_ga] = ga_optimizer(TBasisDictionary, TDisqualifiedDB, run_params.ga_params);
			ResPackGA = struct();
			ResPackGA.x_sol = x_sol_ga;
			ResPackGA.best_indices = best_indices_ga;
			ResPackGA.min_norm = KPIs_ga.min_norm;
			ResPackGA.opt_duration_secs = KPIs_ga.duration_secs;
			ResPackGA.KPIs = KPIs_ga;
			save(fullfile(GP.db_save_folder_path, ['ResPack_GA', round_tag_str]), 'ResPackGA', '-v7.3');
			
			delete(findobj('Name', 'Genetic Algorithm'));
			fprintf("\n---> Done GA solver (round %d)...\n", nr);
			fprintf('********************************************************\n\n\n');

			pause(0.3);
		end
	
		%==================================================================
		% Apply SA solver alternative (for reference B)
		%==================================================================
		if(run_params.user_params.enable_sa_solver)
			fprintf('\n********************************************************');
			fprintf("\n---> Running SA Optimizer (round %d)...\n", nr);

			[best_indices_sa, x_sol_sa, KPIs_sa] = sa_optimizer(TBasisDictionary, TDisqualifiedDB, run_params.sa_params);
			ResPackSA = struct();
			ResPackSA.x_sol = x_sol_sa;
			ResPackSA.best_indices = best_indices_sa;
			ResPackSA.min_norm = KPIs_sa.min_norm;            
			ResPackSA.opt_duration_secs = KPIs_sa.duration_secs;
			ResPackSA.KPIs = KPIs_sa;
			save(fullfile(GP.db_save_folder_path, ['ResPack_SA', round_tag_str]), 'ResPackSA', '-v7.3');
	
			delete(findobj('Name', 'Simulated Annealing'));
			fprintf("\n---> Done SA solver (round %d)...\n", nr);
			fprintf('********************************************************\n\n\n');
			
			pause(0.3);
		end
	
	end % end nrepeats loop.

    %=================================================
    % Simulation completed.
    %=================================================
    fprintf('\n\n ---> Simulation completed : x %d rounds per puzzle!\n', nrepeats);

    % restore the rng state
    rng(old_rng_state);
    
    ResPack = []; % Assign proper output pack if needed by function signature
end