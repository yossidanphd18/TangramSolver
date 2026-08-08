function [ConstraintsMap] = createNumConstraintsDB_v3(flag_which_part, TDisqualifiedDB, GP)
    
    assert(flag_which_part == 2, 'should be called only for part2 at the moment!');

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

    % if using the true sol hint : <true_sol, avec> = npcs
    if(GP.flag_use_true_sol_hint)
        numLC_use_true_sol_hint =  1;
        num_lincon_vector(end+1) = numLC_use_true_sol_hint;
        ConstraintsMap('numLC_use_true_sol_hint') = numLC_use_true_sol_hint;
    end

    %================================
    % disqualified constraints
    %================================
    num_disqualifiedcon_vector = [];
    if(GP.flag_use_disqualified_db)
        numLC_disqualified = TDisqualifiedDB.count_disqualified;
        num_disqualifiedcon_vector(end+1) = numLC_disqualified;
        ConstraintsMap('numLC_disqualified') = numLC_disqualified;
    end

    % total number of constraints.
    NUM_LIN_CONS = sum(num_lincon_vector);
    NUM_DISQUALIFIED_CONS = sum(num_disqualifiedcon_vector);
    NUM_TOTAL_CONS = NUM_LIN_CONS + NUM_DISQUALIFIED_CONS;
    
    ConstraintsMap('NUM_LIN_CONS') = NUM_LIN_CONS;
    ConstraintsMap('NUM_DISQUALIFIED_CONS') = NUM_DISQUALIFIED_CONS;
    ConstraintsMap('NUM_TOTAL_CONS') = NUM_TOTAL_CONS;
    
    %======================================================================
    % num cones : we have 1 cone constraint [q Z] in Q^(2B+1)
    %======================================================================
    numCones_q_Z = 1 ;
    ConstraintsMap('numCones_q_Z') = numCones_q_Z;
    
end
