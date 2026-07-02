function [TImages, GP] = calculatePossibleTranslations(ProblemSpec, TImages, GP)

true_rot_idxs = TImages.Goal.true_rot_idxs;
true_translations = TImages.Goal.true_translations; 
true_flips = TImages.Goal.true_flips; 

npcs = ProblemSpec.npcs;  
im_dims   = GP.im_dims;

nflips = length(ProblemSpec.flip_ids);
nrots = length(ProblemSpec.Grid.rot_angles);

% initialize so we have all {tile}{flip}{rot} tuples
for k = 1:npcs        
    for f = 1:nflips
        for r = 1:nrots
            TImages.Shapes{k}.PossibleTxyPerRot{f}{r} = {};
        end
    end    
end

prev_scale_hint_avail = 0;
if(~isempty(GP.SOLVER_RESULT))
    % when you are in the second pass (high-res), we 
    % norm_thresh_prev_scale_1 = norm([2, 2]);
    prev_scale_hint_avail = 1;
end

txy_dist_tol = norm([0,2]) + 1e-3;

scale_gain = GP.user_params.scale_gain;

% Goal polygon coordinates
Gxy = TImages.Goal.Vertices;
grid_step = 1; % the image is pixelized so step between pixels is 1.
if(scale_gain < 1.0)
    inflate_tol = 0.5;
else
    inflate_tol = 0.5;
end

for k = 1:npcs
            
    true_rot = true_rot_idxs(k);
    true_txy = true_translations(k); true_txy = true_txy{1};
    true_flip = true_flips(k);
    
    edges_only = false;
    if(startsWith(ProblemSpec.TilesInfo.Names{k}, 'LargeTriangle'))
        edges_only = true;
    end

    if(prev_scale_hint_avail)
        % when we are in high resolution pass, the previously found 
        % txy = [a, b] (in low-resolution) is 2*[a,b] in high resolution. 
        %
        scale_ratio = scale_gain / GP.SOLVER_RESULT.scale_gain;
        txy_prev_scale = (GP.SOLVER_RESULT.found_txy{k}) * scale_ratio;
        rot_id_prev_scale = (GP.SOLVER_RESULT.found_rots_id(k));
        flip_id_prev_scale = (GP.SOLVER_RESULT.found_flips_id(k));
    end

    for f = 1:nflips            
        
        Flips = TImages.Shapes{k}.Flips{f};
        
        if(isempty(Flips)); break; end

        for r = 1:nrots

            % results from the previous scale (if exists)
            ignore_options = 0;
            PreveScaleHints.norm_thresh = inf;
            PreveScaleHints.txy_prev_scale = [];            
            if(prev_scale_hint_avail)
                if((r == rot_id_prev_scale) && (f == flip_id_prev_scale))
                    PreveScaleHints.norm_thresh = norm([3, 3]);
                    PreveScaleHints.txy_prev_scale = txy_prev_scale;
                else
                    ignore_options = 1;
                end
            end
            
            tileImageInfo = Flips.RotatedImages{r};
            
            if(isempty(tileImageInfo)); continue; end

            % tile polygon coordinates
            Pxy = tileImageInfo.tileInfo.vertices;

            if(~prev_scale_hint_avail)
                if((f == true_flip) && (r == true_rot))
                    dbg = k;
                    dbg = 1;
                end

                % evaluate options on first pass solution
                [feasible_txy] = find_feasible_translations(Gxy, Pxy, edges_only, [0,im_dims(1)], [0,im_dims(2)], grid_step, inflate_tol, PreveScaleHints);
                if((f == true_flip) && (r == true_rot))
                    [closest_point, closest_dist, closest_index] = find_closest_point(true_txy, feasible_txy);
                    if(closest_dist >= txy_dist_tol)
                        dbg = 1;
                    end
                    assert(closest_dist < txy_dist_tol, 'Could not find a feasible txy with an acceptable tolreance!');
                end
                dbg = 1;
            else
                if(~ignore_options)
                    [feasible_txy] = find_feasible_translations(Gxy, Pxy, edges_only, [0,im_dims(1)], [0,im_dims(2)], grid_step, inflate_tol, PreveScaleHints);
                    if((r == rot_id_prev_scale) && (f == flip_id_prev_scale))
                        dbg = 1;
                    end
                else
                    feasible_txy = [];
                end
            end

            % verify that we found a closest candidate!
            if((f == true_flip) && (r == true_rot) && prev_scale_hint_avail && 0)
                [closest_point, closest_dist, closest_index] = find_closest_point(true_txy, feasible_txy);
                if(closest_dist >= txy_dist_tol)
                    dbg = 1;
                end
                assert(closest_dist < txy_dist_tol, 'Could not find a feasible txy with an acceptable tolreance!');
            end

            npossibles = size(feasible_txy, 1);
            TImages.Shapes{k}.PossibleTxyPerRot{f}{r}.npossibles = npossibles;

            for m = 1:npossibles
				TImages.Shapes{k}.PossibleTxyPerRot{f}{r}.txyList{m} = feasible_txy(m,:);
                %t_x = feasible_txy(m,1);
                %t_y = feasible_txy(m,2);
                %[t_shift] = calcShiftFromTxy(im_dims, [t_x, t_y]);
                %TImages.Shapes{k}.PossibleTxyPerRot{f}{r}.txyList{m} = [t_x, t_y];
                %TImages.Shapes{k}.PossibleTxyPerRot{f}{r}.tshiftList(m) = t_shift;
                % TImages.Shapes{k}.PossibleTxyPerRot{f}{r}.txyAllowedToUse(m) = 1;
            end
           
            dbg = 1;
        end % end rots

    end % end flips

end % end shapes
    
% Find the boundaries
goalImage = TImages.Goal.puzzle;
[rows, cols] = find(goalImage > 0); 
r1 = min(rows) - 1;
r2 = max(rows) + 1;
c1 = min(cols) - 1;
c2 = max(cols) + 1;

% set the bounding box range and the vectors dimension
GP.rows_BB = [r1,r2];
GP.cols_BB = [c1,c2];
GP.vdim = (r2-r1+1)*(c2-c1+1);

% sanity check - show that I found correct fittness locations.
show_sanity_check = 0;
if(show_sanity_check)

    handleOld = findobj('Tag', 'SanityCheckTranslationsFig');
    if ~isempty(handleOld) 
        close(handleOld); 
    end
    figure('Tag', 'SanityCheckTranslationsFig', 'Name', 'Sanity: Reconstruction');

	for k = 1:npcs
        for f = 1:nflips
            Flips = TImages.Shapes{k}.Flips{f};
            if(isempty(Flips)); break; end
            for r = 1:nrots
			    ImInfo = Flips.RotatedImages{r};
                if(isempty(ImInfo)); break; end
                
                if(isempty(TImages.Shapes{k}.PossibleTxyPerRot{f}{r})); break; end;

                if(TImages.Shapes{k}.PossibleTxyPerRot{f}{r}.npossibles == 0); break; end;

                Im = ImInfo.rotImage;
                
			    txyList = TImages.Shapes{k}.PossibleTxyPerRot{f}{r}.txyList ;
			    for m = 1:length(txyList)
				    Im2 = goalImage + imtranslate(Im, txyList{m} , 'FillValues', 0);
                    hFig = findobj('Tag', 'SanityCheckTranslationsFig');
                    if ~isempty(hFig)
                        figure(hFig);
                        imagesc(Im2(r1:r2,c1:c2)); colorbar;
                        pause(0.05);
                        dbg = 1;
                        clf(hFig); 
                    end
			    end
            end
        end
	end
end

dbg = 1;

end % end function
