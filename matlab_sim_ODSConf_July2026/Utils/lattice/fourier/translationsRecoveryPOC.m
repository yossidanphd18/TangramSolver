function [A2, Y2] = translationsRecoveryPOC(TImagesFD, GP)

% this prep is for translations recovery (assuming rotation recovery
% already solved).
	
	error('This function is not supported and not checked for a long time!!');
	
    true_rot_idxs = TImagesFD.true_rot_idxs;
    true_shifts = TImagesFD.true_shifts;
    % true_translations = TImagesFD.true_translations;

    b_k = GP.strongest_bin_k;
    u_k = b_k - 1;
    npcs = GP.npcs;
    nfft = GP.nfft;

    B = npcs;
    Y2 = zeros(2*B, 1);
    A2 = zeros(2*B, 2*B);

    
    
    for k = 1:npcs
        t_shift = true_shifts(k);
        truePhaseShift(k) = exp(-1i*(2*pi/nfft)*u_k*t_shift);
    end

    pw = 1;
    for k = 1:npcs
        
        rot_idx = true_rot_idxs(k);
        sigFD = TImagesFD.Shapes{k}.RotatedImagesFD{rot_idx};
        
        h_k = sigFD(b_k);
        c_v = real(h_k);
        d_v = imag(h_k);
        H1 = [c_v -d_v; d_v c_v];

        y_k = h_k * truePhaseShift(k);
        
        A2(pw:pw+1,pw:pw+1) = H1;
        
        Y2(pw:pw+1) = [real(y_k); imag(y_k)];
        
        pw = pw + 2;
    end

    xx_inv =  A2 \ Y2;

    xx_theory = zeros(size(xx_inv));
    xx_theory(1:2:end) = real(truePhaseShift);
    xx_theory(2:2:end) = imag(truePhaseShift);
    
    TH = 1e-12;
    check1 = max(abs(xx_inv-xx_theory));
    assert(check1 < TH, 'translation recovery POC failed on abs diff magnitude.');


    dbg = 1;
end