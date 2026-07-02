function [TBasisDictionary, TDisqualifiedDB] = prepareFDBasisVectorsDict3(ProblemSpec, TImages, TImagesFD, GP)

    nfft                      = GP.nfft;
    flag_complex_valued_optim = GP.flag_complex_valued_optim;

    npcs   = TImages.npcs;
    nflips = TImages.nflips;
    nrots  = TImages.nrots;
    
    Nr = GP.Nr_w_pad;
    Nc = GP.Nc;
    im_dims = [Nr, Nc];

    % true_rot_idxs = TImages.true_rot_idxs;

    %====================================================================
    % prepare PhaseShifts (fourier domain) of all Pieaces in all rotations and 
    % all possible translations.
    %====================================================================
        
	% count the number of basis vectors (= sum number of possible translations over all tiles/flips/rotations). 
    ntotal_possibles = 0;
    for k = 1:npcs
        for f = 1:nflips
            for r = 1:nrots
                Options = TImages.Shapes{k}.PossibleTxyPerRot{f}{r};
                if(isempty(Options))
                    cnt = 0;
                else
                    cnt = Options.npossibles;
                end
                ntotal_possibles = ntotal_possibles + cnt;
            end
        end
    end
    
	% b_k is vector of selected freq bins.
    b_k = GP.b_k;
    goalVectorCmplx = TImagesFD.GoalFD(b_k);

	goalVector = zeros(GP.vdim, 1);
    if(flag_complex_valued_optim)
        goalVector(1:2:end) = real(goalVectorCmplx);
        goalVector(2:2:end) = imag(goalVectorCmplx);
    else
        goalVector(1:end)   = goalVectorCmplx;
    end

	% Prepare a table of disqualified vectors: meaning that if some a_i is selected for some piece, 
	% then other pieces cannot be placed at same location (translation).
	% so for each basis vector (flip f, rotation r, transation t) we keep indexes of its forbidden vectors. 
    TDisqualifiedDB.var_index = [];
    TDisqualifiedDB.shape_id  = [];
    TDisqualifiedDB.flip_id  = [];
    TDisqualifiedDB.rot_id  = [];
    TDisqualifiedDB.TxyInfo = {};
    TDisqualifiedDB.t_shift = [];
    TDisqualifiedDB.forbidden_indxs = {};

    % table that counts npossibles per each piece and rotation
    CountsDB = zeros(npcs, nflips, nrots);
    
    % dictionary of freq. domain vectors : size [vdim x N]. 
	BasisVectors = zeros(GP.vdim, ntotal_possibles);
    MaybeTrueSolInfo = {};

    % turn on when you want to see plot.
    flag_show_plot = 0;
    if(flag_show_plot)
        close all;
        figure(46956); clf;
    end

    pw = 1;
    pw2 = -1;
    for k = 1:npcs
        
        % The true solution
        true_rot = ProblemSpec.Goal.true_rot_idxs(k);
        true_txy = ProblemSpec.Goal.true_translations{k};
        true_flip = ProblemSpec.Goal.true_flips(k);
        
        for f = 1:nflips
            
            Flips = TImagesFD.Shapes{k}.Flips{f};

            if(isempty(Flips)); break; end

            for r = 1:nrots
                            
                PossibleTxyPerRot = TImages.Shapes{k}.PossibleTxyPerRot{f}{r};

                if(isempty(PossibleTxyPerRot)); break; end

                txyList = PossibleTxyPerRot.txyList ;

                sigFD = Flips.RotatedImagesFD{r};
                
                if(flag_complex_valued_optim)
                    sigFD = sigFD.';
                end

                npossibles = length(txyList);                        
                CountsDB(k, f, r) = npossibles;
                
                % Here we scan true passibles and also the last one that was given 
                % as a "hint" i.e. we know its a true translation but we
                % could not detect it using the 2d convolution and TH used!
                for m = 1:npossibles
                    t_xy = txyList{m} ;
                    
                    if(flag_complex_valued_optim)
                        [phaseShift, t_shift] = calcImageTranslationPhase(im_dims, t_xy, nfft);
                    else
                        [t_shift] = calcShiftFromTxy(im_dims, t_xy);
                    end

                    tileInfo = TImages.Shapes{k}.Flips{f}.RotatedImages{r}.tileInfo;                    
                    assert(k == tileInfo.tile_id, 'tile_id verification failed.');
                    assert(f == tileInfo.flip_id, 'flip_id verification failed.');
                    assert(r == tileInfo.rot_idx, 'rot_id verification failed.');

                    TxyInfo.t_xy = t_xy;
                    %TxyInfo.shape_id = k;
                    %TxyInfo.flip_id = f;
                    %TxyInfo.rot_id = r;
                    TxyInfo.tileInfo = tileInfo;

                    allowed_to_use = PossibleTxyPerRot.txyAllowedToUse(m);
                    assert(allowed_to_use == 1, 'expecting allowed_to_use = 1');
         
                    if(allowed_to_use)
                        TDisqualifiedDB.var_index(pw) = pw;
                        TDisqualifiedDB.shape_id(pw) = k;
                        TDisqualifiedDB.flip_id(pw) = f;
                        TDisqualifiedDB.rot_id(pw) = r;
                        TDisqualifiedDB.TxyInfo{pw} = TxyInfo;
                        TDisqualifiedDB.t_shift(pw) = t_shift;
                        
                        % apply the phase on the signal here so to form a basis
                        % dictionary.
                        if(flag_complex_valued_optim)
                            basisVector = phaseShift(b_k).*sigFD(b_k);
                            BasisVectors(1:2:end,pw) = real(basisVector);
                            BasisVectors(2:2:end,pw) = imag(basisVector);
                        else
                            basisVector = sigFD(b_k);
                            Im1 = reshapeTo2D(basisVector, im_dims(1), im_dims(2));
                            translatedImage = imtranslate(Im1, t_xy , 'FillValues', 0);
                            [basisVector, Nr1 ,Nc1] = reshapeTo1D(translatedImage);
                            BasisVectors(1:end,pw)  = basisVector;
                        end
    
                        pw = pw + 1;
                        pw2 = pw - 1; % keep index of the last added vector.
                    end % of if(allowed_to_use)
                        
                    % Collect candidates that may be part of true solution
                    StInTrueSol = [];
                    StInTrueSol.shape_id = k;
                    StInTrueSol.rot_id = r;
                    StInTrueSol.flip_id = f;
                    StInTrueSol.t_xy = t_xy;
                    StInTrueSol.TxyInfo = TxyInfo;     
                    StInTrueSol.allowed_to_use = allowed_to_use;
                    if(allowed_to_use)
                        StInTrueSol.var_index = pw2;
                    else
                        StInTrueSol.var_index = -1;
                    end
                            
                    true_txy2 = round(true_txy);
                    if((r == true_rot) && (f == true_flip) && (norm(true_txy2 - t_xy)==0))                         
                        StInTrueSol.allowed_indication = 1;
                    elseif(0 && (r == true_rot) && (f == true_flip) && (norm(true_txy2 - t_xy)<=2))
                        StInTrueSol.allowed_indication = 2; % approximate solution
                    else
                        StInTrueSol = [];
                    end

                    if(~isempty(StInTrueSol))
                        MaybeTrueSolInfo{end+1} = StInTrueSol;
                    end

                    if(flag_show_plot && (mod(m,5) == 1))
                        % sanity check - show that I found correct fitness locations with
                        % Fourier domain!
                        % here I must take all the bins!! because I do ifft to
                        % get back to image domain!
                        if(flag_complex_valued_optim)
                            sigFD2 = real(ifft(sigFD.*phaseShift));
                            [translatedImage] = reshapeTo2D(sigFD2, Nr, Nc);                            
                        end

                        Im2 = TImages.Goal.puzzle + translatedImage;

                        figure(46956); imagesc(Im2(1:GP.Nr_wo_pad,:)); colorbar;
                        pause(0.2);
                        clf;
                    end
                
                end % end loop npossibles
            end % end loop nrots

        end  % end loop nflips

        dbg = 1;

    end % end loop npcs

    % Set also the TDisqualifiedDB.forbidden_indxs :
    nvars = length(TDisqualifiedDB.var_index);
    txyInfoList = TDisqualifiedDB.TxyInfo;

    % Get info of the true solution (for sanity test)
    % For Tangrams there may be more than true positions here because we
    % allowed +/-1 deviation in t_xy!
    most_true_solution_idxs = zeros(npcs,1); 
    maybe_true_solution_idxs = zeros(npcs,1); 
    most_true_solution_txys = cell(npcs,1);
    pw1 = 1; pw2 = 1;
    for t = 1:length(MaybeTrueSolInfo)
        MTSI = MaybeTrueSolInfo{t};
        assert(((MTSI.allowed_indication == 1) || (MTSI.allowed_indication==2)),'Indications should be 1 or 2 only');
        if(MTSI.allowed_indication == 1)
            most_true_solution_idxs(pw1) = MTSI.var_index;
            most_true_solution_txys{pw1} = MTSI.t_xy;
            pw1 = pw1 + 1;
        end
        % also elements with value -1 will be here, but no harm in later usages.
        maybe_true_solution_idxs(pw2) = MTSI.var_index;
        pw2 = pw2 + 1;
    end

    for k = 1:npcs
        if(most_true_solution_idxs(k) > 0)
            continue;
        else
            % If not found a candidate for the true solution, then
            % look for "best candidate".
            best_norm = 1e6;
            best_idx = -1;
            % best_txy = [];
            for t = 1:length(MaybeTrueSolInfo)
                MTSI = MaybeTrueSolInfo{t};
                if((MTSI.shape_id == k) && MTSI.allowed_to_use)
                    check_norm = norm(TImages.Goal.true_translations{k} - MTSI.t_xy);
                    if(check_norm <= best_norm)
                        best_norm = check_norm;
                        best_idx = MTSI.var_index;
                        % best_txy = MTSI.t_xy;
                    end
                end
            end
            most_true_solution_idxs(k) = best_idx;            
        end
    end
    
    assert(length(most_true_solution_idxs) == npcs, 'Not enough true vectors for solution!');

    % Count total number of forbidden indexes.
    count_disqualified = 0;
    for n = 1:nvars
        self_TxyInfo = TDisqualifiedDB.TxyInfo{n};
        forbidden_indxs = getForbiddenIndxs2(ProblemSpec.challenge_type, self_TxyInfo, n, txyInfoList, maybe_true_solution_idxs);
        TDisqualifiedDB.forbidden_indxs{n} = forbidden_indxs;
        count_disqualified = count_disqualified + length(forbidden_indxs);
        % For debug only
        if(ismember(n, most_true_solution_idxs))
            check1 = intersect(most_true_solution_idxs, forbidden_indxs);
            if(~isempty(check1))
                warning('Unexpected Forbidden Indexes - Solver will Fail!!!');
            end
        end        
    end
    TDisqualifiedDB.count_disqualified = count_disqualified;

    % pack all info into dictionary:
    TBasisDictionary = containers.Map;
    
    TBasisDictionary('CountsDB') = CountsDB;
    TBasisDictionary('BasisVectors') = BasisVectors;
    TBasisDictionary('selectedBins') = b_k;
    TBasisDictionary('goalVector') = goalVector;
    TBasisDictionary('MaybeTrueSolInfo') = MaybeTrueSolInfo;
    TBasisDictionary('most_true_solution_idxs') = most_true_solution_idxs;

    % binary vector : for each dictionary vector (=translated option) specify if its included in the true solution.
    % used for debug only!
    BasisVectorsInTrueSol = zeros(1, size(BasisVectors,2));
    BasisVectorsInTrueSol(most_true_solution_idxs) = 1;
    TBasisDictionary('BasisVectorsInTrueSol') = BasisVectorsInTrueSol;

end

