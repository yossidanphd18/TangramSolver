function [Grid] = createGrid(tile_scratch_dims, dims)

if(nargin < 2)
    dims = [31,31];
end

    % Grid Spec    
    w0 = floor(max(tile_scratch_dims)*0.5) + 1;
    
    Grid  = []; % Grid information, models the problem.
    Grid.grid_dims = dims;
    Grid.flips = {1, 2}; 
    Grid.rot_angles  = [0, 90, 180, 270];
    Grid.rot_indxs   = [1, 2, 3, 4];
    Grid.origin_x0y0 = [w0, w0]; 
    Grid.tile_scratch_dims = tile_scratch_dims;
    Grid.w0 = w0;

end


