function [TBasisDictionary, TImages] = loadBasisDictionaryData(saved_db_folder)

    fullPath = fullfile(saved_db_folder, 'TBasisDictionary.mat');
    TBasisDictionary = load(fullPath);
    TBasisDictionary = TBasisDictionary.TBasisDictionary;
    
    fullPath = fullfile(saved_db_folder, 'TImages.mat');
    TImages = load(fullPath);
    TImages = TImages.TImages;

end