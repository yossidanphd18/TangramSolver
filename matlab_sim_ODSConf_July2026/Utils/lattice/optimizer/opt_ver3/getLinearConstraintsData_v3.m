function [Amatrix, Ylb, Yub, HTF2, Y2] = getLinearConstraintsData_v3(flag_which_part, GP, ConstraintsMap, VariablesLocatorMap, GurobiModelData, TBasisDictionary, block_starts_vector)
    
    assert(flag_which_part == 2, 'should be called only for part2 at the moment!');

    npcs = GP.npcs;

	%======================================================================
	% Now set the linear constraints matrix 
	% Set the AP matrix , e.g. Yp = AP*Xp
	%======================================================================
	model_nRows = ConstraintsMap('NUM_LIN_CONS') ;
	
	Amatrix = zeros(model_nRows, GurobiModelData.model_ncols);
	Ylb = zeros(model_nRows, 1);
	Yub = zeros(model_nRows, 1);
	
	%=========================================
	% Transfer Function Linear Constraints
	% Y2 = H2 * x + Z
	%=========================================
	% [nr, nc ] = size(TBasisDictionary('BasisVectors') );

	% constraints write pointer 
	pw = 1;
	keep_pwc = pw;
	
	%------------------------------------------------------
	% 	Yp = [RB | I |0] * Xp 
	%------------------------------------------------------
	Y2 = TBasisDictionary('goalVector'); 
	HTF2 = TBasisDictionary('BasisVectors') ;

	if(GP.flag_use_dct)
		DM = dctmtx(length(Y2));
		Y2 = DM*Y2;
		HTF2 = DM*HTF2;
	end

	r1 = pw;
	r2 = r1 + GP.zi_len - 1;
	c1 = 1;
	c2 = c1 + VariablesLocatorMap('len_ai_block').len - 1;
	
	TOL_Y2 = 0;
	Amatrix(r1:r2, c1:c2) = HTF2;
	Ylb(r1:r2) = Y2 - TOL_Y2;
	Yub(r1:r2) = Y2 + TOL_Y2;
	
	% set Identity matrix at correct place so that Y = H*x+ Z
	c1 = block_starts_vector(VariablesLocatorMap('len_qZ_block').place) + 1; % skip the q term
	c2 = c1 + GP.vdim - 1;	
	Amatrix(r1:r2, c1:c2) = eye(GP.vdim);
	
	pw = r2 + 1;
	
	count_LC = (pw - keep_pwc);
	assert(count_LC == ConstraintsMap('numLC_y_equal_Hx_plus_Z'));
	keep_pwc = pw;
	
	%------------------------------------------------------
	% sum(a_i) = 1 per each piece
	%------------------------------------------------------
	p1 = block_starts_vector(VariablesLocatorMap('len_ai_block').place);
	CountsDB = TBasisDictionary('CountsDB');
	for k = 1:npcs
        TM = CountsDB(k,:,:);
		nvecs = sum(TM(:));
		p2 = p1 + nvecs - 1;
		Amatrix(pw, p1:p2) = 1;
		% equality constraint sum(a_i)=1, hence lb=ub=1.
		Ylb(pw) = 1; 
		Yub(pw) = 1;
		
		p1 = p2 + 1;
		pw = pw + 1;
	end
	
	count_LC = (pw - keep_pwc);
	assert(count_LC == ConstraintsMap('numLC_sum_ai_equal_1'));
	keep_pwc = pw;
        
	%------------------------------------------------------
	% true solution hint constraint
	%------------------------------------------------------
    if(GP.flag_use_true_sol_hint)
	    c1 = 1;
	    c2 = c1 + VariablesLocatorMap('len_ai_block').len - 1;
        
		Amatrix(pw, c1:c2) = TBasisDictionary('BasisVectorsInTrueSol');

		% true solution hint : <true_sol, avec> = npcs.
		Ylb(pw) = npcs; 
		Yub(pw) = npcs;		
		pw = pw + 1;        

	    count_LC = (pw - keep_pwc);
	    assert(count_LC == ConstraintsMap('numLC_use_true_sol_hint'));
	    keep_pwc = pw;        
    end

end
