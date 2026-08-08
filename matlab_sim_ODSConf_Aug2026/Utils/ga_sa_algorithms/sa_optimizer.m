function [best_indices, x_sol, KPIs] = sa_optimizer(TBasisDictionary, TDisqualifiedDB, sa_params)

    % Start the stopwatch timer right at the beginning
    startTime = tic;

    CountsDB = TBasisDictionary('CountsDB');
    goalVector = ensureColumn(TBasisDictionary('goalVector'));
    BasisVectors = TBasisDictionary('BasisVectorsDB').BasisVectors;
    [group_sizes, D_groups] = extractGroupsInfo(CountsDB, BasisVectors);
    % BasisPolygons = TBasisDictionary('BasisVectorsDB').BasisPolygons;
    
    TDisqualifiedDB.flag_use_disqualified_db = sa_params.flag_use_disqualified_db;
    % TDisqualifiedDB.force_all_time = sa_params.flag_force_consume_all_time_budget;

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
		'OutputFcn', @(options, optimValues, flag) flagTrackSATime(options, optimValues, flag));
 
    % Note: fitness function must handle the rounding to integers
    fitnessFcn = @(indices) sa_vector_fitness(indices, D_groups, goalVector, group_sizes, TDisqualifiedDB);
    
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

    % --- NEW: Assign duration based on tracking data ---
	tracked_time = getappdata(0, 'SA_BestSolutionTime');
    if isempty(tracked_time) || tracked_time == 0
        KPIs.duration_secs = toc(startTime); 
    else
        KPIs.duration_secs = tracked_time;
    end
    rmappdata(0, 'SA_BestSolutionTime');

    KPIs.min_norm = min_norm;
    KPIs.max_abs = max_abs;
    KPIs.min_mse = min_mse;

end

function score = sa_vector_fitness(indices_floats, D_groups, goalVector, group_sizes, TDisqualifiedDB)
    % indices_floats: continuous vector of float indexes to groups provided by SA
    % D_groups: cell array of dictionaries
    % G: goal vector
    
    % Round x to the nearest integer to select dictionary indices
    indices = round(indices_floats);

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
        % Safety check: ensure rounding doesn't exceed bounds
        idx = max(1, min(idx, size(D_groups{i}, 2)));        
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

function [stop, options, optchanged] = flagTrackSATime(options, optimValues, flag)
    stop = false;       
    optchanged = false; % do we change options inside this function ?

    persistent bestScoreSoFar bestSolutionTime targetTime optimClock;
    
    if strcmp(flag, 'init') || isempty(bestScoreSoFar)
        bestScoreSoFar = Inf;
        bestSolutionTime = 0;
        targetTime = options.MaxTime; 
        optimClock = tic; 
    end
    
    if isfield(optimValues, 'bestfval')
        currentBestScore = optimValues.bestfval;
        elapsedTime = toc(optimClock);
        
        if currentBestScore < bestScoreSoFar
            bestScoreSoFar = currentBestScore;
            bestSolutionTime = elapsedTime;
        end
    end
    
    setappdata(0, 'SA_BestSolutionTime', bestSolutionTime);
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