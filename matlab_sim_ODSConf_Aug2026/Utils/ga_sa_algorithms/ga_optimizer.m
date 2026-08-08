function [best_indices, x_sol, KPIs] = ga_optimizer(TBasisDictionary, TDisqualifiedDB, ga_params)
    
    % Start the stopwatch timer
    startTime = tic;
    
    CountsDB = TBasisDictionary('CountsDB');
    goalVector = ensureColumn(TBasisDictionary('goalVector'));
    BasisVectors = TBasisDictionary('BasisVectorsDB').BasisVectors;
    [group_sizes, D_groups] = extractGroupsInfo(CountsDB, BasisVectors);    
    % BasisPolygons = TBasisDictionary('BasisVectorsDB').BasisPolygons;
    
    TDisqualifiedDB.flag_use_disqualified_db = ga_params.flag_use_disqualified_db;
    TDisqualifiedDB.force_all_time = ga_params.flag_force_consume_all_time_budget;

    % Configure Options with Custom Mutation
    opt_mutation = @(parents, options, nvars, FitnessFcn, state, thisScore, thisPopulation) ...
                    custom_discrete_mutation(parents, options, nvars, FitnessFcn, state, thisScore, thisPopulation, group_sizes, ga_params.mutation_prob);
	
    if(ga_params.isWeb || ~ga_params.enable_fig)
		plot_func_option = [];
    else
		plot_func_option = {@gaplotbestf, @gaplotstopping};
    end
    if(ga_params.isWeb || ~ga_params.enable_display)
        display_option = 'off';
    else
        display_option = 'iter';
    end
	
    % GA Options
    options = optimoptions('ga', ...
        'PopulationSize', ga_params.PopulationSize, ...        
        'MaxGenerations', 1e9, ...                             
        'FunctionTolerance', ga_params.FunctionTolerance, ...   
        'MaxStallGenerations', 1e9, ...                         
        'MaxStallTime', 1e9, ...                               
        'MaxTime', ga_params.MaxTime, ...                       
        'MutationFcn', opt_mutation, ...
        'PlotFcn', plot_func_option, ...
        'Display', display_option, ...
        'OutputFcn', @(options, state, flag) flagForcedTimeAndTrack(options, state, flag, TDisqualifiedDB.force_all_time));                
        
    % GA Parameters
    nGroups = length(group_sizes);
    lb = ones(1, nGroups);            
    ub = group_sizes;           
    intCon = 1:nGroups;               
    max_abs = -1e10;
    
    % define fitness function
    fitnessFcn = @(indices) ga_vector_fitness(indices, D_groups, goalVector, group_sizes, TDisqualifiedDB);
    
    % Run GA Optimization
    [best_indices, min_norm, exit_flag, output_info] = ga(fitnessFcn, nGroups, [], [], [], [], lb, ub, [], intCon, options);
    fprintf('GA Solver finished with exitflag: %d\n', exit_flag);
    fprintf('GA Reason: %s\n', output_info.message);
    
    % --- NEW: Read out our tracked solution time ---
    tracked_time = getappdata(0, 'GA_BestSolutionTime');
    if isempty(tracked_time) || tracked_time == 0
        KPIs.duration_secs = toc(startTime); 
    else
        KPIs.duration_secs = tracked_time;
    end
    rmappdata(0, 'GA_BestSolutionTime'); % Clear root storage cleanly
    
    % --- Calculate MSE ---
    vec_len = size(goalVector, 1);
    final_acc = zeros(vec_len, 1);
    for i = 1:nGroups
        final_acc = final_acc + D_groups{i}(:, best_indices(i));
    end
    
    diffImage = (final_acc - goalVector);
    absDiffImage = abs(diffImage);
    max_abs = max([max_abs, max(absDiffImage(:))]);
    min_mse = mean(diffImage.^2);

    % Pack the solution vector into a canonical vector.
    npcs = length(group_sizes);
    x_sol = zeros(sum(group_sizes),1);
    offset = 0;
    for k = 1:npcs
        pw = best_indices(k) + offset;
        x_sol(pw) = 1;
        offset = sum(group_sizes(1:k));
    end
    
    KPIs.min_norm = min_norm;
    KPIs.max_abs = max_abs;
    KPIs.min_mse = min_mse;
    
end

function score = ga_vector_fitness(indices, D_groups, goalVector, group_sizes, TDisqualifiedDB)
    % Sum the vectors corresponding to the chosen indices
    ngroups = length(indices);
    vec_len = size(goalVector, 1);
    acc = zeros(vec_len, 1);
    
    group_sizes_cumsum = cumsum(group_sizes);
    dictonary_indxs = [];

    % separate the 1st iteration from others.
    i = 1;
    idx = indices(i);
    acc = acc + D_groups{i}(:, idx);
    dictonary_indxs(i) = idx + 0;
    for i = 2:ngroups
        idx = indices(i);
        acc = acc + D_groups{i}(:, idx);
        dictonary_indxs(i) = idx + group_sizes_cumsum(i-1);
    end
    
    % Objective1: Minimize the Euclidean distance to goalVector
    score1 = norm(acc - goalVector);
    
    % Objective2: Penalize intersecting pairs.
    score2 = 0;
    if(TDisqualifiedDB.flag_use_disqualified_db)
        for k = 1:ngroups
            % P1 = BasisPolygons{dictonary_indxs(k)};
            idx1 = dictonary_indxs(k);
            forbidden_indxs = TDisqualifiedDB.forbidden_indxs{idx1};
            forbidden_areas = TDisqualifiedDB.forbidden_areas{idx1};
            for m = k+1:ngroups
                % P2 = BasisPolygons{dictonary_indxs(m)};
                % areaMinPercentage = 0.03; % allow 3% intersection.
                % [is_intersecting, intersectionArea] = check_intersection_mex_o2(P1, P2, areaMinPercentage);
                % score2 = score2 + intersectionArea;
                idx2 = dictonary_indxs(m);
                ii_find = find(forbidden_indxs == idx2);
                assert(length(ii_find) <= 1, 'Expecting upto 1 index!');
                if(~isempty(ii_find))
                    score2 = score2 + forbidden_areas(ii_find);
                end
            end
        end
    end

    score = score1 + score2;
end

function [state, options, optchanged] = flagForcedTimeAndTrack(options, state, flag, force_all_time)
    optchanged = false; % do we change options inside this function ?
    
    % Use persistent variables to keep track of the run details natively
    persistent bestScoreSoFar bestSolutionTime targetTime optimClock;
    
    % 'init' is explicitly sent by MATLAB before the optimization starts
    if strcmp(flag, 'init') || isempty(bestScoreSoFar)
        bestScoreSoFar = Inf;
        bestSolutionTime = 0;
        targetTime = options.MaxTime; 
        optimClock = tic; % Start a stopwatch internal to this persistent space
    end
    
    % Get the current iteration's best score from the population
    currentBestInGen = min(state.Score);
    
    % Get current elapsed time from our persistent clock
    elapsedTime = toc(optimClock);
    
    % If the GA found a strictly better solution this generation, record the timestamp
    if currentBestInGen < bestScoreSoFar
        bestScoreSoFar = currentBestInGen;
        bestSolutionTime = elapsedTime; 
    end
    
    % ONLY intercept premature stop signals if the force flag is true
    if force_all_time
        if state.StopFlag 
            if elapsedTime < targetTime
                state.StopFlag = []; % Wipe out the early exit command
            end
        end
    end
    
    % Update global root application data storage so the main script can read it
    setappdata(0, 'GA_BestSolutionTime', bestSolutionTime);
end