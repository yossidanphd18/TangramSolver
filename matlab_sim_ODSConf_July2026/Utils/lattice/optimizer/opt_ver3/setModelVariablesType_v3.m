function [gurobi_model] = setModelVariablesType_v3(flag_which_part, gurobi_model, GP, VariablesLocatorMap, block_starts_vector, block_lens_vector)

    assert(flag_which_part == 2, 'should be called only for part2 at the moment!');

	% all variables are continous ('C') except for a_i which are integers {0,1}. 
	% the [0,1] is encoded in LB, UB of the model.
    gurobi_model.vtype = repmat('C', GP.nvars, 1);
        
    if(GP.flag_use_integer_ai)
        % a_i integers in [0, 1]
        p1 = block_starts_vector(VariablesLocatorMap('len_ai_block').place);
        p2 = p1 + block_lens_vector(VariablesLocatorMap('len_ai_block').place) - 1;
        gurobi_model.vtype(p1:p2) = 'I';
    end

end

