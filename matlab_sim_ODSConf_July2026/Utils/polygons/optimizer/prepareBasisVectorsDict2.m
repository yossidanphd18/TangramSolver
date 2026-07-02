function [TBasisDictionary, TDisqualifiedDB, GP] = prepareBasisVectorsDict2(ProblemSpec, TImages, GP)


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
        % scale_ratio = GP.scale_gain / GP.SOLVER_RESULT.scale_gain;
        prev_scale_hint_avail = 1;        
    end

    txy_tol = norm([2,2]) + 1e-3;

    pw = 1;
    for k = 1:npcs
        
        % The true solution
        %true_rot = ProblemSpec.Goal.true_rot_idxs(k);
        %true_txy = ProblemSpec.Goal.true_translations{k};
        %true_flip = ProblemSpec.Goal.true_flips(k);
        
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

                    if(GP.flag_use_disqualified_db)
                        TDisqualifiedDB.var_index(pw) = pw;
                        TDisqualifiedDB.shape_id(pw) = k;
                        TDisqualifiedDB.flip_id(pw) = f;
                        TDisqualifiedDB.rot_id(pw) = r;
                        TDisqualifiedDB.TxyInfo{pw} = TxyInfo;
                    end

                    % transalate and take only ROI
                    if(1)
                        [vertices_t] = transformPolygon(tileInfo.vertices, t_xy(1), t_xy(2), 0, 1);
                        [translatedImage] = calculateCoveredArea(vertices_t, gx_min, gx_max, gy_min, gy_max);
                        translatedImage = translatedImage(r1:r2,c1:c2);
                    else
                        tileImage = tileInfo.tile;
                        translatedImage = imtranslate(tileImage, t_xy , 'FillValues', 0);
                        translatedImage = translatedImage(r1:r2,c1:c2);
                    end

                    [basisVector, ~, ~] = reshapeTo1D(translatedImage);
                    BasisVectors(:,pw)  = basisVector;
                    pw = pw + 1;                        
                end % end loop npossibles
            end % end loop nrots

        end  % end loop nflips

        dbg = 1;

    end % end loop npcs


    % Set also the TDisqualifiedDB.forbidden_indxs :
    count_disqualified = 0;
    if(GP.flag_use_disqualified_db)
        nvars = length(TDisqualifiedDB.var_index);
        txyInfoList = TDisqualifiedDB.TxyInfo;
        for n = 1:nvars
            self_TxyInfo = TDisqualifiedDB.TxyInfo{n};
            forbidden_indxs = getForbiddenIndxs(ProblemSpec.challenge_type, self_TxyInfo, n, txyInfoList);
    
            TDisqualifiedDB.forbidden_indxs{n} = forbidden_indxs;
            count_disqualified = count_disqualified + length(forbidden_indxs);
    
            % % For debug
            % if(ismember(n, most_true_solution_idxs))
            %     check1 = intersect(most_true_solution_idxs, forbidden_indxs);
            %     if(length(check1) > 0)
            %         error('Unexpected Forbidden Indexes - Solver will Fail!!!');
            %     end
            % end        
        end
        TDisqualifiedDB.count_disqualified = count_disqualified;
    else
        TDisqualifiedDB.forbidden_indxs = {};
    end

    % Prepare the Goal vector
    [goalVector, ~, ~] = reshapeTo1D(ProblemSpec.Goal.puzzle(r1:r2, c1:c2));
    
    % pack all info into dictionary:
    TBasisDictionary = containers.Map;
    
    TBasisDictionary('CountsDB') = CountsDB;
    TBasisDictionary('BasisVectors') = BasisVectors;
    TBasisDictionary('goalVector') = goalVector;
    %TBasisDictionary('MaybeTrueSolInfo') = MaybeTrueSolInfo;
    %TBasisDictionary('most_true_solution_idxs') = most_true_solution_idxs;
    %TBasisDictionary('my_feasible_sol') = my_feasible_sol;

    %FlagInTrueSol = zeros(1, size(BasisVectors,2));
    %FlagInTrueSol(most_true_solution_idxs) = 1;
    %TBasisDictionary('FlagInTrueSol') = FlagInTrueSol;

    % play_tone(440, 1, 44100);

    dbg = 1;
end
% 
% function [best_idx] = find_best_option(SanityData_k)
% 
%     best_idx = 1;
%     best_dist = 1e5;
%     for i = 1:length(SanityData_k.txy_dist)
%         curr_dist = SanityData_k.txy_dist{i};
%         if(curr_dist < best_dist)
%             best_dist = curr_dist ;
%             best_idx = i;
%         end
%     end
% end
