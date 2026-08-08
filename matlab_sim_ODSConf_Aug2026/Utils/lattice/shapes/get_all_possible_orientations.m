function [Tiles] = get_all_possible_orientations(challenge_type, TilesInfo, Grid)

    npcs = TilesInfo.npcs;
    max_mass = TilesInfo.max_mass;

    flips = Grid.flips; % None/horizontal flip
    rot_angles = Grid.rot_angles;
    rot_indxs = Grid.rot_indxs;
    tile_scratch_dims = Grid.tile_scratch_dims;
    origin_x0y0 = Grid.origin_x0y0;     

    nflips = length(flips);
    nrots = length(rot_angles);

    %====================================
    % Atoms Spec:
    %====================================
    Tiles = []; % Tiles info
    Tiles.max_mass = max_mass;

    for k = 1:npcs
        for f = 1:nflips
            for r = 1:nrots
                Tiles.Atoms{k}.Flips{f}.RotatedTiles{r} = [];
            end
        end
    end

    for pt = 1:npcs
        [FlipsRotsTiles] = getAllTileOrientations(challenge_type, flips, rot_angles, rot_indxs, origin_x0y0, tile_scratch_dims, TilesInfo.Tiles{pt}, TilesInfo.Names{pt}, pt);
        for k = 1:length(FlipsRotsTiles)
            tileInfo = FlipsRotsTiles{k};

            [hit_dRow_dCol] = findRelativeHits(tileInfo.tile);
            tileInfo.hit_dRow_dCol = hit_dRow_dCol;

            f = tileInfo.flip_id;
            r = tileInfo.rot_idx;
            Tiles.Atoms{pt}.Flips{f}.RotatedTiles{r} = tileInfo;    
        end
    end

    dbg = 1;
end
