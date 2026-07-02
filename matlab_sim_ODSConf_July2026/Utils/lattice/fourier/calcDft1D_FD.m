function [inpFD] = calcDft1D_FD(s, nfft, transform_type)
    
if(strcmp(transform_type,'dft'))
    inpFD = fft(s, nfft);
elseif(strcmp(transform_type,'none'))
    inpFD = s;
%elseif(strcmp(transform_type,'dct'))
%    inpFD = dct(s, nfft);    
else
    error('Invalid transform_type argument!');
end
