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

    [TBasisDictionary, TDisqualifiedDB, GP] = prepareBasisVectorsDict(ProblemSpec, TImages, GP);

    fprintf("\n---> done preparing Basis Vectors Dictionary...\n");

end % end of function.
