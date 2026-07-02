function checkModelFeasibiity(flag_which_part, gurobi_model, TParams, TImagesFD, block_starts_vector, block_lens_vector, Y2, VariablesLocatorMap, GP)

    nfft = GP.nfft;
    npcs = GP.npcs;
    B = GP.B;
    nrots = GP.nrots;

    TOL1 = 1e-10;
    TOL2 = 1e-5;
    TOL3 = 1e-5;

    % y2_goal_bins = Y2(1:2*B);
	y2_goal_bins = Y2(1:GP.vdim);
    y2_goal_bins2 = zeros(size(y2_goal_bins));
    
    tmp_vec = TImagesFD.GoalFD(TParams.selected_bins_idxs).';
    y2_goal_bins2(1:2:end) = real(tmp_vec);
    y2_goal_bins2(2:2:end) = imag(tmp_vec);

     if(GP.flag_use_dct)
            DM = dctmtx(length(Y2(1:GP.vdim)));
            y2_goal_bins2 = DM*y2_goal_bins2;
     end

    check_diff = max(abs(y2_goal_bins2 - y2_goal_bins));
    assert(check_diff < TOL1, 'verifying goal vector failed!');

    true_rot_idxs = TImagesFD.true_rot_idxs;
    true_shifts = TImagesFD.true_shifts;
    
    %====================================================================
    % Verify true ai and ti gives the Goal:
    %====================================================================
    nbits = 30;
    nbits_factor = 2^nbits;
    nbits_div = 1.0/nbits_factor;

    phaseVecsDB = {};

    accVec = zeros(B, 1);
    tmp_vec = TImagesFD.GoalFD(TParams.selected_bins_idxs).';
    
    for k = 1:npcs
        r_k = true_rot_idxs(k);
        t_k = true_shifts(k);
        binsVec = TImagesFD.Shapes{k}.RotatedImagesFD{r_k};
        binsVec = binsVec(TParams.selected_bins_idxs).';
        phaseVec = exp((-j*2*pi/nfft).*(TParams.selected_uk_bins.*t_k));
        phaseVec_fp = round(phaseVec.*nbits_factor).*nbits_div;
        
        accVec = accVec + (binsVec.*phaseVec_fp);

        % reduce to N bits precision
        phaseVecsDB{k} = phaseVec_fp;
    end
    z_vec_mine = tmp_vec - accVec ;
    q_mine = norm(z_vec_mine) + 1e-5;

    check_diff = max(abs(z_vec_mine));
    assert(check_diff < TOL2, 'verifying goal reachability failed!');

    dbg = 1;

    %====================================================================
    % Verify gurobi_model matrix, bounds and constraints:
    %====================================================================
    % x_sol = gurobi_result.x;
    x_sol_mine = zeros(size(gurobi_model.lb));

    % ti in [min_shift, max_shift]
    p1 = block_starts_vector(VariablesLocatorMap('len_ti_block').place);
    p2 = p1 + block_lens_vector(VariablesLocatorMap('len_ti_block').place) - 1;
    % ti_block = x_sol(p1:p2);
    ti_block = true_shifts;
    x_sol_mine(p1:p2) = ti_block;

    % u_k = the selected bins range is [0, nfft-1]
    p1 = block_starts_vector(VariablesLocatorMap('len_uk_selected_bins').place);
    p2 = p1 + block_lens_vector(VariablesLocatorMap('len_uk_selected_bins').place) - 1;
    % uk_block = x_sol(p1:p2);
    uk_block = TParams.selected_uk_bins;
    x_sol_mine(p1:p2) = uk_block;
    
    % vi = (2pi/nfft) * ui.
    p1 = block_starts_vector(VariablesLocatorMap('len_vk_block').place);
    p2 = p1 + block_lens_vector(VariablesLocatorMap('len_vk_block').place) - 1;
    % vk_block = x_sol(p1:p2);
    vk_block = (2*pi/nfft).*uk_block;
    x_sol_mine(p1:p2) = vk_block;
    
    % wpi = vi * tp.
    p1 = block_starts_vector(VariablesLocatorMap('len_wpi_block').place);
    % p2 = p1 + block_lens_vector(VariablesLocatorMap('len_wpi_block').place) - 1;
    % wpi_block = x_sol(p1:p2);
    for k = 1:npcs
        t_k = true_shifts(k);
        tmp_vec = vk_block.*t_k;
        p2 = p1 + B - 1;
        x_sol_mine(p1:p2) = tmp_vec;
        p1 = p2 + 1;
    end

    % wni = -wpi.
    p1 = block_starts_vector(VariablesLocatorMap('len_wni_block').place);
    % p2 = p1 + block_lens_vector(VariablesLocatorMap('len_wni_block').place) - 1;
    % wni_block = x_sol(p1:p2);
    for k = 1:npcs
        t_k = true_shifts(k);
        tmp_vec = -(vk_block.*t_k);
        p2 = p1 + B - 1;
        x_sol_mine(p1:p2) = tmp_vec;
        p1 = p2 + 1;
    end
    
    % ci = cos(wpi).
    p1 = block_starts_vector(VariablesLocatorMap('len_ci_block').place);
    % p2 = p1 + block_lens_vector(VariablesLocatorMap('len_ci_block').place) - 1;
    % ci_block = x_sol(p1:p2);
    for k = 1:npcs
        t_k = true_shifts(k);
        tmp_vec = (vk_block.*t_k);
        p2 = p1 + B - 1;
        x_sol_mine(p1:p2) = cos(tmp_vec);
        p1 = p2 + 1;
    end
    
    % si = sin(wni).
    if(0 == GP.flag_use_norm_constrts)
            p1 = block_starts_vector(VariablesLocatorMap('len_si_block').place);
            % p2 = p1 + block_lens_vector(VariablesLocatorMap('len_si_block').place) - 1;
            % si_block = x_sol(p1:p2);
            for k = 1:npcs
                t_k = true_shifts(k);
                tmp_vec = -(vk_block.*t_k);
                p2 = p1 + B - 1;
                x_sol_mine(p1:p2) = sin(tmp_vec);
                p1 = p2 + 1;
            end
    end

    % xi, yi 
    p1 = block_starts_vector(VariablesLocatorMap('len_xy_block').place);
    % p2 = p1 + block_lens_vector(VariablesLocatorMap('len_xy_block').place) - 1;
    % xyi_block = x_sol(p1:p2);
    p_xi_first = p1;
    tmp_vec = zeros(GP.vdim, 1);

    if(flag_which_part ~= 2)

            for r = 1:nrots 
                
                for p = 1:npcs
                    
                    rot_idx = true_rot_idxs(p);
          
                    if(r == rot_idx)
                        
                        [p_xi] = get_xi_index(p, r, p_xi_first, npcs, GP);
                        
                        % c1 = p_xi - p_xi_first + 1;
                        c1 = p_xi;
                        c2 = c1 + (2*B) - 1;
                        
                        binsVec = phaseVecsDB{p};
                        tmp_vec(1:2:end) = real(binsVec);
                        tmp_vec(2:2:end) = imag(binsVec);
        
                        x_sol_mine(c1:c2) = tmp_vec;
                    end
        
                end
        
            end    
    
    else

            for p = 1:npcs
            
                [p_xi] = get_xi_index(flag_which_part, p, [], p_xi_first, npcs, GP);
                c1 = p_xi; % p_xi - p_xi_first + 1;
                c2 = c1 + GP.vdim - 1;
                                
                binsVec = phaseVecsDB{p};
                tmp_vec(1:2:end) = real(binsVec);
                tmp_vec(2:2:end) = imag(binsVec);
                
                x_sol_mine(c1:c2) = tmp_vec;
                            
            end
    end

    % qZ
    p1 = block_starts_vector(VariablesLocatorMap('len_qZ_block').place);
    % p2 = p1 + block_lens_vector(VariablesLocatorMap('len_qZ_block').place) - 1;
    % qZ_block = x_sol(p1:p2);
    x_sol_mine(p1) = q_mine;
    p1 = p1 + 1;
    p2 = p1 + GP.vdim - 1;
    % z_vec_mine;
    temp_vec = zeros(GP.vdim, 1);
    temp_vec(1:2:end) = real(z_vec_mine);
    temp_vec(2:2:end) = imag(z_vec_mine);
    x_sol_mine(p1:p2) = temp_vec;

    % ai in [0, 1]
    if(flag_which_part ~= 2)
        p1 = block_starts_vector(VariablesLocatorMap('len_ai_block').place);
        % p2 = p1 + block_lens_vector(VariablesLocatorMap('len_ai_block').place) - 1;
        % ai_block = x_sol(p1:p2);
        for k = 1:npcs
            r = true_rot_idxs(k);
            x_sol_mine(p1 + r - 1) = 1.0;
            p1 = p1 + nrots;
        end
    end

    % norm1 variable = 1.0
    if(GP.flag_use_norm_constrts)
        p1 = block_starts_vector(VariablesLocatorMap('len_norm1var_block').place);
        x_sol_mine(p1) = 1.0;
    end

%     %====================================================================
%     % Check the constraints for this proposed solution
%     %====================================================================
%     if(flag_which_part == 2)
%         p1 = block_starts_vector(VariablesLocatorMap('len_xy_block').place);
%         p2 = p1 + GP.vdim)*npcs - 1;
%     
%         AA = gurobi_model.A(1:GP.vdim, p1:p2);
%     
%         y_mine = AA * x_sol_mine(p1:p2);
%         y_mine = y_mine(1:GP.vdim);
%     
%         xx_lsq = AA\y_mine;
%     end

    %====================================================================
    % Check the constraints for this proposed solution
    %====================================================================
    y_mine = gurobi_model.A * x_sol_mine;
    goal_mine = y_mine(1:GP.vdim);
    constr_mine = y_mine(GP.vdim+1:end);
    % goal_mine2 = goal_mine(1:2:end) + j*goal_mine(2:2:end);

    check_diff = max(abs(y2_goal_bins2 - goal_mine));
    assert(check_diff < TOL3, 'verifying goal vector failed!');

    if(flag_which_part ~= 2)
        p1 = 1;
        p2 = p1 + npcs - 1;
        constr_block_sum_ai = constr_mine(p1:p2);
        for k = 1:npcs
            assert(constr_block_sum_ai(k) == 1, 'sum ai constraint FAILED.');
        end
    end

    if(flag_which_part ~= 2)
        p1 = p2 + 1;
    else
        p1 = 1;
    end
    % p2 = p1 + npcs - 1;
    p2 = p1 + B - 1;
    constr_block_uk = constr_mine(p1:p2);
    for k = 1:B
        assert(constr_block_uk(k) == TParams.selected_uk_bins(k), 'u_k equal bins(k) constraint FAILED.');
    end
    
    p1 = p2 + 1;
    constr_block_rest = constr_mine(p1:end);
    
    if(GP.flag_use_true_ti)
        p3 = length(constr_block_rest)  - npcs + 1;
        constr_block_ti_equal_ti = constr_block_rest(p3:end);
        for k = 1:npcs
            assert(abs(constr_block_ti_equal_ti(k) - true_shifts(k)) < 1e-6 , 't_i constraint FAILED.');
        end
        
        check_abs = max(abs(constr_block_rest(1:p3-1))); 
        assert(check_abs < 1e-8 , 'other constraint FAILED.');

    else       
        check_abs = max(abs(constr_block_rest)); 
        assert(check_abs < 1e-8 , 'other constraint FAILED.');
    end
    % assert(sum(constr_block_rest) == 0, 'rest constraints FAILED.');
    
    %====================================================================
    % Verify bounds
    %====================================================================
    nvars = length(x_sol_mine);
    
    for k = 1:nvars
        assert(x_sol_mine(k) <= gurobi_model.ub(k), 'ub check failed');
        assert(x_sol_mine(k) >= gurobi_model.lb(k), 'lb check failed');
    end

    fprintf('\n\n---> gurobi_model feasibility check passed with SUCCESS.\n\n');
    dbg = 1;

end