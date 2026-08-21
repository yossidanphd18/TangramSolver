clear; clc; close all;

resultsTable = load('ODS_Rev2_JoinedTable2AndTable3_50_puzzles.mat');
resultsTable = resultsTable.resultsTable;

[SummaryTable] = prepareShortSummaryTable(resultsTable);

analysisPath = './';

table_txt_filename = 'ODS_Rev2_FinalSummary_50puzzles.txt';
table_mat_filename = 'ODS_Rev2_FinalSummary_50puzzles.mat';

saveTableAsTxtPath = fullfile(analysisPath, table_txt_filename);
saveTableAsMatPath = fullfile(analysisPath, table_mat_filename);

saveTableToFiles(SummaryTable, saveTableAsTxtPath, saveTableAsMatPath);

function [SummaryTable] = prepareShortSummaryTable(resultsTable)
    % Assuming your table is already loaded in workspace as: resultsTable
    % It has columns: ID, Name, Seed, NumOptions, SolverGA, SolverSA, SolverMISOCP
    
    solvers = {'SolverGA', 'SolverSA', 'SolverMISOCP'};
    numSolvers = length(solvers);
    
    % Unique puzzle names (assuming 3 rows per puzzle name corresponding to the 3 seeds)
    uniqueNames = unique(resultsTable.Name, 'stable');
    numPuzzles = length(uniqueNames);
    
    % Initialize results storage matrices
    successAll = zeros(numSolvers, 1);
    binnedCounts = zeros(numSolvers, 4); % Columns: [<5m, 5-10m, 10-15m, >15m]
    
    for s = 1:numSolvers
        solverName = solvers{s};
        solverData = resultsTable.(solverName);
        
        puzzlesSucceededAll = 0;
        avgRuntimes = zeros(numPuzzles, 1);
        
        for p = 1:numPuzzles
            % Find rows corresponding to this puzzle name
            idx = strcmp(resultsTable.Name, uniqueNames{p});
            puzRows = solverData(idx);
            
            runTimes = zeros(3, 1);
            runSuccess = false(3, 1);
            
            for r = 1:3
                str = puzRows{r};
                
                % Extract execution time (minutes) using regex
                % Matches digits before "[mins]"
                timeToken = regexp(str, '([\d\.]+)\s*\[mins\]', 'tokens');
                if ~isempty(timeToken)
                    runTimes(r) = str2double(timeToken{1}{1});
                end
                
                % Check success status
                if contains(str, '[Success]')
                    runSuccess(r) = true;
                end
            end
            
            % Check if all 3 seeds succeeded
            if all(runSuccess)
                puzzlesSucceededAll = puzzlesSucceededAll + 1;
            end
            
            % Calculate average runtime over the 3 seeds for this puzzle
            avgRuntimes(p) = mean(runTimes);
        end
        
        successAll(s) = puzzlesSucceededAll;
        
        % Runtime binning based on average runtime
        binnedCounts(s, 1) = sum(avgRuntimes < 5);
        binnedCounts(s, 2) = sum(avgRuntimes >= 5 & avgRuntimes < 10);
        binnedCounts(s, 3) = sum(avgRuntimes >= 10 & avgRuntimes < 15);
        binnedCounts(s, 4) = sum(avgRuntimes >= 15);
    end
    
    % Display final summary table in MATLAB Command Window
    SummaryTable = table(solvers', ...
        string(successAll) + " / " + string(numPuzzles), ...
        binnedCounts(:,1), binnedCounts(:,2), binnedCounts(:,3), binnedCounts(:,4), ...
        'VariableNames', {'Solver', 'Success_All_3_Runs', 'LessThan_5min', 'Between_5_10min', 'Between_10_15min', 'GreaterThan_15min'});
    
    disp('--- Summary Table Results ---');
    disp(SummaryTable);
end

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


