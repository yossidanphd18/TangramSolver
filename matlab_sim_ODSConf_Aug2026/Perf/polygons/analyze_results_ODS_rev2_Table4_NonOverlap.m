%================================================================
clear; 
clc;
close all

%-----------------------------------------------------
% Brief
%-----------------------------------------------------
% Script goal- analyse fine-tuning (FT) results of the 50 puzzles benchmark 
% results from ODS2026 revision1 : single-run, non-recorded seed.
% Process MISOCP results only. 

%-----------------------------------------------------
% Prepare paths and seeds
%-----------------------------------------------------
% save the rng state before using my seed.
my_seed = 1841;
old_rng_state = rng;
rng(my_seed);

% Save original folder and ensure we return to it when the script exits
origFolder = cd(fileparts(mfilename('fullpath')));
cleanupObj = onCleanup(@() cd(origFolder));

% addpath(genpath('C:/gurobi1203/win64/matlab/'));
addpath(genpath('../../Utils'));
addpath(genpath('../../GuiApp'));
addpath(genpath('../../Perf'));

pause(2);

%-----------------------------------------------------
% Select results folders
%-----------------------------------------------------
basePath = '../../__RESULTS_NON_OVERLAP/';
inputsPath = fullfile(basePath, 'InputsDataNonOverlap/');

challengesPath = fullfile(inputsPath, 'Challenges_scale_1.0_NonOverLaoCntsraints/polygons/');
resultsPath_MISOCP = fullfile(inputsPath, 'Results_scale_1.0_misocp_NonOverLaoCntsraints2');

analysisPath = fullfile(basePath, 'ResultsAnalysis/');
saveFiguresFolder = fullfile(analysisPath, 'Figures_ODS2026_rev2_non_overlap');

% Mark single-run and the seed was not recorded, so skip seed column.
NROUNDS = 3;
enable_seed_column = 1;
MY_SEEDS = [1841, 5440, 1518];

if ~exist(analysisPath, 'dir')
    mkdir(analysisPath);
end

if ~exist(saveFiguresFolder, 'dir')
    mkdir(saveFiguresFolder);
end

table_txt_filename = 'ODS_Rev2_Table4_non_overlap_MISOCP.txt';
table_mat_filename = 'ODS_Rev2_Table4_non_overlap_MISOCP.mat';

% path for saving the summary table
saveTableAsTxtPath = fullfile(analysisPath, table_txt_filename);
saveTableAsMatPath = fullfile(analysisPath, table_mat_filename);

%-----------------------------------------------------
% Flags
%-----------------------------------------------------
MAX_TIME_BUDGET_MINUTES = 30;

PLOTS_ENABLED = 0;
APPLY_FEATURES_ANALYSIS = 0;

SHOW_FINE_TUNING_FIGURES = 1;
APPLY_FINE_TUNING_FROM_SCRATCH = 1;

ONLY_RE_CALCULATE_SCORES = 0;
if(ONLY_RE_CALCULATE_SCORES)
    APPLY_FINE_TUNING_FROM_SCRATCH = 0;
end

TRY_VERTEX_MATCHING_FIRST = 1;

% show pre or post fine tuning ?
SHOW_PRE_FINE_TUNING_TABLE = 0;

%-----------------------------------------------------
% Optimization penalty weights
%-----------------------------------------------------
area_err_weight = 1000.0;
overlap_penalty = 1000.0;
txy_penalty = 100.0;
outside_penalty = 0.0;
weights_ft = [area_err_weight, overlap_penalty, txy_penalty, outside_penalty];

%-----------------------------------------------------
% Read folders content
%-----------------------------------------------------
selectedTag = 'SavedDB*';

dirPattern_misocp = fullfile(resultsPath_MISOCP, selectedTag);
entries_misocp = dir(dirPattern_misocp);
folders_misocp = entries_misocp([entries_misocp.isdir]);
nresults = length(folders_misocp);

%-----------------------------------------------------
% Pre-allocate columns for summary Table
%-----------------------------------------------------
ntable_rows = (nresults * NROUNDS);

names = strings(ntable_rows, 1);
seeds = strings(ntable_rows, 1);
num_options = zeros(ntable_rows, 1);

success_misocp = zeros(ntable_rows, 1);
solver_time_misocp = zeros(ntable_rows, 1);
area_outside_misocp = zeros(ntable_rows, 1);
area_covered_misocp = zeros(ntable_rows, 1);
area_uncovered_misocp = zeros(ntable_rows, 1);
area_overlap_misocp = zeros(ntable_rows, 1);

theta_degs = 0:45:(360-0.1);

% --- CONSTANTS FOR PAGING ---
shift0 = 34;
xy_shift_true = [-shift0, shift0];
xy_shift_misocp = [shift0, shift0];

xy_shifts.true = xy_shift_true;
xy_shifts.misocp = xy_shift_misocp;

%-----------------------------------------------------
% Loop all results, analyze, score, visualize.
%-----------------------------------------------------
for i = 1:nresults

    if mod(i-1, 5) == 0
        fprintf('Processing results %d-%d\n', i, i + 4);
    end

    % Load results
    [challenge_name] = extractChallengeName(folders_misocp(i).name);
    [challengeData] = loadTrueResults(challengesPath, challenge_name);
    
    targetFolderPathMisocp = fullfile(folders_misocp(i).folder, folders_misocp(i).name);

	[ResPack_MISOCP, SolPack_MISOCP] = loadResultsMISOCP(targetFolderPathMisocp, NROUNDS);
	
    if(isempty(ResPack_MISOCP) || isempty(challengeData) || isempty(challenge_name))
	    warning('Skipping empty data results...');
        continue;
    end
    
    [polyshapesTrue, polyshapesMISOCP] = loadAllRoundsDataMISOCP(challengeData, SolPack_MISOCP, xy_shifts, theta_degs, NROUNDS);
  
    saveMatPath = fullfile(targetFolderPathMisocp, 'TCombinedPolygons.mat');
    if(APPLY_FINE_TUNING_FROM_SCRATCH)
        [TCombinedPolygons] = getCombinedPolygonsMISOCP(polyshapesTrue, polyshapesMISOCP);
        save(saveMatPath, 'TCombinedPolygons');
    else
        loadedData = load(saveMatPath);
        if(ONLY_RE_CALCULATE_SCORES)
            [TCombinedPolygons] = getCombinedPolygonsMISOCP(polyshapesTrue, polyshapesMISOCP);
            save(saveMatPath, 'TCombinedPolygons');
        else
            TCombinedPolygons = loadedData.TCombinedPolygons;
        end
    end

    % Scores before Fine Tuning
    saveMatPath = fullfile(targetFolderPathMisocp, 'TScoresPreFineTuning.mat');
    if(APPLY_FINE_TUNING_FROM_SCRATCH)
        [TScoresPreFineTuning] = calculateTilingScoresMISOCP(polyshapesMISOCP, TCombinedPolygons);
        save(saveMatPath, 'TScoresPreFineTuning');        
    else
        loadedData = load(saveMatPath);
        if(ONLY_RE_CALCULATE_SCORES)
            [TScoresPreFineTuning] = calculateTilingScoresMISOCP(polyshapesMISOCP, TCombinedPolygons);
            save(saveMatPath, 'TScoresPreFineTuning');     
        else
            TScoresPreFineTuning = loadedData.TScoresPreFineTuning;
        end
    end

    % Scores after Fine Tuning
    maxTranslationNorm = norm([2,2]);
    maxTimeSeconds = 5*60;

    saveMatPath = fullfile(targetFolderPathMisocp, 'polyshapesMISOCP_ft.mat');
    if(APPLY_FINE_TUNING_FROM_SCRATCH)
        polyshapesMISOCP_ft = {};
        for iter = 1:NROUNDS
            [polyshapesMISOCP_ft_i] = applyTxyFineTuning(polyshapesMISOCP{iter}, TCombinedPolygons(iter).combinedPoly_true, ...
                maxTranslationNorm, maxTimeSeconds, 'MISOCP', weights_ft, TRY_VERTEX_MATCHING_FIRST);
            polyshapesMISOCP_ft{iter} = polyshapesMISOCP_ft_i;
        end
        save(saveMatPath, 'polyshapesMISOCP_ft');
    else
        loadedData = load(saveMatPath);
        polyshapesMISOCP_ft = loadedData.polyshapesMISOCP_ft;
    end

    % Calculate scores on the fine-tuned tilings.
    saveMatPath = fullfile(targetFolderPathMisocp, 'TCombinedPolygons_ft.mat');
    if(APPLY_FINE_TUNING_FROM_SCRATCH)
        [TCombinedPolygons_ft] = getCombinedPolygonsMISOCP(polyshapesTrue, polyshapesMISOCP_ft);
        save(saveMatPath, 'TCombinedPolygons_ft');
    else
        loadedData = load(saveMatPath);
        TCombinedPolygons_ft = loadedData.TCombinedPolygons_ft;
    end
    
    saveMatPath = fullfile(targetFolderPathMisocp, 'TScoresPostFineTuning.mat');
    if(APPLY_FINE_TUNING_FROM_SCRATCH)
        [TScoresPostFineTuning] = calculateTilingScoresMISOCP(polyshapesMISOCP_ft, TCombinedPolygons_ft);
        save(saveMatPath, 'TScoresPostFineTuning');
    else
        loadedData = load(saveMatPath);
        if(ONLY_RE_CALCULATE_SCORES)
            [TScoresPostFineTuning] = calculateTilingScoresMISOCP(polyshapesMISOCP_ft, TCombinedPolygons_ft);
            save(saveMatPath, 'TScoresPostFineTuning');
        else
            TScoresPostFineTuning = loadedData.TScoresPostFineTuning;
        end
    end

    % Collect data for table
    ti = NROUNDS*(i-1) + 1;
    
    for tii = ti:ti+NROUNDS-1
        names(tii) = challenge_name;
    end

    tk = 1;
    for tii = ti:ti+NROUNDS-1
        seeds(tii) = MY_SEEDS(tk);
        tk = tk + 1;
    end

    res_tmp = getAvgNumOptions(SolPack_MISOCP);
    for tii = ti:ti+NROUNDS-1
        num_options(tii) = res_tmp;
    end

    res_tmp = getAvgSolveTimeMins(ResPack_MISOCP);
    tk = 1;
    for tii = ti:ti+NROUNDS-1
        solver_time_misocp(tii) = res_tmp.time_per_iter_minutes{tk};
        tk = tk + 1;
    end

    if(SHOW_PRE_FINE_TUNING_TABLE)
        TScores = TScoresPreFineTuning;
    else
        TScores = TScoresPostFineTuning;
    end

    tk = 1;
    for tii = ti:ti+NROUNDS-1
        area_outside_misocp(tii) = TScores.PerIter{tk}.score_OSA_MISOCP;
        tk = tk + 1;
    end

    tk = 1;
    for tii = ti:ti+NROUNDS-1
        area_covered_misocp(tii) = TScores.PerIter{tk}.score_CA_MISOCP;
        tk = tk + 1;
    end

    tk = 1;
    for tii = ti:ti+NROUNDS-1
        area_uncovered_misocp(tii) = TScores.PerIter{tk}.score_UCA_MISOCP;
        tk = tk + 1;
    end

    tk = 1;
    for tii = ti:ti+NROUNDS-1
        area_overlap_misocp(tii) = TScores.PerIter{tk}.score_OLA_MISOCP;
        tk = tk + 1;
    end
    
    %------------------
    THRESH_CA = 783;
    THRESH_OTHER = 1e-1;
 
    for tii = ti:ti+NROUNDS-1
        success_misocp(tii) = (area_covered_misocp(tii) >= THRESH_CA) && (area_uncovered_misocp(tii) < THRESH_OTHER) ...
            && (area_outside_misocp(tii) < THRESH_OTHER) && (area_overlap_misocp(tii) < THRESH_OTHER) ; 
    end

    if(SHOW_FINE_TUNING_FIGURES)
        figData.challenge_name = challenge_name;
        figData.saveFiguresFolder = saveFiguresFolder;
        figData.polyshapesMISOCP = polyshapesMISOCP;
        figData.polyshapesMISOCP_ft = polyshapesMISOCP_ft;
        figData.TCombinedPolygons = TCombinedPolygons;
        figData.i = i;
        figData.nrounds = NROUNDS;
        
        plotFineTuningResults(figData, {'MISOCP'});
    end

    pause(0.2);
    close all;
end

% --- TABLE GENERATION ---
format bank;
validIdx = (names ~= "");
names = names(validIdx);
seeds = seeds(validIdx);
num_options = num_options(validIdx);

success_misocp = success_misocp(validIdx);
solver_time_misocp = solver_time_misocp(validIdx);
area_outside_misocp = area_outside_misocp(validIdx);
area_covered_misocp = area_covered_misocp(validIdx);
area_uncovered_misocp = area_uncovered_misocp(validIdx);
area_overlap_misocp = area_overlap_misocp(validIdx);

symbolMap = {'Fail', 'Success'}; 

numFormat = '05.2e'; 
formatTimeDiffSuccess = @(time, aC, aUC, aOL, aOS, succ, fmt) arrayfun(@(t, ac, auc, aol, aos, s) ...
    sprintf(['%05.2f [mins], %', fmt, ' [CA], %', fmt, ' [UCA], %', fmt, ' [OLA], %', fmt, ' [OSA], [%-7s]'], t, ac, auc, aol, aos, symbolMap{int32(s) + 1}), ...
    time, aC, aUC, aOL, aOS, succ, 'UniformOutput', false);

SolverMISOCP = string(formatTimeDiffSuccess(solver_time_misocp, area_covered_misocp, area_uncovered_misocp, area_overlap_misocp, area_outside_misocp, success_misocp, numFormat));    

if(enable_seed_column)
    resultsTable = table(names, seeds, num_options, SolverMISOCP, ...
        'VariableNames', {'Name', 'Seed', 'NumOptions', 'SolverMISOCP'});
else
    resultsTable = table(names, num_options, SolverMISOCP, ...
        'VariableNames', {'Name', 'NumOptions', 'SolverMISOCP'});
end

if(NROUNDS==1)
    [~, sortIdx] = sort(solver_time_misocp, 'ascend');
    resultsTable = resultsTable(sortIdx, :);
else
    sortIdx = 1:length(solver_time_misocp);
end

formattedOptions = arrayfun(@(x) sprintf('%.5e', x), num_options(sortIdx), 'UniformOutput', false);
resultsTable.NumOptions = string(formattedOptions); 

ID = uint32(1:height(resultsTable))'; 
resultsTable = addvars(resultsTable, ID, 'Before', 'Name');

fprintf('\n--- Simulation Results Summary (%d processed) ---\n\n', sum(validIdx));
disp(resultsTable);

saveTableToFiles(resultsTable, saveTableAsTxtPath, saveTableAsMatPath);
rng(old_rng_state);
        
%===========================================================================================================
% Helper functions
%===========================================================================================================
function saveTableToFiles(resultsTable, txt_file_path, math_file_path)
    saveTableToTextFile(resultsTable, txt_file_path);
    saveTableToMatFile(resultsTable, math_file_path);
end

function saveTableToTextFile(resultsTable, txt_file_path)
    rawString = evalc('disp(resultsTable)');
    cleanString = regexprep(rawString, '<[^>]*>', '');
    fileID = fopen(txt_file_path, 'w');
    if fileID == -1
        error('Could not open file for writing.');
    end
    fprintf(fileID, '%s', cleanString);
    fclose(fileID);
end

function saveTableToMatFile(resultsTable, math_file_path)
    save(math_file_path, 'resultsTable');
end

function [idx] = locatePuzzleIndexInList(challenge_name, folders)
	idx = -1;
	for n = 1:length(folders)
		if(startsWith(folders(n).name, strcat('SavedDB_', strcat(challenge_name,'_'))))
			idx = n;
			break;
		end
	end
end

function [res] = getAvgNumOptions(SolPack) 
	nrounds = length(SolPack);
	acc = 0;
	for iter = 1:nrounds
		acc = acc + prod(SolPack{iter}.group_sizes);
	end
	res = acc/nrounds;
end

function [res] = getAvgSolveTimeMins(ResPack) 
	nrounds = length(ResPack);
	res = [];
    acc = 0;
	for iter = 1:nrounds
        curr_time = ResPack{iter}.opt_duration_secs;
		acc = acc + curr_time;
        res.time_per_iter_minutes{iter} = (curr_time/60);
	end
	res.time_avg_minutes = (acc/nrounds)/60;
end

function [polyshapesTrue, polyshapesMISOCP] = loadAllRoundsDataMISOCP(challengeData, SolPack_MISOCP, xy_shifts, theta_degs, nrounds)
    Polygons = challengeData.TilesInfo.FinalPlacement.Polygons;
    true_txy = challengeData.Goal.true_translations;
    true_flips = challengeData.Goal.true_flips;
    true_rot_idxs = challengeData.Goal.true_rot_idxs;
    
    xy_shift_true   = xy_shifts.true;
    xy_shift_misocp = xy_shifts.misocp;

    polyshapesTrue = cell(1, nrounds);
    polyshapesMISOCP = cell(1, nrounds);

    for iter = 1:nrounds
        for k = 1:length(Polygons)
            txy_miscp = SolPack_MISOCP{iter}.found_txy{k} + challengeData.Grid.origin_x0y0 + xy_shift_misocp;
            txy_true = true_txy{k} + challengeData.Grid.origin_x0y0 + xy_shift_true;
            
            pv = Polygons{k}.OriginalVertices;
            pv_misocp = transformPolygon(pv, txy_miscp(1), txy_miscp(2), theta_degs(SolPack_MISOCP{iter}.found_rots_id(k)), SolPack_MISOCP{iter}.found_flips_id(k));
            pv_true = transformPolygon(pv, txy_true(1), txy_true(2), theta_degs(true_rot_idxs(k)), true_flips(k));
            
            currPoly_true = polyshape(pv_true(:,1), pv_true(:,2));          
            currPoly_misocp = polyshape(pv_misocp(:,1), pv_misocp(:,2));

            polyshapesTrue{iter}{k} = translate(currPoly_true, -xy_shift_true);
            polyshapesMISOCP{iter}{k} = translate(currPoly_misocp, -xy_shift_misocp);
        end
    end
end

function [TCombinedPolygons] = getCombinedPolygonsMISOCP(polyshapesTrue, polyshapesMISOCP)
    nrounds = length(polyshapesTrue); 

    TCombinedPolygons(nrounds).combinedPoly_true = polyshape();
    TCombinedPolygons(nrounds).combinedPoly_misocp = polyshape();

    for iter = 1:nrounds
        p_true  = [polyshapesTrue{iter}{:}];
        p_misocp = [polyshapesMISOCP{iter}{:}];

        TCombinedPolygons(iter).combinedPoly_true   = union(p_true);
        TCombinedPolygons(iter).combinedPoly_misocp = union(p_misocp);
    end
end

function [TScores] = calculateTilingScoresMISOCP(polyshapesMISOCP, TCombinedPolygons)
    nrounds = length(TCombinedPolygons);
    
    outside_misocp = 0; 
    covered_misocp = 0; 
    uncovered_misocp = 0; 
    overlap_misocp = 0; 
    
	TScores = [];
	
    for iter = 1:nrounds
        c_true   = TCombinedPolygons(iter).combinedPoly_true;
        c_misocp = TCombinedPolygons(iter).combinedPoly_misocp;
        p_misocp = polyshapesMISOCP{iter};
        
		score_OSA_MISOCP = calculateOutsideArea(c_misocp, c_true);
        outside_misocp  = outside_misocp + score_OSA_MISOCP;
		
		score_CA_MISOCP = calculateCoveredArea(c_misocp, c_true);
		covered_misocp  = covered_misocp + score_CA_MISOCP;
		
		score_UCA_MISOCP = calculateUncoveredArea(c_misocp, c_true);
        uncovered_misocp = uncovered_misocp + score_UCA_MISOCP;
		
		score_OLA_MISOCP = calculatePairwiseOverlapArea(p_misocp);
        overlap_misocp  = overlap_misocp + score_OLA_MISOCP;
		
		TScoresOneIter = struct();
		TScoresOneIter.score_OSA_MISOCP = score_OSA_MISOCP;
		TScoresOneIter.score_CA_MISOCP = score_CA_MISOCP;
		TScoresOneIter.score_UCA_MISOCP = score_UCA_MISOCP;
		TScoresOneIter.score_OLA_MISOCP = score_OLA_MISOCP;

		TScores.PerIter{iter} = TScoresOneIter;
    end
    
    TScores.AvgAllIters.area_outside_misocp = outside_misocp / nrounds;
    TScores.AvgAllIters.area_covered_misocp = covered_misocp / nrounds;
    TScores.AvgAllIters.area_uncovered_misocp = uncovered_misocp / nrounds;
    TScores.AvgAllIters.area_overlap_misocp = overlap_misocp / nrounds;
end

function [area_outside] = calculateOutsideArea(G, Gref)
    G_outside = subtract(G, Gref);    
    area_outside = area(G_outside);
end

function [area_uncovered] = calculateUncoveredArea(G, Gref)
    Gref_uncovered = subtract(Gref, G); 
    area_uncovered = area(Gref_uncovered);
end

function [area_covered] = calculateCoveredArea(G, Gref)
    Gref_covered = intersect(Gref, G); 
    area_covered = area(Gref_covered);
end

function [area_overlap] = calculatePairwiseOverlapArea(listPolyshapes)
    ntiles = length(listPolyshapes);
    area_overlap = 0;
    for k = 1:ntiles
        poly1 = listPolyshapes{k};
        for m = k+1:ntiles
            poly2 = listPolyshapes{m};
            intersectPoly = intersect(poly1, poly2);
            area_overlap = area_overlap + area(intersectPoly);
        end
    end
end

function [ResPacks, SolPacks] = loadResultsMISOCP(resultPuth, nrounds)
	ResPacks = {};
	SolPacks = {};
	
	for iter = 1:nrounds
		iter_str = ['_iter_',num2str(iter)];
		ResPack = [];
		SolPack.found_rots_id = [];
		SolPack.found_flips_id = [];
		SolPack.found_txy = [];
		SolPack.group_sizes = [];

		matFile = fullfile(resultPuth, ['ResPack_MISOCP', iter_str ,'.mat']);
		if isfile(matFile)
			data = load(matFile);
			ResPack = data.ResPackMISOCP;
			[SolPack.found_rots_id, SolPack.found_flips_id, SolPack.found_txy] = extract_solution_parameters(ResPack.x_sol, ResPack.TImages, ResPack.CountsDB);
			[SolPack.group_sizes] = extractGroupsSize(ResPack.CountsDB);
		else
			error('Invalid file path : %s', matFile);
		end
		
		ResPacks{iter} = ResPack;
		SolPacks{iter} = SolPack;
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

function [polyshapesP_f] = applyTxyFineTuning(polyshapesP_a, polyshapeG, maxTranslationNorm, maxTimeSeconds, solverType, weights, flagTryVertexMatchFirst)
    if nargin < 3 || isempty(maxTranslationNorm), maxTranslationNorm = Inf; end
    if nargin < 4 || isempty(maxTimeSeconds), maxTimeSeconds = Inf; end
    if nargin < 5 || isempty(solverType), solverType = 'YourSolverName'; end
    if nargin < 7 || isempty(flagTryVertexMatchFirst), flagTryVertexMatchFirst = false; end
    
    N = length(polyshapesP_a);
    x0 = zeros(1, 2 * N);
    
    NORM_THRESHOLD = norm([2, 2]); 
    matchedIndices = false(1, N);  
    
    if flagTryVertexMatchFirst
        gVertices = polyshapeG.Vertices; 
        for n = 1:N
            tVertices = polyshapesP_a{n}.Vertices;
            minDist = Inf;
            bestWgt = [0, 0];
            
            for i = 1:size(tVertices, 1)
                xt = tVertices(i, 1);
                yt = tVertices(i, 2);
                dists = sqrt(sum((gVertices - [xt, yt]).^2, 2));
                [dVal, minIdx] = min(dists);
                
                if dVal < minDist
                    minDist = dVal;
                    xg = gVertices(minIdx, 1);
                    yg = gVertices(minIdx, 2);
                    bestWgt = [xg - xt, yg - yt];
                end
            end
            
            if minDist < NORM_THRESHOLD
                x0(2*n - 1) = bestWgt(1);
                x0(2*n)     = bestWgt(2);
                matchedIndices(n) = true;
            end
        end
    end
    
    startTime = tic;
    objectiveFcn = @(vars) computeTilingError(vars, polyshapesP_a, polyshapeG, maxTranslationNorm, weights);
    
    try
        if isinf(maxTranslationNorm)
            lb = -Inf(1, 2 * N); ub = Inf(1, 2 * N);
        else
            lb = -maxTranslationNorm * ones(1, 2 * N); ub = maxTranslationNorm * ones(1, 2 * N);
        end
        
        if (strcmp(solverType, 'MISOCP'))
            for n = 1:N
                if matchedIndices(n)
                    lb(2*n - 1) = x0(2*n - 1); ub(2*n - 1) = x0(2*n - 1);
                    lb(2*n)     = x0(2*n);     ub(2*n)     = x0(2*n);
                end
            end
        end

        opts = optimoptions('patternsearch', ...
                            'Display', 'iter', ...
                            'MaxTime', maxTimeSeconds, ...
                            'OutputFcn', @timeOutFcn, ...
                            'MaxFunctionEvaluations', 10000, ...
                            'MeshTolerance', 1e-4);        
        x_opt = patternsearch(objectiveFcn, x0, [], [], [], [], lb, ub, [], opts);
        
    catch ME
        if contains(ME.identifier, 'UserStop') || contains(ME.message, 'User stop')
            if ~exist('x_opt', 'var'), x_opt = x0; end
        else
            rethrow(ME);
        end
    end
    
    polyshapesP_f = cell(1, N);
    for n = 1:N
        tx = x_opt(2*n - 1);
        ty = x_opt(2*n);
        polyshapesP_f{n} = translate(polyshapesP_a{n}, tx, ty);
    end

    function [stop, options, optchanged] = timeOutFcn(optimValues, options, flag)
        stop = false; optchanged = false;
        if strcmp(flag, 'iter') || strcmp(flag, 'init')
            if toc(startTime) > maxTimeSeconds
                stop = true;
            end
        end
    end
end

function [cost] = computeTilingError(vars, poly_base, polyG, maxNorm, weights)
    N = length(poly_base);
    currentPolys = cell(1, N);
    translationPenalty = 0;
    
    area_err_weight = weights(1);
    overlap_penalty = weights(2);
    txy_penalty = weights(3);
    outside_penalty_weight = weights(4);
    
    for n = 1:N
        tx = vars(2*n - 1);
        ty = vars(2*n);
        tNorm = sqrt(tx^2 + ty^2);
        if tNorm > maxNorm
            translationPenalty = translationPenalty + (tNorm - maxNorm)^2 * txy_penalty;
        end
        currentPolys{n} = translate(poly_base{n}, tx, ty);
    end
    
    unionP = currentPolys{1};
    for n = 2:N
        unionP = union(unionP, currentPolys{n});
    end
    
    symDiff = xor(unionP, polyG);
    areaError = area(symDiff);
    outsideP = subtract(unionP, polyG);
    outsidePenalty = area(outsideP);
    
    overlapPenalty = 0;
    for i = 1:N
        for j = i+1:N
            inter = intersect(currentPolys{i}, currentPolys{j});
            overlapPenalty = overlapPenalty + area(inter);
        end
    end
    
    cost = (area_err_weight * areaError) + ...
           (overlap_penalty * overlapPenalty) + ...
           (translationPenalty) + ...
           (outside_penalty_weight * outsidePenalty);
end