function [TImagesFD] = sanityCheckFourierDomainModel(TImages, TImagesFD, GP, challenge_type, ...
    txy_winners_threshold, TBasisDictionary)

if(nargin < 5)
    txy_winners_threshold = 1;
end

if(nargin < 4)
    challenge_type = 'pentominos';
end

    flag_complex_valued_optim = GP.flag_complex_valued_optim;

    npcs = GP.npcs;
    % nrots = GP.nrots;
    nfft = GP.nfft;
    Nr = GP.Nr_w_pad;
    Nc = GP.Nc;

    im_dims = [Nr, Nc];

    true_rot_idxs = TImages.Goal.true_rot_idxs;
    true_translations = TImages.Goal.true_translations; 
    true_flips = TImages.Goal.true_flips; 

    imAcc = zeros(im_dims);
    
    if(strcmp(GP.flag_selected_bins_mode,'dominant'))
        accFD1 = zeros(1,GP.nbins);
    end

    truePhaseShiftsFD = {};
    min_t_shift = 1e6;
    max_t_shift = 0;
    
    true_shifts = zeros(size(true_rot_idxs));

    for k = 1:npcs
        rot_idx = true_rot_idxs(k);
        t_xy = true_translations{k};
        flip_id = true_flips(k);
            
        sigFD = TImagesFD.Shapes{k}.Flips{flip_id}.RotatedImagesFD{rot_idx};
        
        if(flag_complex_valued_optim)
            [phaseShift, t_shift] = calcImageTranslationPhase(im_dims, t_xy, nfft);
        else
            [t_shift] = calcShiftFromTxy(im_dims, t_xy);
        end

        true_shifts(k) = t_shift;
        min_t_shift = min([min_t_shift, t_shift]);       
        max_t_shift = max([max_t_shift, t_shift]);

        % translate the image in the frequency domain
        if(flag_complex_valued_optim)
            sigFD2 = real(ifft(sigFD.*phaseShift.'));
            truePhaseShiftsFD{k} = phaseShift;
            [Image] = reshapeTo2D(sigFD2, Nr, Nc);

            if(strcmp(GP.flag_selected_bins_mode,'dominant'))
	            sigFD1 = sigFD(GP.b_k).*phaseShift(GP.b_k).';	            
	            accFD1 = accFD1 + sigFD1;
            end	
        else
            Im1 = reshapeTo2D(sigFD, im_dims(1), im_dims(2));
            truePhaseShiftsFD{k} = -1;
            Image = imtranslate(Im1, t_xy , 'FillValues', 0);
        end

        imAcc = imAcc + Image;
    end

    nr = GP.Nr_wo_pad;
    % nc = GP.Nc;
    figure; imagesc(imAcc(1:nr,:)); title('Freq Domain sanity check 1.');  colorbar;

    if(strcmp(GP.flag_selected_bins_mode,'dominant'))
        gFD = TImagesFD.GoalFD(GP.b_k);
        absDiff = abs(gFD - accFD1);
        TH = 1e-9;
        assert(max(absDiff) < TH, 'Dominant bins sanity check failed.');
        figure; plot(abs(gFD)); hold on; plot(absDiff,'r');
    end	

    TImagesFD.truePhaseShiftsFD = truePhaseShiftsFD;
    TImagesFD.true_rot_idxs = true_rot_idxs;
    TImagesFD.true_translations = true_translations;
    TImagesFD.true_flips = true_flips;
    TImagesFD.min_t_shift = min_t_shift;
    TImagesFD.max_t_shift = max_t_shift;
    TImagesFD.true_shifts = true_shifts;
        
    %====================================================================
    % feasibility check using basis-vectors dictionary approach
    %====================================================================
    accVectorFD = zeros(nfft, 1);

    for k = 1:npcs

        % the true rot_idx and t_xy:
        r = true_rot_idxs(k);
        txy_true = true_translations{k};
        f = true_flips(k);

        % verify the true translation exists in the txyList (and hence in the basis dictionary)
        MaybeTrueSolInfo = TBasisDictionary('MaybeTrueSolInfo');
        Options_k = MaybeTrueSolInfo{k};
        txyList = TImages.Shapes{k}.PossibleTxyPerRot{f}{r}.txyList ;
        verifyTxyList(txy_true, txyList, challenge_type, txy_winners_threshold, Options_k);

        % take the source image (in freq-domain) and translate it in
        % freq-domain using the needed phaseShift.
        sigFD = TImagesFD.Shapes{k}.Flips{f}.RotatedImagesFD{r};
        
        if(flag_complex_valued_optim)
            sigFD = sigFD.';   
            [phaseShift, ~] = calcImageTranslationPhase(im_dims, txy_true, nfft);
            basisVector = phaseShift.*sigFD;
        else
            %sigFD = sigFD.';   
            Im1 = reshapeTo2D(sigFD, im_dims(1), im_dims(2));
            Im1 = imtranslate(Im1, txy_true , 'FillValues', 0);
            basisVector = reshapeTo1D(Im1);
            basisVector = basisVector.';
        end

        accVectorFD = accVectorFD + basisVector;
    end

    goalVector = TBasisDictionary('goalVector');

    if(flag_complex_valued_optim)
        sigFD2 = real(ifft(accVectorFD));
        goalFD3 = real(ifft(goalVector));
        [refImage] = reshapeTo2D(goalFD3, Nr, Nc);
    else
        sigFD2 = accVectorFD;
        [refImage] = reshapeTo2D(goalVector, Nr, Nc);
    end

    [reconImage] = reshapeTo2D(sigFD2, Nr, Nc);
    diffImage = refImage - reconImage;
    mseCheck = mean(diffImage(:).^2);
    maxAbsDiff = max(abs(diffImage(:)));

    fprintf(['\n--> Sanity Check Completed (MSE =  ', num2str(mseCheck), ', MaxAbsDiff = ', num2str(maxAbsDiff), ').\n']);

    figure; imagesc(reconImage(1:nr,:)); title('Freq Domain sanity check 2.'); colorbar;
        
    if(strcmp(GP.flag_selected_bins_mode,'dominant'))
        gFD = TImagesFD.GoalFD(GP.b_k);
        accFD = accVectorFD(GP.b_k).';
        absDiff = abs(gFD - accFD);
        TH = 1e-9;
        assert(max(absDiff) < TH, 'Dominant bins sanity check failed.');

        figure; plot(abs(gFD)); hold on; plot(absDiff,'r');
    end

    dbg = 1;

end
