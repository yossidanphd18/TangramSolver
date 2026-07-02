function [GP] = getSpecificOptParams(flag_which_part, GP)

        %======================================================================
        % flags
        %======================================================================
       
        flag_use_special_gurobi_params = 0;
        flag_use_dct = 0;
        flag_use_norm_constrts = 0;
        flag_use_conjugate_pairs = 0;

        if(flag_which_part == 1)
        
            flag_use_true_ai = 0;
            flag_use_true_ti = 0;
        
            flag_use_integer_ai = 1;
            flag_use_integer_ti = 0;
        
            % intentianally force not strict approx to the sin/cos.
            funcpieces = 200;
            funcpieceerror = 1e-6;
        
            MAX_Zi = inf;
            MAX_q = inf;
            
        elseif(flag_which_part == 2)
                
            % ai already known!
            flag_use_true_ai = 1;
            % ti should be found.
            flag_use_true_ti = 0;

            % force strict approx to sin/cos
            funcpieces = -1;
            funcpieceerror = 1e-6;
        
            MAX_Zi = inf;
            MAX_q = inf;
            
            flag_use_dct = 1;
            flag_use_norm_constrts = 1;

            flag_use_integer_ai = 1;
            flag_use_integer_ti = 1;
            flag_use_conjugate_pairs = 0;
            
        else
            
            flag_use_integer_ai = 1;
            flag_use_integer_ti = 1;
        
            % force strict approx to sin/cos
            funcpieces = -1;
            funcpieceerror = 1e-6;
        
            flag_use_true_ai = 0;
            flag_use_true_ti = 0;
        
        %    MAX_Zi = 10.0;
        %    MAX_q = 10.0;
        
            MAX_Zi = inf;
            MAX_q = inf;
            
        end
        
        flag_change_sincos_params = 1;

        GP.flag_use_true_ai = flag_use_true_ai;
        GP.flag_use_true_ti = flag_use_true_ti;
        GP.flag_use_integer_ai = flag_use_integer_ai;
        GP.flag_use_integer_ti = flag_use_integer_ti;
        GP.flag_use_special_gurobi_params = flag_use_special_gurobi_params;
        GP.funcpieces = funcpieces;
        GP.funcpieceerror = funcpieceerror;
        GP.MAX_Zi = MAX_Zi;
        GP.MAX_q = MAX_q;
        GP.flag_change_sincos_params = flag_change_sincos_params;
        GP.flag_use_dct = flag_use_dct; 
        GP.flag_use_norm_constrts = flag_use_norm_constrts;
        GP.flag_use_conjugate_pairs = flag_use_conjugate_pairs;
        
end