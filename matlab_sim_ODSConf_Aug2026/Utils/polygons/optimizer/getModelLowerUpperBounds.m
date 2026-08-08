function [model_blx, model_bux] = getModelLowerUpperBounds(GP, block_starts_vector, block_lens_vector, ...
    VariablesLocatorMap, x_my_sol)

    %======================================================================
    % LowerBounds and UpperBounds on X
    %======================================================================
    % initially all in [0, 1]
    model_blx = 0*ones(GP.nvars, 1);
    model_bux = 1.0*ones(GP.nvars, 1);
    
    % ai in [0, 1] 
    p1 = block_starts_vector(VariablesLocatorMap('len_ai_block').place);
    p2 = p1 + block_lens_vector(VariablesLocatorMap('len_ai_block').place) - 1;
    model_blx(p1:p2) = 0;
    model_bux(p1:p2) = 1;

    % feasibility enforcement of known solution.
    if(~isempty(x_my_sol) && GP.user_params.inject_true_sol)
        model_blx(p1:p2) = x_my_sol(p1:p2);
        model_bux(p1:p2) = x_my_sol(p1:p2);
    end

    % [q Z]
    p1 = block_starts_vector(VariablesLocatorMap('len_qZ_block').place);
    p2 = p1 + block_lens_vector(VariablesLocatorMap('len_qZ_block').place) - 1;
    model_blx(p1:p2) = -GP.MAX_Zi;
    model_bux(p1:p2) =  GP.MAX_Zi;

    % q term (q is energy term on the norm of Z)
    model_blx(p1) = GP.MIN_q; 
    model_bux(p1) = GP.MAX_q;      
end