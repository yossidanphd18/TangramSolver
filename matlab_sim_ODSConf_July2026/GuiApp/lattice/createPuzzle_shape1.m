function [Goal] = createPuzzle_shape1(dims, npcs, visual_offset)

    if(nargin < 3)
        visual_offset = [8,8];
    end
        
    Goal.name = 'Square1';

    puzzle = zeros(dims);
    puzzle(1:8,1:8) = 1; 
    puzzle(1,1) = 0; 
    puzzle(1,8) = 0;
    puzzle(8,1) = 0; 
    puzzle(8,8) = 0;
    puzzle = imtranslate(puzzle, [10,10] , 'FillValues', 0);
    Goal.puzzle = puzzle;
    
    % these are the true values for the square1
    true_flips(1:npcs) = 1; 
    true_flips(2:3) = 2; 
    true_rot_idxs = [1,1,2,3,3,2, 1,3,2,2,4,2];
    true_translations = {[4,3], [6,5], [3,6], [5,7], [1,6], [1,1], [6,1], [0,3], [2,2], [4,0], [2,4], [7,4]};

    % translate the goal towards TR direction (for better goal visualization)
    for k = 1:length(true_translations)
      txy = true_translations{k};
      txy = txy + visual_offset;
      true_translations{k} = txy;
    end

    Goal.true_flips = true_flips;
    Goal.true_rot_idxs = true_rot_idxs;
    Goal.true_translations = true_translations;
    Goal.npcs = npcs;

end


