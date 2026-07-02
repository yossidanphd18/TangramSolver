function [GP, TImages, TBasisDictionary, TDisqualifiedDB] = prepareShapesAndGoal(ProblemSpec, GP)

    fprintf("*****************************************************************************************************\n");
    fprintf(['------****** Started preps stage,  nshapes = ', num2str(GP.npcs), ' ******------\n']);
    fprintf("*****************************************************************************************************\n\n");
                
    %======================================================================
    % create basic polygon Images and goal image
    %======================================================================
    fprintf("\n---> doing some data preperations...\n");

    [TImages, GP] = preparePolygonImages(ProblemSpec, GP);
            
    fprintf("\n---> done handling polygon Images and goal...\n");
 
    %======================================================================
    % calculate possible translations (P inside the goal G)
    %======================================================================
    fprintf("\n---> finding possible Translations...\n");

    [TImages, GP] = calculatePossibleTranslations(ProblemSpec, TImages, GP);

    fprintf("\n---> done calculatig feasible translations...\n");
    
    %======================================================================
    % prepare basis vectors dictionary (from all possible translations)
    %======================================================================
    fprintf("\n---> preparing Basis Vectors Dictionary...\n");

    if(~isempty(GP.SOLVER_RESULT))
        prev_scale_hint_avail = 1;
    else
        prev_scale_hint_avail = 0;
    end

    % if(~prev_scale_hint_avail)
    if(GP.user_params.scale_gain >= 1.0)
        [TBasisDictionary, TDisqualifiedDB, GP] = prepareBasisVectorsDict(ProblemSpec, TImages, GP);
    else
        [TBasisDictionary, TDisqualifiedDB, GP] = prepareBasisVectorsDict2(ProblemSpec, TImages, GP);
    end
    fprintf("\n---> done preparing Basis Vectors Dictionary...\n");
 
    %======================================================================
    % Verify that the forbid constraints don't make the problem infeasible.
    if(GP.user_params.flag_use_disqualified_db)
        fprintf("\n---> verifying forbid constraints do not enforce infeasibility...\n"); 
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
    end

end % end of function.
