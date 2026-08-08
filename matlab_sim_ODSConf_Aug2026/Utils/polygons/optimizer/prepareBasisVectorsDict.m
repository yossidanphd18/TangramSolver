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
    BasisPolygons = {}; % the polygons representing each basis vector.
    pw = 1;
    for k = 1:npcs
        
        % The true solution
        % true_rot = ProblemSpec.Goal.true_rot_idxs(k);
        % true_txy = ProblemSpec.Goal.true_translations{k};
        % true_flip = ProblemSpec.Goal.true_flips(k);
        
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
                
                for m = 1:npossibles
                    t_xy = txyList{m} ;
   
                    tileInfo = TImages.Shapes{k}.Flips{f}.RotatedImages{r}.tileInfo;

                    assert(k == tileInfo.tile_id, 'tile_id verification failed.');
                    assert(f == tileInfo.flip_id, 'flip_id verification failed.');
                    assert(r == tileInfo.rot_idx, 'rot_id verification failed.');

                    TxyInfo.t_xy = t_xy;
                    TxyInfo.tileInfo = tileInfo;
                    %TxyInfo.shape_id = k;
                    %TxyInfo.flip_id = f;
                    %TxyInfo.rot_id = r;

                    if(GP.user_params.flag_use_disqualified_db)
                        TDisqualifiedDB.var_index(pw) = pw;
                        TDisqualifiedDB.shape_id(pw) = k;
                        TDisqualifiedDB.flip_id(pw) = f;
                        TDisqualifiedDB.rot_id(pw) = r;
                        TDisqualifiedDB.TxyInfo{pw} = TxyInfo;
                    end

                    % transalate and take only ROI
                    % the polyon tileInfo.vertices here is already at its
                    % correct flip, so we use apply_flip=0, and is_fwd_transform=1. 
                    apply_flip = 0; is_fwd_transform = 1;
                    [vertices_t] = transformPolygon(tileInfo.vertices, t_xy(1), t_xy(2), apply_flip, is_fwd_transform);
                    [translatedImage] = calculateCoveredArea(vertices_t, gx_min, gx_max, gy_min, gy_max, GP.user_params.flag_quantize_pix_area);
                    translatedImage = translatedImage(r1:r2,c1:c2);

                    [basisVector, ~, ~] = reshapeTo1D(translatedImage);
                    BasisVectors(:,pw)  = basisVector;
                    BasisPolygons{pw} = vertices_t;

                    pw = pw + 1;
                                        
                end % end loop npossibles
            end % end loop nrots

        end  % end loop nflips
  
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
    %----------------------------------------------------------------------
    %----------------------------------------------------------------------

    % Set also the TDisqualifiedDB.forbidden_indxs :    
    if(GP.user_params.flag_use_disqualified_db)
        nvars = length(TDisqualifiedDB.var_index);
        tic;
        
        TileIDs = zeros(nvars,1);
        for n = 1:nvars
            TileIDs(n) = TDisqualifiedDB.TxyInfo{n}.tileInfo.tile_id;
        end

        areaMinPercentage = 0.03; % allow 3% intersection.
 
        % Speed-up using Mex function.
        fprintf('Running Matlab MEXed function for intersection engine...\n');

        tic;
        
        % [ForbiddenIndxsList] = getForbiddenIndxs3(TileIDs, BasisVectors, intersect_th);            
        
        [ForbiddenIndxsList, ForbiddenAreasList] = getForbiddenIndxs4(TileIDs, BasisPolygons, areaMinPercentage);

        TDisqualifiedDB.forbidden_indxs = ForbiddenIndxsList;
        TDisqualifiedDB.forbidden_areas = ForbiddenAreasList;
        TDisqualifiedDB.count_disqualified = sum(cellfun(@length, ForbiddenIndxsList));  
        
        toc;
  
        fprintf('C++ Engine completed in %.3f seconds.\n', toc);
    end

    % Prepare the Goal vector
    [goalVector, ~, ~] = reshapeTo1D(ProblemSpec.Goal.puzzle(r1:r2, c1:c2));

    % Save both basis vectors and basis polygons.
    BasisVectorsDB.BasisVectors = BasisVectors;
    BasisVectorsDB.BasisPolygons = BasisPolygons;
    
    % pack all info into dictionary:
    TBasisDictionary = containers.Map;
    TBasisDictionary('CountsDB') = CountsDB;
    TBasisDictionary('BasisVectorsDB') = BasisVectorsDB;
    TBasisDictionary('goalVector') = goalVector;
    
    dbg = 1;
end

