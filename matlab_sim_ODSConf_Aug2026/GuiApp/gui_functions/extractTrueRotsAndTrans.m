function [SaveDB] = extractTrueRotsAndTrans(appData, SaveDB, flag_override_saved_db)
    
	Polygons = appData.Polygons;
	scratch_size = appData.scratch_size;
	Grid = appData.Grid;
	puzzle_id = appData.puzzle_id;
	challenge_type = appData.challenge_type;
	center_marker = appData.center_marker;
	
	ntiles = length(Polygons);
    rot_angles = 0:45:359;
    max_mass = -100;
    
	SaveDB.Grid.flips = {[1] [2]};
    SaveDB.Grid.rot_angles = rot_angles;
    SaveDB.Grid.rot_indxs = 1:length(rot_angles);
    SaveDB.Grid.tile_scratch_size = scratch_size;
    
    for k = 1:ntiles           
        TILE = SaveDB.TilesInfo.FinalPlacement.Tiles{k};
        theta = SaveDB.TilesInfo.FinalPlacement.Properties{k}.theta;
        flip_id = SaveDB.TilesInfo.FinalPlacement.Properties{k}.flip_id;
        max_mass = max(max_mass, sum(TILE(:)));
        txy_true = SaveDB.TilesInfo.FinalPlacement.Polygons{k}.T - Grid.origin_x0y0;
    
        SaveDB.Goal.true_translations{k} = txy_true;
        SaveDB.TilesInfo.FinalPlacement.Properties{k}.txy_true_base2goal = txy_true;
        SaveDB.Goal.true_flips(k) = flip_id;
        SaveDB.Goal.true_rot_idxs(k) = find(rot_angles == theta);
        SaveDB.TilesInfo.Names{k} = Polygons{k}.Name;
        
        poly_v = SaveDB.TilesInfo.FinalPlacement.Polygons{k}.Vertices - SaveDB.TilesInfo.FinalPlacement.Polygons{k}.T + Grid.origin_x0y0;
        [poly_image_base] = calculateCoveredArea(poly_v, Grid.xmin, Grid.xmax, Grid.ymin, Grid.ymax);
        [rc_BR] = getLeftMostCorner(poly_image_base);
        poly_image_base(rc_BR(1), rc_BR(2)) = center_marker;
        SaveDB.TilesInfo.Tiles{k} = poly_image_base;
    end
    
    if(flag_override_saved_db)
        SaveDB.TilesInfo.TilesMap = containers.Map(SaveDB.TilesInfo.Names, 1:length(SaveDB.TilesInfo.Names));
        SaveDB.TilesInfo.max_mass = max_mass;
        SaveDB.puzzle_id = puzzle_id;
        SaveDB.challenge_type = challenge_type;
        SaveDB.Grid.grid_dims = [appData.GridHeight, appData.GridWidth];
        SaveDB.Grid.xmin = Grid.xmin;
        SaveDB.Grid.xmax = Grid.xmax;
        SaveDB.Grid.ymin = Grid.ymin;
        SaveDB.Grid.ymax = Grid.ymax;
        SaveDB.Grid.scale = Grid.scale;
        SaveDB.Grid.rot_angles = rot_angles;
        SaveDB.Grid.origin_x0y0 = Grid.origin_x0y0;
        SaveDB.TilesInfo.npcs = length(SaveDB.TilesInfo.Tiles);
        
        SaveDB.Goal.puzzle = appData.CombinedAreas;
        SaveDB.Goal.inside_region_mask = appData.CombinedAreasInsideMask;
        SaveDB.Goal.edge_mask = appData.CombinedEdgeMask;
        SaveDB.Goal.npcs = SaveDB.TilesInfo.npcs;
		
        %SaveDB.Goal.Vertices = appData.Goal.Vertices;
        %SaveDB.Goal.Holes = appData.Goal.Holes;
        %SaveDB.Goal.VerticesNoOps = appData.Goal.VerticesNoOps;
        %SaveDB.Goal.VerticesInflated = appData.Goal.VerticesInflated;
        %SaveDB.Goal.VerticesDistorted = appData.Goal.VerticesDistorted;        
        %% SaveDB.Goal.OriginalVertices = appData.Goal.OriginalVertices;
    end
end 