function [best_indices, x_sol, KPIs] = sa_optimizer(TBasisDictionary, sa_params)

    % Start the stopwatch timer right at the beginning
    startTime = tic;

    CountsDB = TBasisDictionary('CountsDB');
    goalVector = ensureColumn(TBasisDictionary('goalVector'));
    BasisVectors = TBasisDictionary('BasisVectors');
    [group_sizes, D_groups] = extractGroupsInfo(CountsDB, BasisVectors);    

    if(sa_params.isWeb || ~sa_params.enable_fig)
		plot_func_option = [];
    else
		plot_func_option = {@saplotbestf, @saplotstopping, @saplottemperature};
    end

    if(sa_params.isWeb || ~sa_params.enable_display)
        display_option = 'off';
    else
        display_option = 'iter';
    end

    MaxFunctionEvaluations = 1e8; 

    % --- NEW: Tracking variables for the best solution time ---
    trackingData.bestScoreSoFar = Inf;
    trackingData.bestSolutionTime = 0;

    % Define custom output function handle to track the timestamp
    % trackTimeOutputFcn = @(options, optimValues, state) flagTrackSATime(options, optimValues, state, @() toc(startTime));

    % Options configuration
    options = optimoptions('simulannealbnd', ...
        'PlotFcn', plot_func_option, ...
        'AnnealingFcn', @sa_integer_move, ...
        'InitialTemperature', sa_params.InitialTemperature, ... 
        'MaxFunctionEvaluations', MaxFunctionEvaluations, ... 
        'MaxIterations', sa_params.MaxIterations, ...
        'ReannealInterval', sa_params.ReannealInterval, ...      
        'MaxStallIterations', sa_params.MaxStallIterations, ...    
        'FunctionTolerance', sa_params.FunctionTolerance, ...    
        'MaxTime', sa_params.MaxTime, ...          
        'Display', display_option, ...        
        'TemperatureFcn', @temperatureexp, ...
        'OutputFcn', @flagTrackSATime); % Added: Hook to log timestamp changes
 
    % Note: fitness function must handle the rounding to integers
    fitnessFcn = @(indices) sa_vector_fitness(indices, D_groups, goalVector);
    
    % Parameters
    nGroups = length(group_sizes);
    lb = ones(1, nGroups);      
    ub = group_sizes;           
    x0 = ones(1, nGroups); 
    max_abs = -1e10;

    % Run Optimization
    [best_indices_raw, min_norm, exit_flag, output_info] = simulannealbnd(fitnessFcn, x0, lb, ub, options);
    
    fprintf('SA Solver finished with exitflag: %d\n', exit_flag);
    fprintf('SA Reason: %s\n', output_info.message);

    % Final Processing 
    best_indices = round(best_indices_raw);

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

    % --- NEW: Assign duration based on tracking data ---
    if trackingData.bestSolutionTime == 0
        KPIs.duration_secs = toc(startTime); % Fallback if no valid steps made
    else
        KPIs.duration_secs = trackingData.bestSolutionTime;
    end

    KPIs.min_norm = min_norm;
    KPIs.max_abs = max_abs;
    KPIs.min_mse = min_mse;

end

% --- CORRECTED: Output Function to match the 3-argument signature and track time natively ---
function [stop, options, optchanged] = flagTrackSATime(options, optimValues, state)
    stop = false;       % Default required by MATLAB to continue optimizing
    optchanged = false; % Default required argument

    persistent saBestScoreSoFar saBestSolutionTime saClock;

    % Reset or initialize when MATLAB passes the 'init' stage flag
    if strcmp(state, 'init') || isempty(saBestScoreSoFar)
        saBestScoreSoFar = Inf;
        saBestSolutionTime = 0;
        saClock = tic; % Start a dedicated local stopwatch
    end

    % Extract current best objective value found by Simulated Annealing
    currentBestScore = optimValues.bestfval;

    % If a strictly lower layout score is found, log the time elapsed on our clock
    if currentBestScore < saBestScoreSoFar
        saBestScoreSoFar = currentBestScore;
        saBestSolutionTime = toc(saClock);
    end

    % Push the current recorded timestamp to root memory application data storage
    setappdata(0, 'SA_BestSolutionTime', saBestSolutionTime);
end

function nextX = sa_integer_move(optimValues, problem)
    currentX = optimValues.x;
    nVars = length(currentX);
    
    numToChange = randi([1, max(1, floor(nVars/5))]);
    indicesToChange = randperm(nVars, numToChange);
    
    nextX = currentX;
    for idx = indicesToChange
        nextX(idx) = randi([problem.lb(idx), problem.ub(idx)]);
    end
end