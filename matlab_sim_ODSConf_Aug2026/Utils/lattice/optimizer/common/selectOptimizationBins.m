function [u_k, b_k] = selectOptimizationBins(nfft, GP, goalFD)
     
    is_odd = (mod(nfft,2) == 1);
    
    if(~GP.clip2roi)
        assert(is_odd, 'nfft expected to be odd!');
    end

    flag_selected_bins_mode = GP.flag_selected_bins_mode;    
    %flag_transform_type = GP.flag_transform_type;
    %flag_complex_valued_optim = GP.flag_complex_valued_optim;


    if(strcmp(flag_selected_bins_mode, 'all'))
        p1 = 1;
        p2 = p1 + nfft - 1;
        b_k = p1:p2;
    elseif(strcmp(flag_selected_bins_mode, 'dominant'))
        if(is_odd)
          p1 = 1;
          p2 = 0.5*(nfft+1);        
        else
          p1 = 1;
          p2 = 1 + 0.5*nfft;
        end

        absGoalFD = abs(goalFD);
        highest = max(absGoalFD);
        binmask1 = (absGoalFD >= GP.flag_dominant_thresh * highest);
        idx1     = binmask1(1:p2);
        idxs = find(idx1 ~= 0);
        b_k = idxs;

        if(0)
            figure; plot(absGoalFD);
            absGoalFD2 = absGoalFD;
            binmask2 = zeros(size(binmask1));
            binmask2(b_k) = 1;
            absGoalFD2(binmask2==0) = 0;
            hold on; stem(abs(absGoalFD2),'r');
            dbg = 1;
        end

    elseif(strcmp(flag_selected_bins_mode, 'half'))
        if(is_odd)
          p1 = 1;
          p2 = 0.5*(nfft+1);        
        else
          p1 = 1;
          p2 = 1 + 0.5*nfft;
        end
        b_k = p1:p2;
    else
        error('Invalid argument value for flag_selected_bins_mode! (only {half, dominant, all} allowed).');
    end

    
    u_k = b_k - 1;
    
    u_k = makeColumnVector(u_k);
    b_k = makeColumnVector(b_k);        
end

