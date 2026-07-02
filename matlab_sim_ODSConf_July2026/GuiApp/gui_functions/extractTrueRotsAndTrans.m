function appData = extractTrueRotsAndTrans(appData, flag_override_saved_db)
    ntiles = length(appData.Polygons);
    rot_angles = 0:45:359;
    max_mass = -100;
    appData.SaveDB.Grid.flips = {[1] [2]};
    appData.SaveDB.Grid.rot_angles = rot_angles;
    appData.SaveDB.Grid.rot_indxs = 1:length(rot_angles);
    appData.SaveDB.Grid.tile_scratch_size = appData.scratch_size;
    
    for k = 1:ntiles           
        TILE = appData.SaveDB.TilesInfo.FinalPlacement.Tiles{k};
        theta = appData.SaveDB.TilesInfo.FinalPlacement.Properties{k}.theta;
        flip_id = appData.SaveDB.TilesInfo.FinalPlacement.Properties{k}.flip_id;
        max_mass = max(max_mass, sum(TILE(:)));
        txy_true = appData.SaveDB.TilesInfo.FinalPlacement.Polygons{k}.T - appData.Grid.origin_x0y0;
    
        appData.SaveDB.Goal.true_translations{k} = txy_true;
        appData.SaveDB.TilesInfo.FinalPlacement.Properties{k}.txy_true_base2goal = txy_true;
        appData.SaveDB.Goal.true_flips(k) = flip_id;
        appData.SaveDB.Goal.true_rot_idxs(k) = find(rot_angles == theta);
        appData.SaveDB.TilesInfo.Names{k} = appData.Polygons{k}.Name;
        
        poly_v = appData.SaveDB.TilesInfo.FinalPlacement.Polygons{k}.Vertices - appData.SaveDB.TilesInfo.FinalPlacement.Polygons{k}.T + appData.Grid.origin_x0y0;
        [poly_image_base] = calculateCoveredArea(poly_v, appData.Grid.xmin, appData.Grid.xmax, appData.Grid.ymin, appData.Grid.ymax);
        [rc_BR] = getLeftMostCorner(poly_image_base);
        poly_image_base(rc_BR(1), rc_BR(2)) = appData.center_marker;
        appData.SaveDB.TilesInfo.Tiles{k} = poly_image_base;
    end
    
    if(flag_override_saved_db)
        appData.SaveDB.TilesInfo.TilesMap = containers.Map(appData.SaveDB.TilesInfo.Names, 1:length(appData.SaveDB.TilesInfo.Names));
        appData.SaveDB.TilesInfo.max_mass = max_mass;
        appData.SaveDB.puzzle_id = appData.puzzle_id;
        appData.SaveDB.challenge_type = appData.challenge_type;
        appData.SaveDB.Grid.grid_dims = [appData.GridHeight, appData.GridWidth];
        appData.SaveDB.Grid.xmin = appData.Grid.xmin;
        appData.SaveDB.Grid.xmax = appData.Grid.xmax;
        appData.SaveDB.Grid.ymin = appData.Grid.ymin;
        appData.SaveDB.Grid.ymax = appData.Grid.ymax;
        appData.SaveDB.Grid.scale = appData.Grid.scale;
        appData.SaveDB.Grid.rot_angles = rot_angles;
        appData.SaveDB.Grid.origin_x0y0 = appData.Grid.origin_x0y0;
        appData.SaveDB.TilesInfo.npcs = length(appData.SaveDB.TilesInfo.Tiles);
        
        appData.SaveDB.Goal.puzzle = appData.CombinedAreas;
        appData.SaveDB.Goal.inside_region_mask = appData.CombinedAreasInsideMask;
        appData.SaveDB.Goal.edge_mask = appData.CombinedEdgeMask;
        appData.SaveDB.Goal.npcs = appData.SaveDB.TilesInfo.npcs;
        appData.SaveDB.Goal.OriginalVertices = appData.Goal.OriginalVertices;
        appData.SaveDB.Goal.Vertices = appData.Goal.Vertices;            
    end
end 