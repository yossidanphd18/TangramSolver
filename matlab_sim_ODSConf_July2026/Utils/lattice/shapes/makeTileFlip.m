function [tile] = makeTileFlip(base_tile, flip_id)
    
% flip_id = {1, 2, 3}; % None/horizontal/vertical flips

    [nr, nc] = size(base_tile);

    if(flip_id == 2)            
        tile = zeros(size(base_tile));
        j = 1;
        for i = nr:-1:1
            tile(j,:) = base_tile(i,:);
            j = j + 1;
        end                
    elseif(flip_id == 3)
        tile = zeros(size(base_tile));
        j = 1;
        for i = nc:-1:1
            tile(:,j) = base_tile(:,i);
            j = j + 1;
        end                
    else % flip=1 means no flip
        tile = base_tile;
    end

end