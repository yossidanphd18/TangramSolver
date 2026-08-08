function [GP, TImages, TImagesFD, TBasisDictionary, TDisqualifiedDB] = prepareShapesAndGoal(ProblemSpec, GP)

    fprintf("*********************************************\n");
    fprintf("---> running PREPS stages...\n");
    fprintf("*********************************************\n\n");
    
    fprintf("*****************************************************************************************************\n");
    fprintf(['------****** Started preps stage,  nshapes = ', num2str(GP.limit_nshapes), ' ******------\n']);
    fprintf("*****************************************************************************************************\n\n");
                
    %======================================================================
    % create basic polygon Images and goal image
    %======================================================================
    
    fprintf("\n------> handling polygon Images and goal...\n");
    
    [TImages, GP] = preparePolygonImages(ProblemSpec, GP);
            
    fprintf("\n---> done handling polygon Images and goal...\n");
    pause(0.1);
    
    %======================================================================
    % calculate possible translations using conv2
    %======================================================================
    [TImages, GP] = calculatePossibleTranslations(ProblemSpec, TImages, GP);

    %======================================================================
    % prepare Fourier domain DB
    %======================================================================
    
    fprintf("\n\n------> handling Fourier domain data...\n");
    
    [TImagesFD, GP] = prepareFreqDomainData(TImages, GP);
    
    fprintf("\n---> done handling Fourier domain data...\n");
    
    %======================================================================
    % prepare basis vectors dictionary (from all possible translations)
    %======================================================================
    
    fprintf("\n\n------> preparing Freq-Domain Basis Vectors Dictionary with Forbid Indexes ...\n");
    pause(0.1);

    if(GP.skip_preprocess)
        fprintf("\n---> ** Skipping ** pre-processing : using pre-saved data...\n");
        path1 = './SavedDB/TBasisDictionary.mat';
        path2 = './SavedDB/TDisqualifiedDB.mat';
        load(path1);
        load(path2);
        clear path1 path2
    else
        [TBasisDictionary, TDisqualifiedDB] = prepareFDBasisVectorsDict2(ProblemSpec, TImages, TImagesFD, GP);
        
        save( fullfile(GP.save_path_per_test, 'TBasisDictionary.mat'), 'TBasisDictionary', '-v7.3');
        save( fullfile(GP.save_path_per_test, 'TDisqualifiedDB.mat'), 'TDisqualifiedDB', '-v7.3');
    end

    fprintf("\n---> done preparing Freq-Domain Basis Vectors Dictionary...\n");
 
    %======================================================================
    fprintf("\n---> verifying forbid constraints do not enforce infeasibility...\n");
    pause(0.1);
 
    % Verify that the forbid constraints don't make the problem infeasible.
    most_true_solution_idxs = TBasisDictionary('most_true_solution_idxs');
    for k = 1:length(most_true_solution_idxs)
	    idx = most_true_solution_idxs(k);
	    fbidxs = TDisqualifiedDB.forbidden_indxs{idx};
	    check1 = intersect(most_true_solution_idxs, fbidxs);
	    % assert(length(check1)==0,'FAILURE !');
        if(length(check1) > 0)
            warning('Unexpected Forbidden Indexes - Solver will Fail!!!');
        end
    end

    %======================================================================
    % sanity-check the Fourier domain Model
    %======================================================================
    if((GP.flag_have_true_ref > 0) && (~GP.clip2roi))
        fprintf("\n\n------> sanity checking Fourier domain model...\n");
        [TImagesFD] = sanityCheckFourierDomainModel(TImages, TImagesFD, GP, ProblemSpec.challenge_type, ...
            ProblemSpec.txy_winners_threshold, TBasisDictionary);
    else
        fprintf("\n\n------> SKIPPING sanity checking Fourier domain model (need to provide true flip, rot and txy)...\n");        
    end

    fprintf("\n---> done sanity checking Fourier domain model...\n");
    pause(0.1);

    %======================================================================
    % prepare Fourier domain DB for translation recovery:
    %======================================================================
	% Not used!!
    % [A2, Y2] = translationsRecoveryPOC(TImagesFD, GP);
         
    % Save outputs data
    save( fullfile(GP.save_path_per_test, 'GP.mat'), 'GP', '-v7.3');
    save( fullfile(GP.save_path_per_test, 'TImages.mat'), 'TImages', '-v7.3');
    save( fullfile(GP.save_path_per_test, 'TImagesFD.mat'), 'TImagesFD', '-v7.3');
    
    dbg = 1;

end
