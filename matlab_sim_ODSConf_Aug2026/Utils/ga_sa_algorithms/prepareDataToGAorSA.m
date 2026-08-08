function [group_sizes, D_groups, goalVector, TBasisDictionary] = prepareDataToGAorSA(saved_db_folder)

    fullPath = fullfile(saved_db_folder, 'TBasisDictionary.mat');
    TBasisDictionary = load(fullPath);
    TBasisDictionary = TBasisDictionary.TBasisDictionary;
    CountsDB = TBasisDictionary('CountsDB');
    goalVector = ensureColumn(TBasisDictionary('goalVector'));
    BasisVectors = TBasisDictionary('BasisVectors');
    [group_sizes, D_groups] = extractGroupsInfo(CountsDB, BasisVectors);    

end