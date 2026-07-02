function [GP] = getSpecificOptParams_v3(flag_which_part, GP)

        assert(flag_which_part == 2, 'Only part 2 should get here.');

        %======================================================================
        % flags
        %======================================================================
        if(~isfield(GP,'flag_use_integer_ai'))
            error('Please set flag_use_integer_ai in GP struct!');
            %GP.flag_use_integer_ai = 1;
        end

        GP.flag_use_special_gurobi_params = 0;
        
        % no need for MIN_Zi, we'll set it to be -MAX_Zi.
        % GP.MAX_Zi = inf;
        if(strcmp(GP.challenge_type,'polygons'))
            GP.MAX_Zi = 5;
        else
            GP.MAX_Zi = 1e3;
        end

        if(GP.gurobi_params_set_id == 1)
            GP.MIN_q = 1e-20; 
            GP.MAX_q = 10; % inf;
        elseif(GP.gurobi_params_set_id == 2)
            GP.MIN_q = 1e-12; 
            GP.MAX_q = 1;  % inf;            
        else
            GP.MIN_q = 1e-20; 
            GP.MAX_q = 10; % inf;            
        end

        if(strcmp(GP.flag_transform_type, 'none'))
            GP.MIN_q = 0;
            GP.MAX_q = 10; % inf;   
        end

        if(strcmp(GP.flag_selected_bins_mode, 'dominant'))
            GP.MIN_q = 0;
            GP.MAX_Zi = 1e3;
        end

        if(strcmp(GP.challenge_type,'polygons'))
            GP.MAX_Zi = 1;
            GP.MIN_q = 0;
            GP.MAX_q = 10; % inf;   
        end
        
        GP.flag_use_dct = 0; 
        GP.flag_use_conjugate_pairs = 0;
		GP.lambda_q = 1e5;
		
end