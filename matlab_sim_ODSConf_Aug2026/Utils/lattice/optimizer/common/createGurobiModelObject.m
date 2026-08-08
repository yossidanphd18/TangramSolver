function [gurobi_model, model_ncols] = createGurobiModelObject(GP, block_starts_vector, VariablesLocatorMap)

    %======================================================================
    % Set the Model_cVec vector
    % x = [a1,a2,...aN | q Zvec]
    %======================================================================
    %  minimize : lambda*q
    %
    model_ncols = GP.nvars;
    Model_c_vector = zeros(model_ncols,1) ; 
    
    % for objective coef :  q.
    p1 = block_starts_vector(VariablesLocatorMap('len_qZ_block').place);
    Model_c_vector(p1) = GP.lambda_q; 
    
    %======================================================================
    % Start Gurobi Model (set alpha to npcs in gurobi_model.objcon)
    %======================================================================
    % Set objective and sense
    gurobi_model = [];
    gurobi_model.obj = Model_c_vector;
    gurobi_model.modelsense = 'min';
    
end
