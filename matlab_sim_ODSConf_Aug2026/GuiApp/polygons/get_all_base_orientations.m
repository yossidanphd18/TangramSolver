function [FlipsRotsTiles] = get_all_base_orientations(TilesInfo, Grid)

    npcs = TilesInfo.npcs;
    flips = cell2mat(Grid.flips); % None/horizontal flip
    rot_angles = Grid.rot_angles;
    rot_indxs = Grid.rot_indxs;
        
    nflips = length(flips);
    nrots = length(rot_angles);

    gx_min = Grid.xmin;
    gx_max = Grid.xmax;
    gy_min = Grid.ymin;
    gy_max = Grid.ymax;

    %====================================
    % Atoms Spec:
    %====================================
    FlipsRotsTiles = []; % FlipsRotsTiles info
    FlipsRotsTiles.max_mass = TilesInfo.max_mass;

    for k = 1:npcs
        for f = 1:nflips
            for r = 1:nrots
                FlipsRotsTiles.Atoms{k}.Flips{f}.RotatedTiles{r} = [];
            end
        end
    end

    txy_post = Grid.origin_x0y0;
    
    for tile_id = 1:npcs
        % Take the tile in its (0,0) orientation.
        poly_v_base_00 = TilesInfo.FinalPlacement.Polygons{tile_id}.OriginalVertices;
        flip_agnostic = TilesInfo.FinalPlacement.Polygons{tile_id}.FlipAgnostic;
        rot_indxs_no_duplicates = TilesInfo.FinalPlacement.Polygons{tile_id}.RotIndxsNoDup;


        % Get all flips and rotation (at grid's origin) for this tile.
        non_agnostic_flips = flips;
        if(flip_agnostic) % if the tile is flip-agnostic then choose only flip_id = 1 i.e. "No Flip".
            non_agnostic_flips = flips(1);
        end

        for f = 1:length(non_agnostic_flips)

            flip_id = non_agnostic_flips(f);

            for r = 1:length(rot_indxs_no_duplicates)
                rot_idx  = rot_indxs(r);
                rot_theta_deg = rot_angles(r);
                
                [vertices_frt] = transformPolygon(poly_v_base_00, txy_post(1), txy_post(2), rot_theta_deg, flip_id);
                [tile_frt] = calculateCoveredArea(vertices_frt, gx_min, gx_max, gy_min, gy_max);

                tileInfo.base_tile_name = TilesInfo.Names{tile_id};
                tileInfo.tile_id  = tile_id;
                tileInfo.flip_id  = flip_id;
                tileInfo.rot_teta = rot_theta_deg;
                tileInfo.rot_idx  = rot_idx;
                tileInfo.tile     = tile_frt;
                tileInfo.vertices = vertices_frt;

                FlipsRotsTiles.Atoms{tile_id}.Flips{flip_id}.RotatedTiles{rot_idx} = tileInfo;
            end
        end      
    end
end


