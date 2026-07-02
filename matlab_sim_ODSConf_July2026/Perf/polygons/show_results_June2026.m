%=================================
clear; 
clc;
close all
% addpath(genpath('C:/gurobi1203/win64/matlab/'));
addpath(genpath('./../../Utils'));
addpath(genpath('./../../GuiApp'));
apply_features_analysis = 0;
challengesPath = 'C:\Users\User\_REPOS\phd_research3\matlab_sim_v201\Challenges_scale_1.0\polygons\'; 

ERR_NORM_THRESHOLD = 4.7;% Success criteria.
MAX_TIME_MINS = 30;      % Max time given to all algorithms

resultsPath = 'C:\Users\User\_REPOS\phd_research3\matlab_sim_v201\Results_scale_1.0_ms3\';
saveFiguresFolder = 'C:\Users\User\_REPOS\phd_research3\__MyTangramPaper_6\';

selectedTag = 'SavedDB*';

% Ensure the save directory exists
if ~exist(saveFiguresFolder, 'dir')
    mkdir(saveFiguresFolder);
end
% 1. Get folders
dirPattern = fullfile(resultsPath, selectedTag);
entries = dir(dirPattern);
folders = entries([entries.isdir]);
nresults = length(folders);
% Pre-allocate
names = strings(nresults, 1);
num_options = zeros(nresults,1);
success_misocp = zeros(nresults,1);
success_ga = zeros(nresults,1);
success_sa = zeros(nresults,1);
preprocess_time_misocp = zeros(nresults,1);
%preprocess_time_ga = zeros(nresults,1);
%preprocess_time_sa = zeros(nresults,1);
solver_time_misocp = zeros(nresults,1);
solver_time_ga = zeros(nresults,1);
solver_time_sa = zeros(nresults,1);
norm_diff_misocp = zeros(nresults,1);
norm_diff_ga = zeros(nresults,1);
norm_diff_sa = zeros(nresults,1);
theta_degs = 0:45:(360-0.1);
features_array = zeros(nresults,7);
% --- CONSTANTS FOR PAGING ---
rows = 2;
cols = 2;
plotsPerPage = (rows*cols);
currentFig = [];
subplot_idx = 1;
shift0 = 34;
xy_shift_true = [-shift0, shift0];
xy_shift_misocp = [shift0, shift0];
xy_shift_ga = [-shift0, -shift0];
xy_shift_sa = [shift0, -shift0];
for i = 1:nresults
    % Load results
    [challenge_name] = extractChallengeName(folders(i).name);
    [challengeData] = loadTrueResults(challengesPath, challenge_name);	
	[ResPack_MISOCP, SolPack_MISOCP] = loadResultsMISOCP(folders(i).folder, folders(i).name);
	[ResPack_GA, SolPack_GA] = loadResultsGASA(folders(i).folder, folders(i).name, 'GA', ResPack_MISOCP.TImages, ResPack_MISOCP.CountsDB);
	[ResPack_SA, SolPack_SA] = loadResultsGASA(folders(i).folder, folders(i).name, 'SA', ResPack_MISOCP.TImages, ResPack_MISOCP.CountsDB);
	
    features_array(i,:) = SolPack_MISOCP.group_sizes;
    if(isempty(ResPack_MISOCP) || isempty(challengeData) || isempty(challenge_name) || ...
	   isempty(ResPack_GA) || isempty(ResPack_SA))
	    warning('Skipping empty data results...');
        continue;
    end
    
    % --- FIGURE MANAGEMENT ---
    % 1. Save previous figure before creating a new one
    if ~isempty(currentFig) && mod(i-1, plotsPerPage) == 0
        figNumToSave = ceil((i-1) / plotsPerPage);
        savePath = fullfile(saveFiguresFolder, sprintf('tangram_results_%d.png', 99 + figNumToSave));
        % Use exportgraphics to preserve dark background and titles
        exportgraphics(currentFig, savePath, 'BackgroundColor', 'current', 'Resolution', 300);
        fprintf('Saved: %s\n', savePath);
    end
    % 2. Create new figure
    text_per_figure = 0;
    if mod(i-1, plotsPerPage) == 0
        text_per_figure = 1;
        subplot_idx = 1; 
        figNum = ceil(i / plotsPerPage);
        currentFig = figure('Color', [0.15 0.15 0.15], ...
                            'Name', sprintf('Batch Results Page %d', figNum));
        set(currentFig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
        sgtitle(currentFig, sprintf('Results (Batch %d)', figNum), ...
            'Color', 'w', 'FontSize', 16, 'FontWeight', 'bold');
    end
    % SELECT SUBPLOT
    ax1 = subplot(rows, cols, subplot_idx);
    hold(ax1, 'on'); 
    subplot_idx = subplot_idx + 1;
    % --- VIZUALIZATION CODE ---
    gv = ResPack_MISOCP.TImages.Goal.Vertices;
    gg0_true = translate(polyshape(gv(:,1), gv(:,2)), xy_shift_true);
    gg0_ours = translate(polyshape(gv(:,1), gv(:,2)), xy_shift_misocp);
    
    plot(ax1, gg0_true, 'FaceColor', [1 0.8 0.8], 'EdgeColor', [52 38 116]./255, 'LineStyle', '--', 'LineWidth', 2.5);
    plot(ax1, gg0_ours, 'FaceColor', [1 0.3 0.6], 'EdgeColor', [52 38 116]./255, 'LineStyle', '--', 'LineWidth', 1.5);
    
    Polygons = challengeData.TilesInfo.FinalPlacement.Polygons;
    true_txy = challengeData.Goal.true_translations;
    true_flips = challengeData.Goal.true_flips;
    true_rot_idxs = challengeData.Goal.true_rot_idxs;
    for k = 1:length(Polygons)
        txy_miscp = SolPack_MISOCP.found_txy{k} + challengeData.Grid.origin_x0y0 + xy_shift_misocp;
		txy_ga = SolPack_GA.found_txy{k} + challengeData.Grid.origin_x0y0 + xy_shift_ga;
		txy_sa = SolPack_SA.found_txy{k} + challengeData.Grid.origin_x0y0 + xy_shift_sa;
        txy_true = true_txy{k} + challengeData.Grid.origin_x0y0 + xy_shift_true;
        
        pv = Polygons{k}.OriginalVertices;
        pv_misocp = transformPolygon(pv, txy_miscp(1), txy_miscp(2), theta_degs(SolPack_MISOCP.found_rots_id(k)), SolPack_MISOCP.found_flips_id(k));
		pv_ga = transformPolygon(pv, txy_ga(1), txy_ga(2), theta_degs(SolPack_GA.found_rots_id(k)), SolPack_GA.found_flips_id(k));
		pv_sa = transformPolygon(pv, txy_sa(1), txy_sa(2), theta_degs(SolPack_SA.found_rots_id(k)), SolPack_SA.found_flips_id(k));
        pv_true = transformPolygon(pv, txy_true(1), txy_true(2), theta_degs(true_rot_idxs(k)), true_flips(k));
        
        plot(ax1, polyshape(pv_true(:,1), pv_true(:,2)), 'FaceColor', [0.3 0.6 1], 'EdgeColor', 'w', 'LineWidth', 0.6);
        plot(ax1, polyshape(pv_misocp(:,1), pv_misocp(:,2)), 'FaceColor', [0.3 0.6 0], 'EdgeColor', 'w', 'LineWidth', 0.6);
		plot(ax1, polyshape(pv_ga(:,1), pv_ga(:,2)), 'FaceColor', [0.5 0.1 0.4], 'EdgeColor', 'w', 'LineWidth', 0.6);
		plot(ax1, polyshape(pv_sa(:,1), pv_sa(:,2)), 'FaceColor', [0.2 0.5 0.5], 'EdgeColor', 'w', 'LineWidth', 0.6);
    end
    styleAxes(ax1);
    axis(ax1, 'equal');
    set(ax1, 'XTick', [], 'YTick', []);
    
    %---------------------------------------------------------
    if(text_per_figure)
        % Ensure we are targeting the current figure
        hFig = currentFig;
        
        offs_xy = [-0.02, 0];
        % Define the center of the schematic in normalized figure coordinates [x, y]
        % [0.5, 0.5] is the absolute center of the figure window.
        center = [0.1, 0.1] + offs_xy;
        
        oliveColor = [255, 255, 255] ./ 255; % Olive/lime for the lines
        blueColor  = [34,  166, 227]./ 255; % Sky blue for the text
        
        % --- 1. Draw the Schematic Cross/Grid ---
        
        % Horizontal Line ( Olive Color )
        annotation(hFig, 'line', [0.06, 0.14] + offs_xy(1), [0.9, 0.9], ...
                   'Color', oliveColor, 'LineWidth', 1.0);
        
        % Vertical Line ( Olive Color )
        annotation(hFig, 'line', [0.1,0.1] + offs_xy(1), [0.85,0.95], ...
                   'Color', oliveColor, 'LineWidth', 1.0);
        
        % --- 2. Draw the Quadrant Labels ---
        
        textPropsTL = {'Units', 'normalized', 'Color', [0.3 0.6 1], 'FontSize', 8, ...
                     'FontWeight', 'bold', 'HorizontalAlignment', 'center'};
        textPropsTR = {'Units', 'normalized', 'Color', [158,109,48]./ 255, 'FontSize', 8, ...
                     'FontWeight', 'bold', 'HorizontalAlignment', 'center'};
        textPropsBL = {'Units', 'normalized', 'Color', [0.5 0.1 0.4], 'FontSize', 8, ...
                     'FontWeight', 'bold', 'HorizontalAlignment', 'center'};
        textPropsBR = {'Units', 'normalized', 'Color', [0.2 0.5 0.5], 'FontSize', 8, ...
                     'FontWeight', 'bold', 'HorizontalAlignment', 'center'};
        
        % The offset moves the text away from the center crosshairs
        x_off = 0.05; 
        y_off = 0.08;
        
        % Top-Left: True
        annotation(hFig, 'textbox', [0.04 + offs_xy(1), 0.9, 0.08, 0.05], ...
                   'String', 'TRUE', textPropsTL{:}, 'EdgeColor', 'none');
        
        % Top-Right: MISOCP
        annotation(hFig, 'textbox',  [0.085 + offs_xy(1), 0.9, 0.08, 0.05], ...
                   'String', 'MISOCP', textPropsTR{:}, 'EdgeColor', 'none');
        
        % Bottom-Left: GA
        annotation(hFig, 'textbox', [0.04 + offs_xy(1), 0.85, 0.08, 0.05], ...
                   'String', 'GA', textPropsBL{:}, 'EdgeColor', 'none');
        
        % Bottom-Right: SA
        annotation(hFig, 'textbox', [0.085 + offs_xy(1), 0.85, 0.08, 0.05], ...
                   'String', 'SA', textPropsBR{:}, 'EdgeColor', 'none');        
    end
    %---------------------------------------------------------
	
    title(ax1, challenge_name, 'Color', 'w', 'FontSize', 8);
    drawnow limitrate;
    % Collect data for table
    names(i) = challenge_name;
    num_options(i) = prod(SolPack_MISOCP.group_sizes);
    misocp_err_norm = norm(ResPack_MISOCP.KPIs.diffImage);

    success_misocp(i) = (ResPack_MISOCP.KPIs.success) && (misocp_err_norm <= ERR_NORM_THRESHOLD);
    success_ga(i) = ResPack_GA.KPIs.min_norm <= ERR_NORM_THRESHOLD;
    success_sa(i) = ResPack_SA.KPIs.min_norm <= ERR_NORM_THRESHOLD;
    solver_time_misocp(i) = ResPack_MISOCP.KPIs.etime_gurobi_opt_minutes; 


    % We forced N mins execution.
    if(success_ga(i))
        solver_time_ga(i) = min(ResPack_GA.opt_duration_secs/60, MAX_TIME_MINS);
    else
        solver_time_ga(i) = MAX_TIME_MINS;
    end
    if(success_sa(i))
        solver_time_sa(i) = min(ResPack_SA.opt_duration_secs/60, MAX_TIME_MINS);
    else
        solver_time_sa(i) = MAX_TIME_MINS;
    end

    preprocess_time_misocp(i) = ResPack_MISOCP.KPIs.etime_pre_process_minutes;
    
    norm_diff_misocp(i) = misocp_err_norm;
    norm_diff_ga(i) = ResPack_GA.KPIs.min_norm;   
    norm_diff_sa(i) = ResPack_SA.KPIs.min_norm;
end % end loop

% --- SAVE THE VERY LAST FIGURE ---
if ~isempty(currentFig)
    figNumToSave = ceil(nresults / plotsPerPage);
    savePath = fullfile(saveFiguresFolder, sprintf('tangram_results_%d.png', 99 + figNumToSave));
    exportgraphics(currentFig, savePath, 'BackgroundColor', 'current', 'Resolution', 300);
    fprintf('Saved Final Page: %s\n', savePath);
end

% --- TABLE GENERATION ---
format bank;
% 1. Identify valid entries (where names is not an empty string)
validIdx = (names ~= "");
% 2. Prune all arrays to keep only the processed data
names = names(validIdx);
num_options = num_options(validIdx);
success_ga = success_ga(validIdx);
solver_time_ga = solver_time_ga(validIdx);
norm_diff_ga = norm_diff_ga(validIdx);
success_sa = success_sa(validIdx);
solver_time_sa = solver_time_sa(validIdx);
norm_diff_sa = norm_diff_sa(validIdx);
success_misocp = success_misocp(validIdx);
solver_time_misocp = solver_time_misocp(validIdx);
norm_diff_misocp = norm_diff_misocp(validIdx);
preprocess_time_misocp = preprocess_time_misocp(validIdx);

% Inline mapping lambda expressions to keep script workflow legal
symbolMap = {'Fail', 'Success'}; 

% %-7s forces the string to take exactly 7 spaces, left-aligned
formatTimeDiffSuccess = @(time, ndiff, succ) arrayfun(@(t, n, s) ...
    sprintf('%05.2f [mins], %05.2f [norm], [%-7s]', t, n, symbolMap{int32(s) + 1}), ...
    time, ndiff, succ, 'UniformOutput', false);

% Merge time, norm diff, and success data into consolidated text columns
SolverGA = string(formatTimeDiffSuccess(solver_time_ga, norm_diff_ga, success_ga));
SolverSA = string(formatTimeDiffSuccess(solver_time_sa, norm_diff_sa, success_sa));
SolverMISOCP = string(formatTimeDiffSuccess(solver_time_misocp, norm_diff_misocp, success_misocp));

% 3. Create the table with clean triple columns
resultsTable = table(names, num_options, SolverGA, SolverSA, SolverMISOCP, ...
    'VariableNames', {'Name', 'NumOptions', 'SolverGA', 'SolverSA', 'SolverMISOCP'});

% 4. Format and Sort 
[~, sortIdx] = sort(solver_time_misocp, 'ascend');
resultsTable = resultsTable(sortIdx, :);

% Create formatted strings for the NumOptions column
formattedOptions = arrayfun(@(x) sprintf('%.5e', x), num_options(sortIdx), 'UniformOutput', false);
resultsTable.NumOptions = string(formattedOptions); 

% Add ID column
ID = uint32(1:height(resultsTable))'; 
resultsTable = addvars(resultsTable, ID, 'Before', 'Name');

fprintf('\n--- Simulation Results Summary (%d processed) ---\n\n', sum(validIdx));
disp(resultsTable);

if(apply_features_analysis)
    %=========================================
    % Feature Analysis:
    %=========================================
    YY = solver_time_misocp;
    XX = features_array;
    
    %=========================================
    % Method 1
    %=========================================
    [R1, P1] = corr(XX, YY, 'Type', 'Pearson'); 
    % Visualize
    figure; 
    bar(R1);
    xlabel('Feature Index'); ylabel('Correlation with Y');
    title('Linear Impact of Features');
    
    %=========================================
    % Method 2
    %=========================================
    mdl2 = stepwiselm(XX, YY, 'Upper', 'linear', 'Criterion', 'sse');
    disp(mdl2);
    
    figure;
    bar(mdl2.Coefficients.Estimate(2:end)); 
    set(gca, 'XTickLabel', mdl2.CoefficientNames(2:end));
    ylabel('Coefficient Magnitude');
    title('Feature Impact (Stepwise Selection)');
    
    %=========================================
    % Method 3
    %=========================================
    t = templateTree('NumVariablesToSample', 'all');
    model3 = fitrensemble(XX, YY, 'Method', 'Bag', 'NumLearningCycles', 100, 'Learners', t);
    imp3 = predictorImportance(model3);
    
    figure;
    bar(imp3);
    set(gca, 'TickLabelInterpreter', 'none');
    title('Feature Importance (Random Forest)');
    ylabel('Importance Score');
    xlabel('Features');
    
    %=========================================
    % Method 4
    %=========================================
    ncaModel = fsrnca(XX, YY);
    figure;
    plot(ncaModel.FeatureWeights, 'ro');
    grid on;
    xlabel('Feature index'); ylabel('Feature weight');
    title('NCA Feature Weights');
end % if(apply_features_analysis)

%===========================================================================================================
% Helper functions. (All formal functions must reside down here)
%===========================================================================================================
function [ResPack, SolPack] = loadResultsMISOCP(basePath, folderName)
    ResPack = [];
    SolPack.found_rots_id = [];
    SolPack.found_flips_id = [];
    SolPack.found_txy = [];
	SolPack.group_sizes = [];
    resultPuth = fullfile(basePath, folderName);
    matFile = fullfile(resultPuth, 'ResPack_MISOCP.mat');
    if isfile(matFile)
        data = load(matFile);
        ResPack = data.ResPack;
		[SolPack.found_rots_id, SolPack.found_flips_id, SolPack.found_txy] = extract_solution_parameters(ResPack.x_sol, ResPack.TImages, ResPack.CountsDB);
        [SolPack.group_sizes] = extractGroupsSize(ResPack.CountsDB);
	else
		error('Invalid file path : %s', matFile);
    end
end
function [ResPack, SolPack] = loadResultsGASA(basePath, folderName, solver_type, TImages, CountsDB)
    ResPack = [];
    SolPack.found_rots_id = [];
    SolPack.found_flips_id = [];
    SolPack.found_txy = [];
    resultPuth = fullfile(basePath, folderName);
    matFile = fullfile(resultPuth, ['ResPack_', solver_type, '.mat']);
    if isfile(matFile)
        data = load(matFile);
        fieldName = ['ResPack', solver_type];
        ResPack = data.(fieldName);
		[SolPack.found_rots_id, SolPack.found_flips_id, SolPack.found_txy] = extract_solution_parameters(ResPack.x_sol, TImages, CountsDB);
    else
		error('Invalid file path : %s', matFile);
	end
end
function [challenge_name] = extractChallengeName(folderName)
    challenge_name = '';
    parts = strsplit(folderName, '_');
    if length(parts) >= 2
        challenge_name = string(parts{2}); 
    else
        challenge_name = string(folderName); 
    end
end
function [challengeData] = loadTrueResults(challengesPath, challenge_name)
    challengeData = [];
    matFile = fullfile(challengesPath, [char(challenge_name),'_data.mat']);
    if isfile(matFile)
        data = load(matFile);
        challengeData = data.SaveDB;
    end
end
function styleAxes(ax)
    set(ax, 'Color', [0.1 0.1 0.1], 'XColor', [0.8 0.8 0.8], 'YColor', [0.8 0.8 0.8]);
    set(findall(ax, 'type', 'text'), 'Color', 'w'); 
end