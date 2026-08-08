function [group_sizes, D_groups, goalVector, TBasisDictionary] = prepareDataToGAorSA(saved_db_folder)

    % saved_db_folder = 'C:\Users\User\_REPOS\phd_research3\matlab_sim_v200\Results_one_by_one_scale_1.0\SavedDB_shape56_20260402_162558';
    fullPath = fullfile(saved_db_folder, 'TBasisDictionary.mat');
    TBasisDictionary = load(fullPath);
    TBasisDictionary = TBasisDictionary.TBasisDictionary;
    CountsDB = TBasisDictionary('CountsDB');
    goalVector = ensureColumn(TBasisDictionary('goalVector'));
    BasisVectors = TBasisDictionary('BasisVectors');
    [group_sizes, D_groups] = extractGroupsInfo(CountsDB, BasisVectors);    

end