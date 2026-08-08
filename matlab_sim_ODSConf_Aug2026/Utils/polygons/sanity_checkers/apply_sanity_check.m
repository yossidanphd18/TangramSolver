function apply_sanity_check(checker_type, Challenges, TilesInfo, FlipsRotsTiles)

    if(strcmp(checker_type, 'FeasibleSolutionExists'))
        acc1 = zeros(Challenges.Grids{1}.grid_dims);
        for tile_id = 1:length(TilesInfo.Tiles)
            flip_id = TilesInfo.FinalPlacement.Polygons{tile_id}.FlipID;
            theta_deg = TilesInfo.FinalPlacement.Polygons{tile_id}.Theta;
            txy_true2 = TilesInfo.FinalPlacement.Properties{tile_id}.txy_true_base2goal;
            rot_idx = find(theta_deg == Challenges.Grids{1}.rot_angles);
            tileInfo = FlipsRotsTiles.Atoms{tile_id}.Flips{flip_id}.RotatedTiles{rot_idx}; 
            txy_true2_r = round(txy_true2);
            acc1 = acc1 + imtranslate(tileInfo.tile, txy_true2_r, 'FillValues',0);            
        end
        % figure; imagesc(acc1);colorbar;
        absDiff = abs(Challenges.Goals{1}.puzzle - acc1);
        absDiff(absDiff < 1e-10) = 0;
        figure; subplot(2,2,1); imagesc(acc1); colorbar; title('Sanity check : Recon'); colorbar;
        subplot(2,2,2);imagesc(absDiff); colorbar; title('Diff Recon vs Goal'); colorbar;
    end

end
