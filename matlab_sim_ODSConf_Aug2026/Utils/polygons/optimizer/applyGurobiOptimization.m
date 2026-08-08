function [ResPack, GP] = applyGurobiOptimization(GP, TImages, TBasisDictionary, TDisqualifiedDB, x_my_sol)

    t_start_pre_process = tic;
    
    assert(GP.flag_which_part == 2, 'should be called only for part2 at the moment!');	
    assert(GP.user_params.inject_true_sol == 0,'inject_true_sol : should only be used for SANITY!');
    assert(isempty(x_my_sol),'true solution injection should be used only for sanity check!');
    
    assert(GP.flag_use_integer_ai == 1,'flag_use_integer_ai : must be enabled!');
    assert(GP.apply_dim_reduction == 0,'apply_dim_reduction : dont enable, negatove impact on solver!');
    
	fprintf("*****************************************************************************************************\n");
    fprintf(['------****** Started Optimization Part ', num2str(GP.flag_which_part), ' (for rotations + translations) ******------\n']);
	fprintf("*****************************************************************************************************\n\n");

	[GP] = getSpecificOptParams(GP);
	
    % set Gurobi_model specific parameters
	[gurobi_params, GP] = getGurobiSpecificParams(GP);
    
	%======================================================================
	% Preparations for GUROBI Optimization:
	%======================================================================
	fprintf("---> Preparations for GUROBI optimization...\n\n");
    % Save before reducing the model.
    %  GP2 = GP;
    %  TBasisDictionary2 = TBasisDictionary;
    if(GP.apply_dim_reduction)
        [GP, TBasisDictionary] = applyModelReduction(GP, TBasisDictionary);
    end

    % our optimization parameters vector is: x = [a_1,a_2,...,a_N | q, z1,z2,...zL]
    % with N = total number of basis vectors (all rotations and possible
    % translations).
    % and L = GP.vdim (for dft its = 2*nbins due to complex valued transform).

	% variables mapper
	[VariablesLocatorMap, block_lens_vector, block_starts_vector] = prepareVariablesLengthsDB(TBasisDictionary, GP.vdim);
	
	GP.nvars = sum(block_lens_vector);
	GP.zi_len = GP.vdim;
	
	% constraints mapper
	[ConstraintsMap] = createNumConstraintsDB(TDisqualifiedDB, GP);
	
	% initiate gurobi_model and its c vector (objective coefs vector) 
	[gurobi_model, model_ncols] = createGurobiModelObject(GP, block_starts_vector, VariablesLocatorMap);

	% lower and upper bounds for all variables
	[model_blx, model_bux] = getModelLowerUpperBounds(GP, block_starts_vector, block_lens_vector, ...
        VariablesLocatorMap, x_my_sol);

	GurobiModelData.gurobi_model = gurobi_model;
	GurobiModelData.model_ncols = model_ncols;
	GurobiModelData.model_blx = model_blx;
	GurobiModelData.model_bux = model_bux;
	
	% set gurobi_model constraints matrix
	[Amatrix, Ylb, Yub, HTF2, Y2, Bmatrix, Blb, Bub] = getLinearConstraintsData(GP, ConstraintsMap, VariablesLocatorMap, GurobiModelData, TBasisDictionary, block_starts_vector);
	
	save( [GP.db_save_folder_path, 'HTF2'], 'HTF2');
	save( [GP.db_save_folder_path, 'Y2'], 'Y2');
    if(~isempty(Bmatrix))
        save( [GP.db_save_folder_path, 'Bmatrix'], 'Bmatrix');
    end
		
    % set the Gurobi model constraints
	[gurobi_model] = setAllModelConstraints(gurobi_model, model_blx, model_bux, Amatrix, Ylb, VariablesLocatorMap, block_starts_vector, block_lens_vector, TDisqualifiedDB, GP);

	% set the Gurobi_model variables type
	[gurobi_model] = setModelVariablesType(gurobi_model, GP, VariablesLocatorMap, block_starts_vector, block_lens_vector);
	    
    % Set my seed to Gurobi.
    % gurobi_params.Seed = GP.user_params.my_seeds(1);
    gurobi_params.Seed = GP.curr_iter_seed;

    % time the end of pre-processing stage
    t_end_pre_process_secs = toc(t_start_pre_process);

	%------------------------------------------------------------------
	fprintf("---> Starting Gurobi solver...\n\n");
	%------------------------------------------------------------------ 
    t_start_gurobi = tic;
    
	gurobi_result = gurobi(gurobi_model, gurobi_params);
	% gurobi_result = gurobi(gurobi_model);
	
	if strcmp(gurobi_result.status, 'OPTIMAL');
	  fprintf('\n\n** SUCCEED ** Optimal objective: %e\n', gurobi_result.objval);
	  % disp(gurobi_result.x)
	else
	  fprintf('\n\n** FAILED **Optimization returned status: %s\n', gurobi_result.status);
	end
			
	fprintf("---> Done Gurobi solver...\n\n");
	
    t_end_gurobi_secs = toc(t_start_gurobi);
	%======================================================================
	% verify the solution :
	%======================================================================
	CountsDB = TBasisDictionary('CountsDB');
	x_sol = gurobi_result.x;

	[KPIs, SOLVER_RESULT] = verifyMySolution(x_sol, GP, TImages, CountsDB) ;
    
    ResPack = [];
    ResPack.GP = GP;
    ResPack.TImages = TImages;
    ResPack.CountsDB = CountsDB;
    ResPack.x_sol = x_sol;
    ResPack.KPIs = KPIs;
    ResPack.gurobi_model = gurobi_model;
    ResPack.gurobi_params = gurobi_params;
    ResPack.gurobi_result = gurobi_result;
    ResPack.SOLVER_RESULT = SOLVER_RESULT;
    ResPack.t_end_pre_process_secs = t_end_pre_process_secs;
    ResPack.t_end_gurobi_secs = t_end_gurobi_secs;

    dbg = 1;
end
