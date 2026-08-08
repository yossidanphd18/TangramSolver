function [TImagesFD, GP] = prepareFreqDomainData(TImages, GP)

    TImagesFD = [];
    
    nfft           = GP.nfft;
    transform_type = GP.flag_transform_type;

    npcs   = TImages.npcs;
    nflips = TImages.nflips;
    nrots  = TImages.nrots;

    pixel_value = GP.pixel_values(1);

    % initialize so we have all {tile}{flip}{rot} tuples
    for k = 1:npcs
        for f = 1:nflips
            for r = 1:nrots
                TImagesFD.Shapes{k}.Flips{f}.RotatedImagesFD{r} = {};
            end   
        end    
    end

    for p = 1:npcs
        for f = 1:nflips
            Flips = TImages.Shapes{p}.Flips{f};            
            if(isempty(Flips)); break; end
            for r = 1:nrots
                ImInfo = Flips.RotatedImages{r};
                if(isempty(ImInfo)); break; end
                Im = ImInfo.rotImage;
                assert(max(Im(:)) == pixel_value,'Tile value verfifcation failed!');
                [signal_1D] = reshapeTo1D(Im) ;         
                signalFFT = calcDft1D_FD(signal_1D, nfft, transform_type);
                TImagesFD.Shapes{p}.Flips{f}.RotatedImagesFD{r} = signalFFT ;
            end
        end
    end
    
    Im = TImages.Goal.puzzle;

    if(GP.clip2roi)
        [rows, cols] = find(Im);
        % Find the boundaries
        r1 = min(rows);
        r2  = max(rows);
        c1 = min(cols);
        c2  = max(cols);

        Im = Im(r1-1:r2+1, c1-1:c2+1);
        nfft = length(Im(:));

        GP.Nr_w_pad = size(Im,1);
        GP.Nc = size(Im,2);
        GP.nfft = nfft;
    end

    assert(max(Im(:)) == pixel_value,'Goal tile value verfifcation failed!');
    [signal_1D] = reshapeTo1D(Im) ;         
    signalFFT = calcDft1D_FD(signal_1D, nfft, transform_type);
    TImagesFD.GoalFD = signalFFT ;

    
    % select the bins to be used in optimization.
    [u_k, b_k] = selectOptimizationBins(nfft, GP, TImagesFD.GoalFD);
    GP.u_k = u_k; % u_k bins indexing 0,1,2,3 
    GP.b_k = b_k; % b_k bins indexing 1,2,3,...

    % vectors dmension (complex for dft so 2*B).
    B = length(b_k);
    if(strcmp(GP.flag_transform_type,'dft'))
        GP.nbins = B;
        GP.vdim  = 2*B;
    else
        GP.vdim  = B;
    end

end
