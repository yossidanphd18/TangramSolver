function [Image] = reshapeTo2D(Sig1D, Nr, Nc)

    Nr2 = floor(length(Sig1D)/Nc);
    
    N3 = Nr2*Nc;
    
    TH = 1e-10;

    Sig1Dcut = Sig1D(1:N3).';
    Sig1Dtail = Sig1D(N3+1:end).';
    if(~isempty(Sig1Dtail))
        max_abs = max(abs(Sig1Dtail)) ;
        assert(max_abs <= TH, 'Assuming tail is almost all zeros!')
    end
    Image = reshape(Sig1Dcut, Nc, Nr2).';

end



