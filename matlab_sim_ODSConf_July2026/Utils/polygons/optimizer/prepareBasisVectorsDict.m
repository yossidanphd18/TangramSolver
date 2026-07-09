function [TBasisDictionary, TDisqualifiedDB, GP] = prepareBasisVectorsDict(ProblemSpec, TImages, GP)


    npcs   = TImages.npcs;
    nflips = TImages.nflips;
    nrots  = TImages.nrots;

    rows_BB = GP.rows_BB;
    cols_BB = GP.cols_BB;
    % vec_dim = GP.vdim; % vectors dimension
    % im_dims = GP.im_dims;

    r1 = rows_BB(1);
    r2 = rows_BB(2);
    c1 = cols_BB(1); 
    c2 = cols_BB(2);

    gx_min = ProblemSpec.Grid.xmin;
    gx_max = ProblemSpec.Grid.xmax;
    gy_min = ProblemSpec.Grid.ymin;
    gy_max = ProblemSpec.Grid.ymax;

	% count the number of basis vectors (= sum number of possible translations over all pieces and rotations). 
    ntotal_possibles = 0;
    for k = 1:npcs
        for f = 1:nflips
            for r = 1:nrots
                TPR = TImages.Shapes{k}.PossibleTxyPerRot{f}{r};
                if(isempty(TPR))
                    cnt = 0;
                else
                    cnt = TPR.npossibles;
                end
                ntotal_possibles = ntotal_possibles + cnt;
            end
        end
    end
        
	% Prepare a table of disqualified vectors: meaning that if some a_i is selected for some piece, 
	% then other pieces cannot be placed at same location (translation).
	% so for each basis vector (flip f, rotation r, transation t) we keep indexes of its forbidden vectors. 
    
    TDisqualifiedDB.var_index = [];
    TDisqualifiedDB.shape_id  = [];
    TDisqualifiedDB.flip_id  = [];
    TDisqualifiedDB.rot_id  = [];
    TDisqualifiedDB.TxyInfo = {};
    TDisqualifiedDB.forbidden_indxs = {};

    % table that counts npossibles per each piece and rotation
    CountsDB = zeros(npcs, nflips, nrots);
    
    % dictionary of freq. domain vectors : size [vdim x N]. 
	BasisVectors = zeros(GP.vdim, ntotal_possibles);
    MaybeTrueSolInfo = {};

    % Do we have results from previous scale (low scale) solution ?
    prev_scale_hint_avail = 0;
    if(~isempty(GP.SOLVER_RESULT))
        % scale_ratio = GP.user_params.scale_gain / GP.SOLVER_RESULT.scale_gain;
        prev_scale_hint_avail = 1;        
    end

    txy_tol = norm([2,2]) + 1e-3;

    % for sanity check - collect vectors that could be in solution.
    SanityCheckData = {};

    pw = 1;
    for k = 1:npcs
        
        % The true solution
        true_rot = ProblemSpec.Goal.true_rot_idxs(k);
        true_txy = ProblemSpec.Goal.true_translations{k};
        true_flip = ProblemSpec.Goal.true_flips(k);
        
        found_vector = 0;
        pwf = 1;
        SanityData_k = [];

        pw0 = 1;
        for f = 1:nflips
            
            % TImages.Shapes{1}.Flips{1}.RotatedImages

            Flips = TImages.Shapes{k}.Flips{f};

            if(isempty(Flips)); break; end

            for r = 1:nrots
                            
                PossibleTxyPerRot = TImages.Shapes{k}.PossibleTxyPerRot{f}{r};

                if(isempty(PossibleTxyPerRot)); continue; end
                if(PossibleTxyPerRot.npossibles == 0); continue; end
               
                txyList = PossibleTxyPerRot.txyList ;

                npossibles = length(txyList);
        
                CountsDB(k, f, r) = npossibles;
                
                % Here we scan true passibles and also the last one that was given 
                % as a "hint" i.e. we know its a true translation but we
                % could not detect it using the 2d convolution and TH used!
                for m = 1:npossibles
                    t_xy = txyList{m} ;
   
                    tileInfo = TImages.Shapes{k}.Flips{f}.RotatedImages{r}.tileInfo;

                    assert(k == tileInfo.tile_id, 'tile_id verification failed.');
                    assert(f == tileInfo.flip_id, 'flip_id verification failed.');
                    assert(r == tileInfo.rot_idx, 'rot_id verification failed.');

                    TxyInfo.t_xy = t_xy;
                    %TxyInfo.shape_id = k;
                    %TxyInfo.flip_id = f;
                    %TxyInfo.rot_id = r;
                    TxyInfo.tileInfo = tileInfo;

                    if(GP.user_params.flag_use_disqualified_db)
                        TDisqualifiedDB.var_index(pw) = pw;
                        TDisqualifiedDB.shape_id(pw) = k;
                        TDisqualifiedDB.flip_id(pw) = f;
                        TDisqualifiedDB.rot_id(pw) = r;
                        TDisqualifiedDB.TxyInfo{pw} = TxyInfo;
                    end

                    % transalate and take only ROI
                    if(1)
                        [vertices_t] = transformPolygon(tileInfo.vertices, t_xy(1), t_xy(2), 0, 1);
                        [translatedImage] = calculateCoveredArea(vertices_t, gx_min, gx_max, gy_min, gy_max, GP.user_params.flag_quantize_pix_area);
                        translatedImage = translatedImage(r1:r2,c1:c2);
                    else
                        tileImage = tileInfo.tile;
                        translatedImage = imtranslate(tileImage, t_xy , 'FillValues', 0);
                        translatedImage = translatedImage(r1:r2,c1:c2);
                    end

                    [basisVector, ~, ~] = reshapeTo1D(translatedImage);
                    BasisVectors(:,pw)  = basisVector;

                    pw = pw + 1;
                        
                    % Collect candidates that may be part of true solution
                    true_txy2 = round(true_txy);
                    StInTrueSol = [];
                    StInTrueSol.shape_id = k;
                    StInTrueSol.rot_id = r;
                    StInTrueSol.flip_id = f;
                    StInTrueSol.t_xy = t_xy;
                    StInTrueSol.var_index = pw - 1; % keep index of the last added vector.
                    StInTrueSol.TxyInfo = TxyInfo;

                    if((r == true_rot) && (f == true_flip))
                        txy_dist = norm(true_txy2 - t_xy);
                        if(txy_dist > txy_tol)
                            StInTrueSol = [];
                        else
                            % collect the options for sanity check
                            found_vector = found_vector + 1;
                            SanityData_k.vectors{pwf} = BasisVectors(:,pw-1);
                            SanityData_k.vec_index{pwf} = (pw-1);
                            SanityData_k.true_txy{pwf} = true_txy2;
                            SanityData_k.vec_txy{pwf} = t_xy;
                            SanityData_k.txy_dist{pwf} = txy_dist;
                            pwf = pwf+1;
                        end
                    else
                        StInTrueSol = [];
                    end

                    if(~isempty(StInTrueSol))
                        MaybeTrueSolInfo{k}{pw0} = StInTrueSol;
                        pw0 = pw0 + 1;
                    end
                
                end % end loop npossibles
            end % end loop nrots

        end  % end loop nflips

        SanityCheckData{k} = SanityData_k;
  
        dbg = 1;

    end % end loop npcs

    %----------------------------------------------------------------------
    %----------------------------------------------------------------------
    % for sanity check
    %----------------------------------------------------------------------
    %----------------------------------------------------------------------
    Nr1 = diff(rows_BB)+1;
    Nc1 = diff(cols_BB)+1;
    assert(Nr1*Nc1 == prod(GP.vdim), 'Vectors dimension mis-match.');

    my_feasible_sol = zeros(npcs,1);
    possible_recon = zeros(Nr1,Nc1);

    for k = 1:npcs
        SanityData_k = SanityCheckData{k};
        if(isempty(SanityData_k))
            error(['Found no sanity vector for tile ',num2str(k)]);
        end
        best_idx = find_best_option(SanityData_k);
        vec_1d = SanityData_k.vectors{best_idx};
        my_feasible_sol(k) = SanityData_k.vec_index{best_idx};
        im_2d = reshapeTo2D(vec_1d, Nr1, Nc1);
        possible_recon = possible_recon + im_2d;
    end

    if(0) % don't do this ! No hints to solver!!
        % Set this so we'll use it in the Gurobi optimization as UB/LB of Zi.
        goal_image = ProblemSpec.Goal.puzzle(r1:r2, c1:c2);
        diff_image = goal_image - possible_recon;
        worst_abs_err = round(max(abs(diff_image(:))));
        GP.worst_abs_err = worst_abs_err;
    end

    show_sanity_test_figure = 0;
    if(show_sanity_test_figure)
        % figure; imagesc(possible_recon); colorbar;title('Sanity Check : A possible reconstruction.');        
        handleOld = findobj('Tag', 'SanityCheckBasisVectorsFig');
        if ~isempty(handleOld) 
            close(handleOld); 
        end
        figure('Tag', 'SanityCheckBasisVectorsFig', 'Name', 'Sanity: Reconstruction');
        imagesc(possible_recon); colorbar;title('Sanity Check : A possible reconstruction.');
    
        pause(0.1);    
    end
    %----------------------------------------------------------------------
    %----------------------------------------------------------------------

    % Get info of the true solution (for sanity test)
    % For Tangrams there may be more than true positions here because we
    % allowed +/-1 deviation in t_xy!
    most_true_solution_idxs = [];
    most_true_solution_txys = {};

    maybe_true_solution_idxs = []; 
    maybe_true_solution_txys = {};

    true_translations = TImages.Goal.true_translations;
    assert(length(MaybeTrueSolInfo) == npcs, 'Unexpected size to MaybeTrueSolInfo');

    for k = 1:npcs
        txy_true = true_translations{k};
        txy_true = round(txy_true);
        MTSI_List = MaybeTrueSolInfo{k}; 
        best_true_found = 0;
        best_t_xy = [1e3,1e3];
        for t = 1:length(MTSI_List)
            MTSI = MTSI_List{t};
            if(isempty(MTSI))
                continue;
            end
            if(best_true_found == 0)
                if(norm(MTSI.t_xy - txy_true) < txy_tol)
                    best_true_found = 1;
                    most_true_solution_idxs(k) = MTSI.var_index;
                    most_true_solution_txys{k} = MTSI.t_xy;
                    best_t_xy = MTSI.t_xy;
                end
            else
                if(norm(MTSI.t_xy - txy_true) < norm(best_t_xy - txy_true))
                    most_true_solution_idxs(k) = MTSI.var_index;
                    most_true_solution_txys{k} = MTSI.t_xy;
                    best_t_xy = MTSI.t_xy;
                end                
            end
            maybe_true_solution_idxs(end+1) = MTSI.var_index;
            maybe_true_solution_txys{end+1} = MTSI.t_xy;            
        end
        assert(best_true_found == 1, 'The true txy index must be found in the candidtae set!');
    end

    assert(length(most_true_solution_idxs) == npcs, 'Not enough true vectors for solution!');

    % Set also the TDisqualifiedDB.forbidden_indxs :    
    if(GP.user_params.flag_use_disqualified_db)
        nvars = length(TDisqualifiedDB.var_index);
        % fprintf('Preparing coordinate vectors using C++ MEX engine...\n');
        tic;
        
        TileIDs = zeros(nvars,1);
        for n = 1:nvars
            TileIDs(n) = TDisqualifiedDB.TxyInfo{n}.tileInfo.tile_id;
        end

        intersect_th = 5.0;

        % Speed-up using Mex function.
        if(0)
            % Call the MATLAB function
            fprintf('Running Matlab function for intersection engine...\n');
            tic;

            [ForbiddenIndxsList] = getForbiddenIndxs3(TileIDs, BasisVectors, intersect_th);
        else
            fprintf('Running optimized C++ MEX for intersection engine...\n');
            tic;
    
            % Call the new MEX function        
            ForbiddenIndxsList = getForbiddenIndxs3_mex_o1(TileIDs, BasisVectors, intersect_th);
        end

        most_true_solution_keep = most_true_solution_idxs;
        
        % this is true ONLY for shape35 at scale_gain=1.0.
        % most_true_solution_keep = [127, 742, 1286, 4913, 5201, 7700, 9811];

        for n = 1:length(most_true_solution_keep)
            excluded_cells = ForbiddenIndxsList{most_true_solution_keep(n)};
            if any(ismember(most_true_solution_keep, excluded_cells))
                infeasible = 1;
            end
        end

        count_disqualified = 0;
        for n = 1:nvars
            TDisqualifiedDB.forbidden_indxs{n} = ForbiddenIndxsList{n};
            count_disqualified = count_disqualified + length(ForbiddenIndxsList{n});
            
            % Integrity check
            if(ismember(n, most_true_solution_idxs))
                check1 = intersect(most_true_solution_idxs, ForbiddenIndxsList{n});
                if(~isempty(check1))
                    error('Unexpected Forbidden Indexes - Solver will Fail!!!');
                end
            end                        
        end
        TDisqualifiedDB.count_disqualified = count_disqualified;
        
        fprintf('C++ Engine completed in %.3f seconds.\n', toc);

    end

    % Prepare the Goal vector
    [goalVector, ~, ~] = reshapeTo1D(ProblemSpec.Goal.puzzle(r1:r2, c1:c2));
    
    % pack all info into dictionary:
    TBasisDictionary = containers.Map;
    
    TBasisDictionary('CountsDB') = CountsDB;
    TBasisDictionary('BasisVectors') = BasisVectors;
    TBasisDictionary('goalVector') = goalVector;
    TBasisDictionary('MaybeTrueSolInfo') = MaybeTrueSolInfo;
    TBasisDictionary('most_true_solution_idxs') = most_true_solution_idxs;
    TBasisDictionary('my_feasible_sol') = my_feasible_sol;

    FlagInTrueSol = zeros(1, size(BasisVectors,2));
    FlagInTrueSol(most_true_solution_idxs) = 1;
    TBasisDictionary('FlagInTrueSol') = FlagInTrueSol;

    % play_tone(440, 1, 44100);

    dbg = 1;
end

function [best_idx] = find_best_option(SanityData_k)

    best_idx = 1;
    best_dist = 1e5;
    for i = 1:length(SanityData_k.txy_dist)
        curr_dist = SanityData_k.txy_dist{i};
        if(curr_dist < best_dist)
            best_dist = curr_dist ;
            best_idx = i;
        end
    end
end
