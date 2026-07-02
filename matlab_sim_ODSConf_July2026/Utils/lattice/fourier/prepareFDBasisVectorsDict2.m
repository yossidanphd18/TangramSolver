function [TBasisDictionary, TDisqualifiedDB] = prepareFDBasisVectorsDict2(ProblemSpec, TImages, TImagesFD, GP)

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
        
	% count the number of basis vectors (= sum number of possible translations over all pieces and rotations). 
    ntotal_possibles = 0;
    for k = 1:npcs
        for f = 1:nflips
            for r = 1:nrots
                %if(GP.flag_use_true_rots && (r ~= true_rot_idxs(k)))
                %    continue;
                %end
                T = TImages.Shapes{k}.PossibleTxyPerRot{f}{r};
                if(isempty(T))
                    cnt = 0;
                else
                    cnt = T.npossibles;
                end

                ntotal_possibles = ntotal_possibles + cnt;
            end
        end
    end
    
    b_k = GP.b_k;
	
	% b_k is vector of selected freq bins.    
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
    pw0 = -1;

    % turn on when you want to see plot.
    flag_show_plot = 0;
    if(flag_show_plot)
        close all;
        figure(46956); clf;
    end

    txy_tol = norm([2,2]);

    pw = 1;
    pw2 = -1;
    for k = 1:npcs
        
        % The true solution
        true_rot = ProblemSpec.Goal.true_rot_idxs(k);
        true_txy = ProblemSpec.Goal.true_translations{k};
        true_flip = ProblemSpec.Goal.true_flips(k);
        
        pw0 = 1;

        for f = 1:nflips
            
            Flips = TImagesFD.Shapes{k}.Flips{f};

            if(isempty(Flips)); break; end

            for r = 1:nrots
                            
                PossibleTxyPerRot = TImages.Shapes{k}.PossibleTxyPerRot{f}{r};

                if(isempty(PossibleTxyPerRot)); break; end
                if(PossibleTxyPerRot.npossibles == 0); continue; end
               
                txyList = PossibleTxyPerRot.txyList ;

                sigFD = Flips.RotatedImagesFD{r};
                
                if(flag_complex_valued_optim)
                    sigFD = sigFD.';
                end

                npossibles = length(txyList);
                npossibles2 = npossibles;
                % verify the dis-allowed hint translation.
                if(PossibleTxyPerRot.txyAllowedToUse(end) == 0)
                    warning('Im not expecting to betainc here');
                    assert(PossibleTxyPerRot.txyAllowedToUse(end-1)==1, 'txyAllowedToUse() unexpected behavior!');
                    npossibles2 = npossibles2 - 1;
                end
                    
                % if we know the rotations then collect info only from the
                % known ones!
                % 
                %if(GP.flag_use_true_rots && (r ~= true_rot_idxs(k)))
                %    continue;
                %end
    
                CountsDB(k, f, r) = npossibles2;
                
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

                    % figure; imagesc(tileInfo.tile);
                    % pause(0.2);
                    % clf;
                    
                    assert(k == tileInfo.tile_id, 'tile_id verification failed.');
                    assert(f == tileInfo.flip_id, 'flip_id verification failed.');
                    assert(r == tileInfo.rot_idx, 'rot_id verification failed.');

                    TxyInfo.t_xy = t_xy;
                    %TxyInfo.shape_id = k;
                    %TxyInfo.flip_id = f;
                    %TxyInfo.rot_id = r;
                    TxyInfo.tileInfo = tileInfo;

                    allowed_to_use = PossibleTxyPerRot.txyAllowedToUse(m);
                    if(m < npossibles)
                      assert(allowed_to_use == 1, 'allowed_to_use must be 1 here!');
                    elseif (allowed_to_use == 0)
                      assert(m == npossibles, 'allowed_to_use may be 0 only for the last element!'); 
                    end

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
                    if(strcmp(GP.challenge_type,'polygons'))
                        true_txy2 = round(true_txy);
                        StInTrueSol = [];
                        StInTrueSol.shape_id = k;
                        StInTrueSol.rot_id = r;
                        StInTrueSol.flip_id = f;
                        StInTrueSol.t_xy = t_xy;
                        StInTrueSol.allowed_to_use = allowed_to_use;
                        if(allowed_to_use)
                            StInTrueSol.var_index = pw2;
                        else
                            StInTrueSol.var_index = -1;
                        end
                        StInTrueSol.TxyInfo = TxyInfo;
                        if((r == true_rot) && (f == true_flip))
                            dbg = 1;
                        end

                        if((r == true_rot) && (f == true_flip))
                            if(norm(true_txy2 - t_xy) <= txy_tol)
                                StInTrueSol.allowed_indication = 1;
                            else
                                StInTrueSol = [];
                            end
                        else
                            StInTrueSol = [];
                        end
                    else
                        StInTrueSol = [];
                        StInTrueSol.shape_id = k;
                        StInTrueSol.rot_id = r;
                        StInTrueSol.flip_id = f;
                        StInTrueSol.t_xy = t_xy;
                        StInTrueSol.allowed_to_use = allowed_to_use;
                        if(allowed_to_use)
                            StInTrueSol.var_index = pw2;
                        else
                            StInTrueSol.var_index = -1;
                        end
                        if((r == true_rot) && (f == true_flip) && (norm(true_txy - t_xy)==0))
                            StInTrueSol.allowed_indication = 1;
                        else
                            StInTrueSol = [];
                        end
                    end

                    if(~isempty(StInTrueSol))
                        MaybeTrueSolInfo{k}{pw0} = StInTrueSol;
                        pw0 = pw0 + 1;
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
        MTSI_List = MaybeTrueSolInfo{k}; 
        true_found = 0;
        for t = 1:length(MTSI_List)
            MTSI = MTSI_List{t};
            if(isempty(MTSI))
                continue;
            end
            assert((MTSI.allowed_indication == 1),'Indications should be 1 or 2 only');
            if((norm(MTSI.t_xy - txy_true) == 0) && (true_found == 0))
                true_found = 1;
                most_true_solution_idxs(k) = MTSI.var_index;
                most_true_solution_txys{k} = MTSI.t_xy;
            end
            maybe_true_solution_idxs(end+1) = MTSI.var_index;
            maybe_true_solution_txys{end+1} = MTSI.t_xy;            
        end

        assert(true_found == 1, 'The true txy index must be found in the candidtae set!');
    end

    assert(length(most_true_solution_idxs) == npcs, 'Not enough true vectors for solution!');

    % Set also the TDisqualifiedDB.forbidden_indxs :
    nvars = length(TDisqualifiedDB.var_index);
    txyInfoList = TDisqualifiedDB.TxyInfo;

    count_disqualified = 0;
    for n = 1:nvars
        self_TxyInfo = TDisqualifiedDB.TxyInfo{n};
        forbidden_indxs = getForbiddenIndxs2(ProblemSpec.challenge_type, self_TxyInfo, n, txyInfoList, maybe_true_solution_idxs);

        TDisqualifiedDB.forbidden_indxs{n} = forbidden_indxs;
        count_disqualified = count_disqualified + length(forbidden_indxs);

        % For debug
        if(ismember(n, most_true_solution_idxs))
            check1 = intersect(most_true_solution_idxs, forbidden_indxs);
            if(length(check1) > 0)
                error('Unexpected Forbidden Indexes - Solver will Fail!!!');
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

    FlagInTrueSol = zeros(1, size(BasisVectors,2));
    FlagInTrueSol(most_true_solution_idxs) = 1;
    TBasisDictionary('FlagInTrueSol') = FlagInTrueSol;

    % play_tone(440, 1, 44100);

    dbg = 1;
end

