function sanityCheckGoalImage(Goal, Tiles, show_goal_figure)

    if(show_goal_figure)
      ZerosIm = zeros(size(Goal.puzzle));
      ImAcc = ZerosIm;
      for k = 1:Goal.npcs
        f = Goal.true_flips(k);
        r = Goal.true_rot_idxs(k);
        tile = Tiles.Atoms{k}.Flips{f}.RotatedTiles{r}.tile;
        tile(tile~=0) = 1;
        tile_dims = size(tile);
        txy = Goal.true_translations{k};
        Im1 = ZerosIm;
        Im1(1:tile_dims(1),1:tile_dims(2)) = tile;
        Im1 = imtranslate(Im1, txy , 'FillValues', 0);
        ImAcc = ImAcc + Im1;
        dbg = 1;
      end
      figure(1); 
      subplot(2,2,1); imagesc(ImAcc); title('goal composed from the tiles');
      subplot(2,2,2); imagesc(ImAcc-Goal.puzzle); title('diff vs reference');
      dbg = 1;
    end  

end
