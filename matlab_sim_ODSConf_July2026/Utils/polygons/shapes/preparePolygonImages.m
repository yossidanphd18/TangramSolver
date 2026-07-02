function [TImages, GP] = preparePolygonImages(ProblemSpec, GP)

    pixel_values = GP.pixel_values;
    
    ZerosImage = zeros(GP.im_dims);
    
    TilesMap = ProblemSpec.TilesMap;
    
    npcs = GP.npcs;   
    nflips = GP.nflips;
    nrots  = GP.nrots;
    
    % initialize so we have all {tile}{flip}{rot} triples
    TImages = [];
    for k = 1:npcs
        for f = 1:nflips
            for r = 1:nrots
                TImages.Shapes{k}.Flips{f}.RotatedImages{r} = {};
            end
        
        end    
    end
    
    for k = 1:npcs
        rot_indxs_no_dup = ProblemSpec.TilesInfo.FinalPlacement.Polygons{k}.RotIndxsNoDup;
        for f = 1:nflips
            for r = 1:nrots
                tileInfo = ProblemSpec.Tiles.Atoms{k}.Flips{f}.RotatedTiles{r};
                
                if(isempty(tileInfo))
                    continue;
                end
    
                name = tileInfo.base_tile_name;
                tile = tileInfo.tile;
                flip_id = tileInfo.flip_id;
                rot_idx = tileInfo.rot_idx;
                tile_id = TilesMap(name);
            
                % remove the center marker, so all tile values are the same.
                pix_val = pixel_values(k);
                if(strcmp(ProblemSpec.challenge_type,'polygons'))
                    tile = min(tile, pix_val);
                else
                    tile((tile ~= 0)) = pix_val;
                end
                
                [nr, nc] = size(tile);
                
                rotImage = ZerosImage;
                rotImage(1:1+nr-1,1:1+nc-1) = tile;
                
                rotImageInfo.rotImage = rotImage;
                rotImageInfo.tileInfo = tileInfo;
    
                TImages.Shapes{tile_id}.mass = nnz(tileInfo.tile);
            
                TImages.Shapes{tile_id}.Flips{flip_id}.RotatedImages{rot_idx} = rotImageInfo; 
                
                dbg = 1;
            end
        
        end    
    end
    
    % remove the center marker, so all tile values are the same.
    % set unified pixel value in goal image.
    if(~strcmp(ProblemSpec.challenge_type,'polygons'))
        goalImage = ProblemSpec.Goal.puzzle;
        goalImage(goalImage ~= 0) = pixel_values(1);
        ProblemSpec.Goal.puzzle = goalImage;
    end
    
    TImages.Goal = ProblemSpec.Goal;
    TImages.pixel_values = pixel_values;
    TImages.npcs = npcs;
    TImages.nflips = nflips;
    TImages.nrots = nrots;
    
    fprintf("\n---> completed PREPS stage 1..\n");

end % of function.