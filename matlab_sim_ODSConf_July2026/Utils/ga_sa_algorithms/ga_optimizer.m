function [best_indices, x_sol, KPIs] = ga_optimizer(TBasisDictionary, ga_params)
    
    % Start the stopwatch timer
    startTime = tic;
    
    CountsDB = TBasisDictionary('CountsDB');
    goalVector = ensureColumn(TBasisDictionary('goalVector'));
    BasisVectors = TBasisDictionary('BasisVectors');
    [group_sizes, D_groups] = extractGroupsInfo(CountsDB, BasisVectors);    
    
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
        'OutputFcn', @flagForcedTimeAndTrack); % Safe direct function handle                     
        
    % GA Parameters
    nGroups = length(group_sizes);
    lb = ones(1, nGroups);            
    ub = group_sizes;           
    intCon = 1:nGroups;               
    max_abs = -1e10;
    
    % define fitness function
    fitnessFcn = @(indices) ga_vector_fitness(indices, D_groups, goalVector);
    
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
    
    absDiff = abs(final_acc - goalVector);
    max_abs = max([max_abs, max(absDiff(:))]);
    min_mse = (min_norm^2) / vec_len; 
    
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

% --- CORRECTED: Output Function using robust persistent time tracking ---
function [state, options, optchanged] = flagForcedTimeAndTrack(options, state, flag)
    optchanged = false;

    % Use persistent variables to keep track of the run details natively
    persistent bestScoreSoFar bestSolutionTime targetTime saClock;

    % 'init' is explicitly sent by MATLAB before the optimization starts
    if strcmp(flag, 'init') || isempty(bestScoreSoFar)
        bestScoreSoFar = Inf;
        bestSolutionTime = 0;
        targetTime = options.MaxTime; 
        saClock = tic; % Start a stopwatch internal to this persistent space
    end

    % Get the current iteration's best score from the population
    currentBestInGen = min(state.Score);
    
    % Get current elapsed time from our persistent clock
    elapsedTime = toc(saClock);
    
    % If the GA found a strictly better solution this generation, record the timestamp
    if currentBestInGen < bestScoreSoFar
        bestScoreSoFar = currentBestInGen;
        bestSolutionTime = elapsedTime; 
    end
    
    % Intercept any premature signal trying to stop GA early
    if state.StopFlag 
        if elapsedTime < targetTime
            state.StopFlag = []; % Wipe out the early exit command
        end
    end

    % Update global root application data storage so the main script can read it
    setappdata(0, 'GA_BestSolutionTime', bestSolutionTime);
end