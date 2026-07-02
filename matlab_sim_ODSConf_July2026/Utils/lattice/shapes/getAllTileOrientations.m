function [Tiles] = getAllTileOrientations(challenge_type, flips, rot_angles, rot_indxs, origin_x0y0, tile_scratch_dims, base_tile, base_tile_name, base_tile_id)
    
%     rot_indxs = Grid.rot_indxs;
%     rot_angles = Grid.rot_angles;
%     tile_scratch_dims = Grid.tile_scratch_dims;
    
    pw = 1;
    Tiles = {};

    for flip = 1:length(flips)
        flip_id = flips{flip};
        [tile] = makeTileFlip(base_tile, flip_id);
        for r = 1:length(rot_indxs)
            rot_idx  = rot_indxs(r);
            rot_teta = rot_angles(rot_idx);
            % note that 'tile' already flipped here.
            [Tiles, pw] = addTile(challenge_type, Tiles, tile, base_tile_name, base_tile_id, flip_id, rot_teta, rot_idx, origin_x0y0, tile_scratch_dims, pw);
        end
    end

    dbg = 1;
end

function [rotated_array] = rotatePolygonFixedSize(image_array, angle_degrees)
    
    dims = size(image_array);
    
    Rdefault = imref2d(size(image_array)); % The default coordinate system used by imrotate
    tX = mean(Rdefault.XWorldLimits);
    tY = mean(Rdefault.YWorldLimits);
    tTranslationToCenterAtOrigin = [1 0 0; 0 1 0; -tX -tY,1];
    theta = angle_degrees;
    tRotation = [cosd(theta) -sind(theta) 0; sind(theta) cosd(theta) 0; 0 0 1];
    tTranslationBackToOriginalCenter = [1 0 0; 0 1 0; tX tY,1];
    tformCenteredRotation = tTranslationToCenterAtOrigin*tRotation*tTranslationBackToOriginalCenter;
    tformCenteredRotation = affine2d(tformCenteredRotation);
    [rotated_array,Rout] = imwarp(image_array,tformCenteredRotation);

    rotated_array = rotated_array(1:dims(1), 1:dims(2));

end

function [Tiles, pw] = addTile(challenge_type, Tiles, tile, base_tile_name, base_tile_id, flip_id, rot_teta, rot_idx, origin_x0y0, tile_scratch_dims, pw)
   % note that 'tile' already flipped here.

    % we marked the 'center' of the tile with a value > 1.
    % look for the center marker of the tile.
    [rt0,ct0] = find(tile > 1); 
    
    [tr,tc] = size(tile);    
    
    % We have "origin_x0y0" the x,y coords of the origin on the grid.
    % All tiles are moved to this origin, rotated there and saved.
    % set the tile into a small square for rotating later below.
    T1 = zeros(tile_scratch_dims);
    T1(1:1+tr-1,1:1+tc-1) = tile;
    txy = [origin_x0y0(2)-ct0 , origin_x0y0(1)-rt0];
    
    if(strcmp(challenge_type, 'polygons'))
        % imtranslate(T1, txy , 'OutputView', 'full','FillValues', 0);
        % rotatedTile  = imrotate(T1, rot_teta, 'bicubic', 'loose');
         T1 = imtranslate(T1, txy , 'FillValues', 0);
         % rotatedTile  = imrotate(T1, rot_teta);
         % rotatedTile  = imrotate(T1, rot_teta, 'bicubic', 'loose');
         % center_rc = 0.5*(tile_scratch_dims+1);
         % center_rc = fliplr(center_rc);
         rotatedTile = rotatePolygonFixedSize(T1, rot_teta);
         
         % find the new center
         [r_center, c_center] = find(rotatedTile > 1.5);
         txy2 = origin_x0y0 - [c_center, r_center];
         rotatedTile = imtranslate(rotatedTile, txy2 , 'FillValues', 0);
         dbg = 1;
    else
        T1 = imtranslate(T1, txy , 'FillValues', 0);
        rotatedTile  = imrotate(T1, rot_teta);
    end
    
    tileInfo.base_tile_name = base_tile_name;
    tileInfo.tile_id  = base_tile_id;
    tileInfo.flip_id  = flip_id;
    tileInfo.rot_teta = rot_teta;
    tileInfo.rot_idx  = rot_idx;
    tileInfo.tile     = rotatedTile;

    already_exists = 0;
    
    if(pw == 1)
        assert(length(Tiles) == 0, 'Expecting empty Tiles{} set.');
        already_exists = 0;
    else
        L = length(Tiles);
        already_exists = 0;
        for k = 1:L
            tile = Tiles{k}.tile;
            diff = abs(tile - rotatedTile);
            if(sum(diff(:)) == 0)
                already_exists = 1;
                break;
            end
        end
    end

    if (~already_exists)
        Tiles{pw} = tileInfo;
        pw = pw + 1;
    end

end

