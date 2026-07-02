function [phaseShift, t_shift] = calcImageTranslationPhase(im_dims, t_xy, nfft)
    
% works for pos and neg tx, ty!

    % nr = im_dims(1);
    % nc = im_dims(2);
    
    % assert(nfft >= (nr*nc), 'Unexpected dims - assuming nfft >= M*N !');
    assert(nfft >= prod(im_dims), 'Unexpected dims - assuming nfft >= M*N !');

%     t_x = t_xy(1);
%     t_y = t_xy(2);
%     
%     t_shift = nc*t_y + t_x;
    
    [t_shift] = calcShiftFromTxy(im_dims, t_xy);

    u = 0:nfft-1;

    phaseShift = exp((-j*(2*pi)/nfft)*u*t_shift).';

end