function [Goal] = createPuzzle_shape3(dims, npcs, visual_offset)

    if(nargin < 3)
        visual_offset = [8,8];
    end
        
    Goal.name = 'Square3';

    puzzle = zeros(dims);
    puzzle(1:8,1:8) = 1; 
    puzzle(2,2) = 0; 
    puzzle(2,7) = 0;
    puzzle(7,2) = 0; 
    puzzle(7,7) = 0;
    puzzle = imtranslate(puzzle, [10,10] , 'FillValues', 0);
    Goal.puzzle = puzzle;

    % these are the true values for the square3
    true_flips(1:npcs) = 1;
    true_rot_idxs = [2,2,1,3,1, 2, 1, 1,1,4,4,2];
    true_translations = {[3,6], [4,0], [2,4], [1,7], [5,2], [5,6], [2,2], [7,7], [0,3], [5,4], [1,0], [7,2]};

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


