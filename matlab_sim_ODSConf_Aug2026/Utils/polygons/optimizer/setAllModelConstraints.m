function [gurobi_model] = setAllModelConstraints(gurobi_model, model_blx, model_bux, Amatrix, Ylb, VariablesLocatorMap, ...
    block_starts_vector, block_lens_vector, TDisqualifiedDB, GP)

    gurobi_model.lb = model_blx;
    gurobi_model.ub = model_bux;

    %------------------------------------------------------------------
    % Set the Linear constraints matrix
    %------------------------------------------------------------------
    % Define a threshold for numerical noise
    % Set any coefficient smaller than the threshold to 0
    threshold = 1e-7;
    Amatrix(abs(Amatrix) < threshold) = 0;
    % If A is a sparse matrix, clean up the stored zero structures
    % A = dropzeros(sparse(A));


    if(GP.user_params.flag_use_disqualified_db && GP.user_params.flag_disqualified_as_lin_cons)
        % % 1. Define matrices
        % % A is MxN, B is KxN
        % % b is Mx1, c is Kx1
        % 
        % % 2. Concatenate matrices
        % model.A = [A; B]; 
        % 
        % % 3. Concatenate right-hand side
        % model.rhs = [b; c];
        % 
        % % 4. Define senses
        % % '='/ for equality (Ax = b)
        % % '<'/ for inequality (Bx <= c)
        % model.sense = [repmat('=', M, 1); repmat('<', K, 1)];
        % 
        % % 5. Call Gurobi
        % results = gurobi(model, params);

    end

    gurobi_model.A   = sparse(Amatrix);
    gurobi_model.rhs = Ylb;
    gurobi_model.sense = '=';
    
	% see constraints manual at https://www.gurobi.com/wp-content/plugins/hd_documentations/documentation/9.0/refman.pdf
	
    %------------------------------------------------------------------
    % Cones norm(Z) <= q i.e. (z1^2 + z2^2 +..+ zM^2) <= q^2
    %------------------------------------------------------------------
    if(GP.user_params.encode_Z_leq_q_as_convex_soc)
        if(1)
		    HMatrix = zeros(GP.nvars, GP.nvars);
            EMatrix = eye(GP.vdim);
            quad_con_cnt = 1;
            
            % p1 is the index of the q element in your variables vector
            p1 = block_starts_vector(VariablesLocatorMap('len_qZ_block').place);
            p2 = p1 + block_lens_vector(VariablesLocatorMap('len_qZ_block').place) - 1;
            p3 = p1 + 1; % skip the q element, to z_1 element
            p4 = p2; % last z_i element
            
            % 1. Quadratic coefficients: z_1^2, z_2^2, ... and now q^2 (-1)
            HMatrix(p3:p4, p3:p4) = EMatrix; % coefs of z_1, z_2, ... z_last is +1
            HMatrix(p1, p1) = -1;            % coef of q^2 is -1 (this forms the standard SOC!)
            
            % 2. Linear vector is now completely empty for this constraint
            qVector = zeros(GP.nvars, 1);    
            
            % 3. Assign to Gurobi model (sum(z_i^2) - q^2 <= 0  ==>  sum(z_i^2) <= q^2)
            gurobi_model.quadcon(quad_con_cnt).Qc = sparse(HMatrix);
            gurobi_model.quadcon(quad_con_cnt).q  = sparse(qVector); 
            gurobi_model.quadcon(quad_con_cnt).rhs = 0.0;  
            gurobi_model.quadcon(quad_con_cnt).sense = '<';
            quad_con_cnt = quad_con_cnt + 1;
        else
            error('Dont use this - Its incorrect and Not a SOC formulation!');
            HMatrix = zeros(GP.nvars, GP.nvars);
            EMatrix = eye(GP.vdim);
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
        end
    else
        error('Dont use this - seems to be incorrect encoding!');
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
    if(GP.user_params.flag_use_disqualified_db && (~GP.user_params.flag_disqualified_as_lin_cons))

        if(1)

            % 1. Determine number of active constraints
            % cellfun is efficient here to count non-empty cells
            num_constraints = sum(cellfun(@(x) ~isempty(x), TDisqualifiedDB.forbidden_indxs));
            
            % 2. Define the template for the indicator constraint
            % This ensures consistent field names and types across the entire array
            template = struct('type', 'indicator', ...
                              'binvar', [], ...
                              'binval', 1, ...
                              'linterm', [], ...
                              'sense', '<', ...
                              'rhs', 0);
            
            % 3. Pre-allocate the struct array using repmat
            % This avoids memory fragmentation and is significantly faster
            gurobi_model.genconstrs = repmat(template, num_constraints, 1);
            
            % 4. Populate the struct array
            cnt_idx = 1;
            for n = 1:length(TDisqualifiedDB.forbidden_indxs)
                forbidden_indxs = TDisqualifiedDB.forbidden_indxs{n};
                
                if ~isempty(forbidden_indxs)
                    % Validate indices
                    assert(all(forbidden_indxs <= GP.nvars), 'Forbidden indices out of range!');
                    
                    % Populate fields
                    % Use the pre-allocated index cnt_idx
                    gurobi_model.genconstrs(cnt_idx).binvar = n;
                    
                    % Construct the sparse vector directly. 
                    % This is the most memory-efficient way to represent the linear term.
                    gurobi_model.genconstrs(cnt_idx).linterm = sparse(1, forbidden_indxs, 1, 1, GP.nvars);
                    
                    cnt_idx = cnt_idx + 1;
                end
            end
            % Trim the array to the number of constraints actually filled
            gurobi_model.genconstrs = gurobi_model.genconstrs(1:cnt_idx - 1);

        else
            if(GP.flag_use_integer_ai)
                genconind_binval = 1;
                genconind_sense = '<';
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
                
                % % reduce number of constraints.
                % if(mod(n,2) == 0)
                %     continue;
                % end
    
			    % we want to encode : a_k = 1 --> sum(forbiden a_i) <= 0.
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
    end

    dbg = 1;

end

