function [gurobi_model] = setAllModelConstraints_v3(flag_which_part, gurobi_model, model_blx, model_bux, Amatrix, Ylb, VariablesLocatorMap, ...
    block_starts_vector, block_lens_vector, TDisqualifiedDB, GP)

    assert(flag_which_part == 2, 'should be called only for part2 at the moment!');


    gurobi_model.lb = model_blx;
    gurobi_model.ub = model_bux;

    %------------------------------------------------------------------
    % Set the Linear constraints matrix
    %------------------------------------------------------------------
    gurobi_model.A   = sparse(Amatrix);
    gurobi_model.rhs = Ylb;
    gurobi_model.sense = '=';

	% see constraints manual at https://www.gurobi.com/wp-content/plugins/hd_documentations/documentation/9.0/refman.pdf
	
    %------------------------------------------------------------------
    % Cones norm(Z) <= q i.e. (z1^2 + z2^2 +..+ zM^2) <= q
    %------------------------------------------------------------------
    if(0)
        HMatrix = zeros(GP.nvars, GP.nvars);
        EMatrix = eye(GP.vdim);
        % EMatrix(1,1) = -1;       
        quad_con_cnt = 1;
        % we encode the constraint as xT*Qc*x + qT*x <= beta.
        % hence : 
        p1 = block_starts_vector(VariablesLocatorMap('len_qZ_block').place);
        p2 = p1 + block_lens_vector(VariablesLocatorMap('len_qZ_block').place) - 1;
        p3 = p1 + 1; % skip the q element, to z_1 element
        p4 = p2; % last z_i element
        qVector = zeros(GP.nvars, 1);
        qVector(p1) = -1; % coef of q element is -1
        HMatrix(p3:p4, p3:p4) = EMatrix; % coefs of z_1, z_2, ... z_last is 1.
        gurobi_model.quadcon(quad_con_cnt).Qc = sparse(HMatrix);
        gurobi_model.quadcon(quad_con_cnt).q  = sparse(qVector); 
        gurobi_model.quadcon(quad_con_cnt).rhs = 0.0;  % this is for <= beta i.e. here beta=0.
        gurobi_model.quadcon(quad_con_cnt).sense = '<';
        quad_con_cnt = quad_con_cnt + 1;
    else
        HMatrix = zeros(GP.nvars, GP.nvars);
        EMatrix = eye(GP.vdim + 1);
        EMatrix(1,1) = -1;
        zerosVector = zeros(GP.nvars, 1);
        quad_con_cnt = 1;
        % we encode the constraint as xT*Qc*x + qT*x <= beta.
        % hence : 

        p1 = block_starts_vector(VariablesLocatorMap('len_qZ_block').place);
        p2 = p1 + block_lens_vector(VariablesLocatorMap('len_qZ_block').place) - 1;
        HMatrix(:,:) = 0;
        HMatrix(p1:p2, p1:p2) = EMatrix;
        gurobi_model.quadcon(quad_con_cnt).Qc = sparse(HMatrix);
        gurobi_model.quadcon(quad_con_cnt).q  = sparse(zerosVector); 
        gurobi_model.quadcon(quad_con_cnt).rhs = 0.0;  % this is for <= beta i.e. here beta=0.
        gurobi_model.quadcon(quad_con_cnt).sense = '<';
        quad_con_cnt = quad_con_cnt + 1;
    end

    %------------------------------------------------------------------
    % Disqualified constraints
    %------------------------------------------------------------------
    if(GP.flag_use_disqualified_db)

        if(GP.flag_use_integer_ai)
            genconind_binval = 1;
            genconind_sense = '=';
        else
            genconind_binval = 0.9;
            genconind_sense = '>';
        end

        N = length(TDisqualifiedDB.var_index);
        cnt_idx = 1;
        zeros_vec = zeros(GP.nvars,1);
        for n = 1:N
            forbidden_indxs = TDisqualifiedDB.forbidden_indxs{n};
            assert(any(forbidden_indxs > N) == 0, 'forbidden indxs not in allowed range!');
            
			% we want to encode : a_k = 1 --> sum(forbiden a_i) = 0.
			% or x[binvar] = binval --> <x,a> sense rhs.
			%
            if(length(forbidden_indxs) > 0)
				% encoding : if x(binvar)=binval then sum(a(forbidden indexes)) = 0.
                gurobi_model.genconind(cnt_idx).binvar = n;
                gurobi_model.genconind(cnt_idx).binval = genconind_binval;
                a_vec = zeros_vec;
                a_vec(forbidden_indxs) = 1;
                gurobi_model.genconind(cnt_idx).a = sparse(a_vec);
                gurobi_model.genconind(cnt_idx).sense = genconind_sense;
                gurobi_model.genconind(cnt_idx).rhs = 0;
                cnt_idx = cnt_idx + 1;
            end
        end
    end

    dbg = 1;

end

