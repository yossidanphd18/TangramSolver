function [Goal] = createPuzzle_shape2(dims, npcs, visual_offset)

    if(nargin < 3)
        visual_offset = [8,8];
    end
        
    Goal.name = 'Square2';

    puzzle = zeros(dims);
    puzzle(1:8,1:8) = 1; 
    puzzle(4:5,4:5) = 0; 
    puzzle = imtranslate(puzzle, [10,10] , 'FillValues', 0);
    Goal.puzzle = puzzle;

    % these are the true values for the square2
    true_flips(1:npcs) = 1; true_flips(2) = 2;  true_flips(5) = 2; true_flips(9) = 2; true_flips(11) = 2;  
    true_rot_idxs = [2,3,2,2,3, 1, 1, 1,2,1,1,1];
    true_translations = {[6,2], [1,4], [5,6], [0,1], [4,2], [3,6], [2,1], [7,4], [2,7], [7,6], [0,4], [5,0]};
    
    % move the goal to be more centered (for better goal visualization)
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


