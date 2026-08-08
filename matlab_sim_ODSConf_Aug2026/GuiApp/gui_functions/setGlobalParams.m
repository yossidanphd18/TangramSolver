function [GP] = setGlobalParams(ProblemSpec, run_params)

    GP = run_params;
    
    if(isfield(run_params, 'SOLVER_RESULT'))
        GP.SOLVER_RESULT = run_params.SOLVER_RESULT;
    else
        GP.SOLVER_RESULT = [];
    end
    
    GP.npcs = ProblemSpec.npcs;
    GP.nrots = length(ProblemSpec.Grid.rot_angles);
    GP.nflips = length(ProblemSpec.flip_ids);
    
    GP.im_dims = size(ProblemSpec.Goal.puzzle);
    GP.grid_scale = ProblemSpec.Grid.scale; % 1 unit in continueos = K pixels.
    
    if(strcmp(ProblemSpec.challenge_type,'polygons'))
        GP.pixel_values = 1*ones(1,300);
    else
        GP.pixel_values = 231*ones(1,300);
    end

end