function [GP] = getSpecificOptParams(GP)

        assert(GP.flag_which_part == 2, 'Only part 2 should get here.');

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

        if(strcmp(GP.challenge_type,'polygons'))
            if(1)
                GP.MIN_q = 0;
                
                scale_TH = 1.0;
                if(GP.user_params.scale_gain < scale_TH)
                    GP.MAX_Zi = 10;
                else
                    GP.MAX_Zi = 10;
                end
                
                %total_mass = (GP.grid_scale)^2; % Square challenge was 1x1 and we made 1 = grid_scale pixels 
                %edges_mass = round(0.3*total_mass);
                % the intention is : object mass * worst error  
                %maxQ = norm(GP.MAX_Zi * ones(edges_mass,1)); 
                %maxQ2 = maxQ.^2;
                
                GP.MAX_q = 1e7;
                % GP.MAX_q = 3e3;
                
                % if(GP.scale_gain < scale_TH)
                %     GP.MAX_q = 1e7;
                % else
                %     GP.MAX_q = 1e7;
                % end
            else
                % GP.MAX_Zi = 1;
                % GP.MIN_q = 0;
                % GP.MAX_q = 10; % inf;   
    
                GP.MAX_Zi = 2 * GP.worst_abs_err;
                GP.MIN_q = 0;
                
                % I assume the error is concentrated on the edges, which are
                % say 30% of the object mass. Our Tangram is 1x1 square where
                % 1unity = GP.grid_scale.
                %
                total_mass = (GP.grid_scale)^2;
                edges_mass = round(0.3*total_mass);
                % object mass * worst error  
                maxQ = norm(GP.worst_abs_err * ones(edges_mass,1)); 
                maxQ2 = maxQ.^2;
                GP.MAX_q = maxQ2;
            end
        end
        
		GP.lambda_q = 1e5;
		% GP.lambda_q = 1.0;
end