function [Goal] = createPuzzle_shape4(dims, npcs, visual_offset)

% Note that for the Kangaroo we FORCE visual_offset_forced=[0,0] below!!
        
    Goal.name = 'Goal';

    % create the kanagaroo puzzle:
    puzzle = zeros(dims);
    idxs = [
       142   166   167   173   193   197   198   199   200   201   202   203   204   224   225
       226   227   228   229   230   231   232   233   234   235   254   255   256   257   258
       259   260   261   262   263   264   292   293   294   295   323   324   325   326   327
       355   356   357   358   359   387   388   389   390   421   452   483   514   545   576];
    idxs = idxs.';        % Flip it
    idxs = idxs(:).';     % Linearize and make it a row vector    
    puzzle(idxs) = 1;
    
    % these are the true values for the kangaroo
    true_flips(1:npcs) = 1;
    true_rot_idxs(1:npcs) = 1;
    true_translations = {[5,4], [6,6], [4,8], [5,9], [5,11], [8,11], [7,12], [4,15], [5,13], [9,14], [10,14], [14,15]};

    % move the goal to be more centered (for better goal visualization)
    visual_offset_forced = [0,0]
    for k = 1:length(true_translations)
      txy = true_translations{k};
      txy = txy + visual_offset_forced;
      true_translations{k} = txy;
    end

    Goal.true_flips = true_flips;
    Goal.true_rot_idxs = true_rot_idxs;
    Goal.true_translations = true_translations;
    Goal.npcs = npcs;

    Goal.puzzle = puzzle;  
end


