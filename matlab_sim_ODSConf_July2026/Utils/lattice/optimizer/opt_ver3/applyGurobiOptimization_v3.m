function [ResultsPackage, GP] = applyGurobiOptimization_v3(GP, TImages, TImagesFD, TBasisDictionary, TDisqualifiedDB, ...
    flag_which_part, x_my_sol)

	assert(flag_which_part == 2, 'Only part 2 should get here.');
	% assert(GP.flag_use_conjugate_pairs == 0, 'We dont use the flag_use_conjugate_pairs currently !');
	
	title_suffix_str = ' (for rotations + translations) ******------\n'; 

	fprintf("*****************************************************************************************************\n");
	fprintf(['------****** Started Optimization Part ', num2str(flag_which_part), title_suffix_str]);
	fprintf("*****************************************************************************************************\n\n");

    %nfft   = GP.nfft;
    %npcs   = TImages.npcs;
    %nflips = TImages.nflips;
    %nrots  = TImages.nrots;

	min_ti = 0;
	max_ti = GP.assumed_tmax;
	
	[GP] = getSpecificOptParams_v3(flag_which_part, GP);
	
    % u_k is fft bins indexing [0,1,2...]
    % b_k is fft bins indexing [1,2,3...]
	selected_uk_bins = GP.u_k;
	selected_bins_idxs = GP.b_k;

	for k = 1:length(selected_uk_bins)
		assert(selected_bins_idxs(k) - selected_uk_bins(k) == 1);
	end
	
    if(0)
	    for k = 1:length(true_shifts_ti)
		    assert(true_shifts_ti(k) > 0);
	    end
    end

	min_uk = min(selected_uk_bins);  
	max_uk = max(selected_uk_bins); 

	GP.min_ti = min_ti;
	GP.max_ti = max_ti;

	GP.min_uk = min_uk;
	GP.max_uk = max_uk;
	
	%======================================================================
	% Preparations for GUROBI Optimization:
	%======================================================================
	fprintf("---> Preparations for GUROBI optimization...\n\n");
	
    % our optimization parameters vector is: x = [a_1,a_2,...,a_N | q, z1,z2,...zL]
    % with N = total number of basis vectors (all rotations and possible
    % translations).
    % and L = GP.vdim (for dft its = 2*nbins due to complex valued transform).

	% variables mapper
	[VariablesLocatorMap, block_lens_vector, block_starts_vector] = prepareVariablesLengthsDB_v3(flag_which_part, TBasisDictionary, GP);
	
	GP.nvars = sum(block_lens_vector);
	GP.zi_len = GP.vdim;
	
	% constraints mapper
	[ConstraintsMap] = createNumConstraintsDB_v3(flag_which_part, TDisqualifiedDB, GP);
	
	% initiate gurobi_model and its c vector (objective coefs vector) 
	[gurobi_model, model_ncols] = createGurobiModelObject(GP, block_starts_vector, VariablesLocatorMap);

	% lower and upper bounds for all variables
	[model_blx, model_bux] = getModelLowerUpperBounds_v3(flag_which_part, GP, block_starts_vector, block_lens_vector, ...
        VariablesLocatorMap, x_my_sol);

	GurobiModelData.gurobi_model = gurobi_model;
	GurobiModelData.model_ncols = model_ncols;
	GurobiModelData.model_blx = model_blx;
	GurobiModelData.model_bux = model_bux;
	
	% set gurobi_model constraints matrix
	[Amatrix, Ylb, Yub, HTF2, Y2] = getLinearConstraintsData_v3(flag_which_part, GP, ConstraintsMap, VariablesLocatorMap, GurobiModelData, TBasisDictionary, block_starts_vector);
	
    save( fullfile(GP.save_path_per_test, 'HTF2.mat'), 'HTF2', '-v7.3');
    save( fullfile(GP.save_path_per_test, 'Y2.mat'), 'Y2', '-v7.3');
		
    % set the Gurobi model constraints
	[gurobi_model] = setAllModelConstraints_v3(flag_which_part, gurobi_model, model_blx, model_bux, Amatrix, Ylb, VariablesLocatorMap, block_starts_vector, block_lens_vector, TDisqualifiedDB, GP);

	% set the Gurobi_model variables type
	[gurobi_model] = setModelVariablesType_v3(flag_which_part, gurobi_model, GP, VariablesLocatorMap, block_starts_vector, block_lens_vector);
	
    % set Gurobi_model specific parameters
	[gurobi_params] = getGurobiSpecificParams(flag_which_part, GP.flag_use_special_gurobi_params);
    
    if(strcmp(GP.challenge_type,'polygons'))
	    gurobi_params.MIPFocus = 1 ;
	    gurobi_params.IntFeasTol = 1e-6 ;
	    gurobi_params.FeasibilityTol = 1e-5 ;
	    gurobi_params.OptimalityTol = 1e-5 ;
        % Feasibility enforcement of known solution.
        if(~isempty(x_my_sol))
            if(0)
                gurobi_model.start = x_my_sol; 
                gurobi_params.SolutionLimit = 1; % Stop after finding the first feasible solution (if any)
                gurobi_params.Heuristics = 0.0;  % Turn off heuristics to rely purely on the start (optional)
            else
                p1 = block_starts_vector(VariablesLocatorMap('len_ai_block').place);
                p2 = p1 + block_lens_vector(VariablesLocatorMap('len_ai_block').place) - 1;        
                gurobi_model.lb(p1:p2) = x_my_sol(p1:p2);
                gurobi_model.ub(p1:p2) = x_my_sol(p1:p2);  
    
                gurobi_model.Presolve = 1;         % Conservative presolve effort
                gurobi_model.PrePasses = 3;        % Limit the number of presolve passes
                gurobi_model.PreQLinearize = 1;    % Force quadratic linearization early
            end
            % -1 auto, 0 off, 1 conservative, 2 aggressive
            % gurobi_model.Presolve = 1;
        else
            gurobi_model.Presolve = 1;         % Conservative presolve effort
            gurobi_model.PrePasses = 3;        % Limit the number of presolve passes
            gurobi_model.PreQLinearize = 1;    % Force quadratic linearization early        
        end        
    else
	    gurobi_params.MIPFocus = 3 ;
	    gurobi_params.IntFeasTol = 1e-9 ;
	    gurobi_params.FeasibilityTol = 1e-9 ;
	    gurobi_params.OptimalityTol = 1e-9 ;
    end
    
	%------------------------------------------------------------------
	fprintf("---> Starting Gurobi solver...\n\n");
	%------------------------------------------------------------------        
	gurobi_result = gurobi(gurobi_model, gurobi_params);
	% gurobi_result = gurobi(gurobi_model);
	
	if strcmp(gurobi_result.status, 'OPTIMAL');
	  fprintf('\n\n** SUCCEED ** Optimal objective: %e\n', gurobi_result.objval);
	  % disp(gurobi_result.x)
	else
	  fprintf('\n\n** FAILED **Optimization returned status: %s\n', result.status);
	end
			
	fprintf("---> Done Gurobi solver...\n\n");
	
	%======================================================================
	% verify the solution :
	%======================================================================
	CountsDB = TBasisDictionary('CountsDB');
	x_sol = gurobi_result.x;

	[KPIs] = verifyMySolution2(x_sol, GP, TImages, TImagesFD, CountsDB) ;
    
    ResultsPackage = [];
    ResultsPackage.GP = GP;
    ResultsPackage.TImages = TImages;
    ResultsPackage.TImagesFD = TImagesFD;
    ResultsPackage.CountsDB = CountsDB;
    ResultsPackage.x_sol = x_sol;
    ResultsPackage.KPIs = KPIs;
    ResultsPackage.gurobi_model = gurobi_model;
    ResultsPackage.gurobi_params = gurobi_params; 
    ResultsPackage.gurobi_result = gurobi_result;

end
