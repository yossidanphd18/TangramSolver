if(0)
    load('ODS_Rev2_Table2_20_puzzles.mat')
    resultsTable20 = resultsTable;
    clear resultsTable
    
    load('ODS_Rev2_Table3_30_puzzles.mat')
    resultsTable30 = resultsTable;
    clear resultsTable
    
    disp(resultsTable20);
    disp(resultsTable30);
    
    % Vertically concatenate the two tables
    combinedTable = [resultsTable20; resultsTable30];
    % Reset the ID column and explicitly cast it as an integer type (e.g., uint32)
    combinedTable.ID = uint32((1:height(combinedTable))');
    disp(combinedTable)
end


analysisPath = './';

table_txt_filename = 'ODS_Rev2_JoinedTables23_50_puzzles.txt';
table_mat_filename = 'ODS_Rev2_JoinedTables23_50_puzzles.mat';

saveTableAsTxtPath = fullfile(analysisPath, table_txt_filename);
saveTableAsMatPath = fullfile(analysisPath, table_mat_filename);

saveTableToFiles(combinedTable, saveTableAsTxtPath, saveTableAsMatPath);

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

