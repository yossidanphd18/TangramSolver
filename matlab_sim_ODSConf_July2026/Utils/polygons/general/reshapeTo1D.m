function [Sig1D, Nr, Nc] = reshapeTo1D(Image)

    [Nr, Nc] = size(Image);
    N = Nr*Nc;
    
    Sig1D = reshape(Image.', 1, N);

end

