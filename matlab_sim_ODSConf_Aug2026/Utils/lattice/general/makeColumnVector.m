function u = makeColumnVector(u)

    [nr, nc] = size(u);
    
    if nr == 1
        u = u.';
    end

end