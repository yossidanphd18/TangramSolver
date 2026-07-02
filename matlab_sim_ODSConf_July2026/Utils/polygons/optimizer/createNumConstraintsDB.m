function [ConstraintsMap] = createNumConstraintsDB(TDisqualifiedDB, GP)
    
    ConstraintsMap = containers.Map;

    npcs = GP.npcs;
    
    %================================
    % linear constraints
    %================================
    num_lincon_vector = [];
    
    % Y2 = H2 * x + Z
    numLC_y_equal_Hx_plus_Z = GP.zi_len ;
    num_lincon_vector(end+1) = numLC_y_equal_Hx_plus_Z;
    ConstraintsMap('numLC_y_equal_Hx_plus_Z') = numLC_y_equal_Hx_plus_Z;
       
    % sum(a_i) = 1, for each pieace.
    numLC_sum_ai_equal_1 =  npcs;
    num_lincon_vector(end+1) = numLC_sum_ai_equal_1;
    ConstraintsMap('numLC_sum_ai_equal_1') = numLC_sum_ai_equal_1;

    % % if using the true sol hint : inner product <true_sol, avec> = npcs
    % if(GP.flag_use_true_sol_hint)
    %     numLC_use_true_sol_hint =  1;
    %     num_lincon_vector(end+1) = numLC_use_true_sol_hint;
    %     ConstraintsMap('numLC_use_true_sol_hint') = numLC_use_true_sol_hint;
    % end

    if(GP.user_params.flag_disqualified_as_lin_cons)
        numLC_disqualified = TDisqualifiedDB.count_disqualified;
        ConstraintsMap('numLC_disqualified') = numLC_disqualified;
    else
        numLC_disqualified = 0;
    end

    %================================
    % disqualified constraints
    %================================
    if(GP.user_params.flag_use_disqualified_db)
        if(GP.user_params.flag_disqualified_as_lin_cons)
            numGENCOND_disqualified = 0;
        else
            numGENCOND_disqualified = TDisqualifiedDB.count_disqualified; 
        end
        ConstraintsMap('numGENCOND_disqualified') = numGENCOND_disqualified;
    else
        numGENCOND_disqualified = 0;
    end

    % total number of constraints.
    NUM_LIN_CONS = sum(num_lincon_vector);
    NUM_LIN_CONS_DISQUALIFIED = numLC_disqualified;
    NUM_DISQUALIFIED_GENCOND_CONS = numGENCOND_disqualified;
    NUM_TOTAL_CONS = NUM_LIN_CONS + NUM_LIN_CONS_DISQUALIFIED + NUM_DISQUALIFIED_GENCOND_CONS;
    
    ConstraintsMap('NUM_LIN_CONS') = NUM_LIN_CONS;
    ConstraintsMap('NUM_LIN_CONS_DISQUALIFIED') = NUM_LIN_CONS_DISQUALIFIED;
    ConstraintsMap('NUM_DISQUALIFIED_GENCOND_CONS') = NUM_DISQUALIFIED_GENCOND_CONS;
    ConstraintsMap('NUM_TOTAL_CONS') = NUM_TOTAL_CONS;
    
    %======================================================================
    % num cones : we have 1 cone constraint [q Z] in Q^(2B+1)
    %======================================================================
    numCones_q_Z = 1 ;
    ConstraintsMap('numCones_q_Z') = numCones_q_Z;
    
end
