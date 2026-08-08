function [TImages, GP] = calculatePossibleTranslations(ProblemSpec, TImages, GP)

    true_rot_idxs = TImages.Goal.true_rot_idxs;
    true_translations = TImages.Goal.true_translations; 
    true_flips = TImages.Goal.true_flips; 

    npcs = ProblemSpec.npcs;  
    goalImage = TImages.Goal.puzzle;
    im_dims   = [GP.Nr_w_pad, GP.Nc];
    
    nflips = length(ProblemSpec.flip_ids);
    nrots = length(ProblemSpec.Grid.rot_angles);

    tile_scratch_dims = ProblemSpec.Grid.tile_scratch_dims;
    % tile_scratch_dims = [51,51];

    r1 = tile_scratch_dims(1);
    c1 = tile_scratch_dims(2);
    conv_shift = r1; % for compensating conv delay in x/y directions.

    % initialize so we have all {tile}{flip}{rot} tuples
    for k = 1:npcs        
        for f = 1:nflips
            for r = 1:nrots
                TImages.Shapes{k}.PossibleTxyPerRot{f}{r} = {};
            end
    
        end    
    end

    corr_tol = 1 + 1e-4;
    txy_tol = norm([2,2]) + 1e-3;

    for k = 1:npcs
        
        % if(~isfield(TImages.Shapes{k}, 'mass'))
        %     dbg = 1;
        % end
        
        true_rot = true_rot_idxs(k);
        true_txy = true_translations(k); true_txy = true_txy{1};
        true_flip = true_flips(k);
        
        mass = TImages.Shapes{k}.mass;
        pixel_value = TImages.pixel_values(k);  
        
        for f = 1:nflips            
            
            Flips = TImages.Shapes{k}.Flips{f};
            
            if(isempty(Flips)); break; end

            for r = 1:nrots
                
                % find possible translations : those that fully overlaps
                % with the goal image, i.e. overlap mass = mass*pixel_value^2
                tileImageInfo = Flips.RotatedImages{r};
                
                if(isempty(tileImageInfo)); break; end
                   
                tileImage = tileImageInfo.rotImage;

                assert(max(tileImage(:)) == pixel_value,'Tile value verification failed!');
                assert(max(goalImage(:)) == pixel_value,'Goal tile value verification failed!');

                % conv2 do counterclock 180 degrees so need to take 
                % rotate 180 before conv.
                T1 = tileImage(1:r1, 1:c1);
                T1 = imrotate(T1, 180);
                fitnessImage = conv2(T1, goalImage);
                % remove small noise values:
                % precision = 1e8;
                % fitnessImage = round((fitnessImage * precision)/precision);

                % indicator to feasible translation.
                if(strcmp(ProblemSpec.challenge_type,'polygons'))
                    % sanity checks
                    check_tile_max = max(T1(:));
                    check_goal_max = max(goalImage(:));
                    check_tile_mass = sum(T1(:));
                    % remove small noise values:
                    % check_tile_mass = round((check_tile_mass * precision)/precision);
                
                    assert(check_tile_max == pixel_value, 'Unexpected tile pixel value.');
                    assert(check_goal_max == 1, 'Unexpected goal pixel value.');              
                    
                    % [I1a, J1a] = find(fitnessImage == check_tile_mass);
                    % [I1, J1] = find(abs(fitnessImage-check_tile_mass) <= corr_tol);
                    
                    max_fitness = max(max(fitnessImage));
                    [I0, J0] = find(fitnessImage > (max_fitness-4));
                    
                    % remove any negative translations because we dont
                    % expect such.
                    pw0 = 1;
                    I1 = []; J1 = [];
                    for t = 1:length(I0)
                        min_txy_check = min([I0(t)-conv_shift, J0(t)-conv_shift]);
                        if(min_txy_check < 0)
                            continue;
                        end
                        I1(pw0) = I0(t);
                        J1(pw0) = J0(t);
                        pw0 = pw0+1;
                    end

                    if((f == true_flip) && (r == true_rot))
                        dbg = 1;
                    end
                else
                    [I1, J1] = find(fitnessImage == (mass*(pixel_value^2)));
                end
                
                npossibles = length(I1);
                TImages.Shapes{k}.PossibleTxyPerRot{f}{r}.npossibles = npossibles;
                
                if(npossibles > 0)
                    I1 = I1 - conv_shift;
                    J1 = J1 - conv_shift;       
                    IJ1 = [I1,J1];
                    min_txy_check = min(IJ1(:));
                    assert(min_txy_check >= 0, 'Negative t_xy is not expected!');
                else
                    dbg = 1;
                end

                for m = 1:npossibles
                    t_x = J1(m);
                    t_y = I1(m);
                    [t_shift] = calcShiftFromTxy(im_dims, [t_x, t_y]);
                    TImages.Shapes{k}.PossibleTxyPerRot{f}{r}.txyList{m} = [t_x, t_y];
                    TImages.Shapes{k}.PossibleTxyPerRot{f}{r}.tshiftList(m) = t_shift;
                    TImages.Shapes{k}.PossibleTxyPerRot{f}{r}.txyAllowedToUse(m) = 1;
                end
    
                % If we missed the true translation (due to our discrete conv
                % method), then include that into the list.
                if((f == true_flip) && (r == true_rot))
                    true_txy2 = round(true_txy);
                    txyList = TImages.Shapes{k}.PossibleTxyPerRot{f}{r}.txyList;
                    found = 0;
                    for m = 1:length(txyList)
                        check_norm = norm(true_txy2 - txyList{m});
                        if(check_norm <= txy_tol)
                            found = 1;
                            break;
                        end
                    end
                    % Add the true t_xy at the end of list and make a note
                    % that its "not allowed to use".
                    if(found == 0)
                        error('True t_xy could not be detected using conv2!');
                        m_extra = length(txyList)+1; 
                        [t_shift2] = calcShiftFromTxy(im_dims, [true_txy2(1), true_txy2(2)]);
                        TImages.Shapes{k}.PossibleTxyPerRot{f}{r}.txyList{m_extra} = true_txy2;
                        TImages.Shapes{k}.PossibleTxyPerRot{f}{r}.tshiftList(m_extra) = t_shift2;
                        TImages.Shapes{k}.PossibleTxyPerRot{f}{r}.txyAllowedToUse(m_extra) = 0;
                    end
                end
            end

        end
    
    end
    
    % sanity check - show that I found correct fittness locations.

    show_sanity_check = 0;

    if(show_sanity_check)
	    close all;
	    figure(46956); clf;
		for k = 1:npcs
            for f = 1:nflips
                Flips = TImages.Shapes{k}.Flips{f};
                if(isempty(Flips)); break; end
                for r = 1:nrots
				    ImInfo = Flips.RotatedImages{r};
                    if(isempty(ImInfo)); break; end
                    Im = ImInfo.rotImage;
				    txyList = TImages.Shapes{k}.PossibleTxyPerRot{f}{r}.txyList ;
				    for m = 1:length(txyList)
					    Im2 = goalImage + imtranslate(Im, txyList{m} , 'FillValues', 0);
					    figure(46956); imagesc(Im2); colorbar;
					    pause(0.05);
                        dbg = 1;
					    clf;
				    end
                end
            end
		end
    end

    dbg = 1;

end
