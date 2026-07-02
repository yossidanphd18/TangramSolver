function [run_params, ResPack] = tangramProcessing(run_params)

    [Challenges, TilesInfo, FlipsRotsTiles] = create_challenges(run_params);
        
    if(run_params.show_sanity_test_figure)
        apply_sanity_check('FeasibleSolutionExists', Challenges, TilesInfo, FlipsRotsTiles);
    end

    %================================================
    % Select tests set (only one at this stage)
    %================================================
    selected_tests = [1];
    ChallengeFiles = {Challenges.Names{selected_tests}};
    Grids = {Challenges.Grids{selected_tests}};
    Goals = {Challenges.Goals{selected_tests}};
    
    %================================================
    % collected data into table
    %================================================
    TestsNames = ChallengeFiles;
    TSuccuss = [];
    TAbsDiff = [];
    Tncombs  = [];
    TElapsedTime_mins = [];
    ResPack = [];
    
    assert(length(ChallengeFiles)==1, 'We should process 1 file only in this loop. Need to refactor the code if not!');
    
    test_id = 1;

    % for test_id = 1:length(ChallengeFiles)
        
        ProfilerData = struct();
    
        t_start_0 = tic;
    
        % close all
    
        % prepare output folder
        [run_params] = prepare_output_folders(run_params);
    
        %=================================================
        % start processing...
        %=================================================
        fprintf(['\n\n--> Test ', num2str(test_id), ' : shape = ', ChallengeFiles{test_id}, '.\n\n']);
    
        Grid = Grids{test_id};
        Goal = Goals{test_id};
        
        if(strcmp(ChallengeFiles{test_id},'Square3'))
            run_params.gurobi_params_set_id = 2;
        end
    
        %=================================================
        % Stage1- Get problem and challenge/goal specs
        %=================================================
        % Create an input problem spec (tiles, grid, etc)
        [ProblemSpec] = create_problem_spec(run_params.challenge_type, Goal, TilesInfo, Grid, FlipsRotsTiles);    
        % ProblemSpec.Goal = Goal;
        
        %=================================================
        % Set global parameters (w.r.t. given flags).
        %=================================================    
        if(strcmp(ChallengeFiles{test_id},'Square3'))
            run_params.gurobi_params_set_id = 2;
        else
            run_params.gurobi_params_set_id = 1;
        end
        
        [GP] = setGlobalParams(ProblemSpec, run_params);
        
        ProfilerData.etime_preprocA = toc(t_start_0);
        
        %=================================================
        % Prepare images and goal images/arrays
        %=================================================    
        t_start1 = tic;
        ProblemSpec.TilesInfo = TilesInfo;
        [GP, TImages, TBasisDictionary, TDisqualifiedDB] = prepareShapesAndGoal(ProblemSpec, GP);
        ProfilerData.etime_shapes_goal_secs = toc(t_start1);
    
        fprintf("\n---> saving Model data (in case of crash)...\n");
        t_start2 = tic;
        save( fullfile(GP.db_save_folder_path, 'GP'), 'GP', '-v7.3');
        save( fullfile(GP.db_save_folder_path, 'TImages'), 'TImages', '-v7.3');
        save( fullfile(GP.db_save_folder_path, 'TBasisDictionary'), 'TBasisDictionary', '-v7.3');
        save( fullfile(GP.db_save_folder_path, 'TDisqualifiedDB'), 'TDisqualifiedDB', '-v7.3');
        pause(0.5);
        % close all
        ProfilerData.etime_save_db1 = toc(t_start2);
        ProfilerData.etime_gurobi_preproc_tot_sec = toc(t_start_0);
    
        %====================================================================
        % feasibility check using basis-vectors dictionary approach
        %====================================================================
        % DON NOT SET 1 HERE !!! USED ONLY FOR SANITY.
        % Inject the true solution as a hint to the solver (as a sanity test).
        % Otherwise - no hint to solver.
        if(run_params.user_params.inject_true_sol)
            error('Forcing error - dont inject true solution unless youre debugging!');
            % For injecting true solution to the solver.
            % use JUST for sanity check !
            [KPIs, x_my_sol] = checkIfFeasibleSol(GP, TBasisDictionary);
        else
            x_my_sol = [];
        end
    
        if(run_params.user_params.enable_misocp_solver)
            %=================================================
            % Run the solver optimization
            %=================================================
            fprintf("\n---> starting Gurobi solver...\n");
            t_start_gurobi_optim = tic;
            [ResPack, GP] = applyGurobiOptimization(GP, TImages, TBasisDictionary, TDisqualifiedDB, x_my_sol);      
            t_end_gurobi_optim_secs = toc(t_start_gurobi_optim);
    
            ProfilerData.etime_gurobi_opt_secs = t_end_gurobi_optim_secs;
            ProfilerData.etime_gurobi_opt_minutes = secs2mins(t_end_gurobi_optim_secs);
            ProfilerData.etime_pre_process_minutes = secs2mins(ProfilerData.etime_gurobi_preproc_tot_sec);
            % ProfilerData.etime_pre_process_minutes = secs2mins(ResPack.t_end_pre_process_secs);
            
            ResPack.KPIs.etime_gurobi_opt_secs = ProfilerData.etime_gurobi_opt_secs;
            ResPack.KPIs.etime_gurobi_opt_minutes = ProfilerData.etime_gurobi_opt_minutes;
            ResPack.KPIs.etime_pre_process_minutes = ProfilerData.etime_pre_process_minutes;
            ResPack.KPIs.ProfilerData = ProfilerData;
    
            %=================================================
            % Save the KPIs and results of this test
            %=================================================
            fprintf("\n---> saving Solver results data...\n");
            t_start = tic;
            save(fullfile(GP.db_save_folder_path, 'ResPack_MISOCP'), 'ResPack' , '-v7.3');
            TSuccuss(test_id) = ResPack.KPIs.success;
            TAbsDiff(test_id) = ResPack.KPIs.maxAbsDiff;
            TElapsedTime_mins(test_id) = ResPack.KPIs.etime_gurobi_opt_minutes;
            Tncombs(test_id) = ResPack.KPIs.ncombinations;
            ProfilerData.etime_save_db2 = toc(t_start);
        
            %=================================================
            % Report Status for current iteration
            %=================================================
            fprintf('\n\n***************** Profiler Information *****************\n');
            fprintf('-> PreprocA took %.2f [mins].\n', secs2mins(ProfilerData.etime_preprocA));
            fprintf('-> prepareShapesAndGoal() took %.2f [mins].\n', secs2mins(ProfilerData.etime_shapes_goal_secs));
            fprintf('-> Save DB of prepareShapesAndGoal() took %.2f [mins].\n', secs2mins(ProfilerData.etime_save_db1));
            fprintf('-> Save DB of applyGurobiOptimization() took %.2f [mins].\n', secs2mins(ProfilerData.etime_save_db2));
            if(ResPack.KPIs.success)
	            fprintf('--> Solver SUCCESS and took %.2f [mins].\n', ProfilerData.etime_gurobi_opt_minutes);
            else
	            fprintf('--> Solver **FAIL** and took %.2f [mins].\n', ProfilerData.etime_gurobi_opt_minutes);
            end
            fprintf('********************************************************\n\n\n');
        end % if (run_params.user_params.enable_misocp_solver)

        %==================================================================
        % Apply GA solver alternative (for reference A)
        %==================================================================
        if(run_params.user_params.enable_ga_solver)
            fprintf('\n\n---> Runing GA Optimizer (as a comparative approach 1) ...\n');
            [best_indices_ga, x_sol_ga, KPIs_ga] = ga_optimizer(TBasisDictionary, run_params.ga_params);
            ResPackGA = struct();
            ResPackGA.x_sol = x_sol_ga;
            ResPackGA.best_indices = best_indices_ga;
            ResPackGA.min_norm = KPIs_ga.min_norm;
            ResPackGA.opt_duration_secs = KPIs_ga.duration_secs;
            ResPackGA.preproc_duration_secs = ProfilerData.etime_shapes_goal_secs;
            ResPackGA.KPIs = KPIs_ga;
            save(fullfile(GP.db_save_folder_path, 'ResPack_GA'), 'ResPackGA' , '-v7.3');
            
            % Find the GA plot figure by its name and close it
            delete(findobj('Name', 'Genetic Algorithm'));
            % delete(findobj('Tag', 'OptimGUI'));
            pause(0.3);
        end

        %==================================================================
        % Apply SA solver alternative (for reference B)
        %==================================================================
        if(run_params.user_params.enable_sa_solver)
            fprintf('\n\n---> Runing SA Optimizer (as a comparative approach 2) ...\n');
            [best_indices_sa, x_sol_sa, KPIs_sa] = sa_optimizer(TBasisDictionary, run_params.sa_params);
            ResPackSA = struct();
            ResPackSA.x_sol = x_sol_sa;
            ResPackSA.best_indices = best_indices_sa;
            ResPackSA.min_norm = KPIs_sa.min_norm;            
            ResPackSA.opt_duration_secs = KPIs_sa.duration_secs;
            ResPackSA.preproc_duration_secs = ProfilerData.etime_shapes_goal_secs;
            ResPackSA.KPIs = KPIs_sa;
            save(fullfile(GP.db_save_folder_path, 'ResPack_SA'), 'ResPackSA' , '-v7.3');
    
            % Find the SA plot figure by its name and close it
            delete(findobj('Name', 'Simulated Annealing'));
            % delete(findobj('Tag', 'OptimGUI'));        
            pause(0.3);
        end
    % end % of tests loop
    
    %=================================================
    % Save summary table of all tests
    %=================================================
    if(run_params.user_params.enable_misocp_solver)
        TestsNames = TestsNames.';
        TSuccuss = TSuccuss.';
        TAbsDiff = TAbsDiff.';
        TElapsedTime_mins = TElapsedTime_mins.';
        Tncombs = Tncombs.';
        SummaryTable = table(TSuccuss, TAbsDiff, TElapsedTime_mins, 'RowNames', TestsNames);
        
        % Convert numeric 0/1 to categorical "no"/"yes"
        SummaryTable.TSuccuss = categorical(SummaryTable.TSuccuss, [0 1], {'no', 'yes'});
        disp(SummaryTable);
    
        SummaryTable.TestsNames = TestsNames;
        SummaryTable.TSuccuss = TSuccuss;
        SummaryTable.TAbsDiff = TAbsDiff;
        SummaryTable.TElapsedTime_mins = TElapsedTime_mins;
        SummaryTable.Tncombs = Tncombs;
        
        % saved_name_suffix = char(datetime('now'), '_yyyyMMdd_HHmmss');
        % save(fullfile(GP.db_save_folder_path, ['ResultsTable', saved_name_suffix]) , 'SummaryTable', '-v7.3');
        save(fullfile(GP.db_save_folder_path, 'ResultsTable_MISOCP') , 'SummaryTable', '-v7.3');
    end

    %=================================================
    % Simulation completed.
    %=================================================
    
    fprintf('\n\n ---> Simulation completed (All tests total time = %.2f minutes)\n', sum(TElapsedTime_mins));

end % end of function