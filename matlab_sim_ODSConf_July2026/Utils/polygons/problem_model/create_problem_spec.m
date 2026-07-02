function [ProblemSpec] = create_problem_spec(challenge_type, Goal, TilesInfo, Grid, FlipsRotsTiles)

    % grid_dims = Grid.grid_dims;
    % tile_min_rect_width = max(Grid.tile_scratch_size);

    %====================================
    % Set Problem Spec
    %====================================
    ProblemSpec = [];
    ProblemSpec.challenge_type = challenge_type;

    ProblemSpec.npcs = TilesInfo.npcs;
    ProblemSpec.tile_min_rect_width = max(Grid.tile_scratch_size);
    ProblemSpec.max_mass = TilesInfo.max_mass; % all tiles are pentominoes (mass = 5).
    ProblemSpec.grid_dims = Grid.grid_dims;

    % rot_indxs_no_duplicates = TilesInfo.FinalPlacement.Polygons{tile_id}.RotIndxsNoDup;
    ProblemSpec.Tiles = FlipsRotsTiles;
    ProblemSpec.TilesMap = TilesInfo.TilesMap;
    ProblemSpec.Grid  = Grid;
    ProblemSpec.flip_ids = Grid.flips;
    ProblemSpec.Goal = Goal;

    ProblemSpec.limit_nshapes = max([TilesInfo.npcs, length(TilesInfo.Names)]);
    ProblemSpec.im_width_pixels = max(Grid.grid_dims);
    ProblemSpec.assumed_tmax = 500;

    % When we check fitness, how many translations should we expect ?
    % For polygons, as translations are fractional, more than 1 may win!
    if(strcmp(challenge_type,'polygons'))
        ProblemSpec.txy_winners_threshold = 2;
    else
        ProblemSpec.txy_winners_threshold = 1;
    end
end
