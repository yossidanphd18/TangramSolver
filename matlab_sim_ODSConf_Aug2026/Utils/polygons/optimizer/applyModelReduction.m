function [GP, TBasisDictionary] = applyModelReduction(GP, TBasisDictionary)

    if(GP.apply_dim_reduction <= 0)
        fprintf('---> Model reduction is Disabled...\n');
        return;
    else
        assert(GP.reduced_dim > 50, 'Minimum vectors length is not sufficient!');
    end
    
    fprintf('---> Applying Model Reduction...\n');
    
    D = TBasisDictionary('BasisVectorsDB').BasisVectors;
    G = TBasisDictionary('goalVector').';
    my_feasible_sol = TBasisDictionary('my_feasible_sol');

    [K, N] = size(D);

    if(0)
        feasible_mask = all(D <= G, 1);
        D1 = D(:, feasible_mask);
        original_map = find(feasible_mask); % To map back to original indices later
    
        fprintf('--> Pruning: Removed %d impossible vectors.\n', N - size(D1, 2));
    else
        D1 = D;
    end

    %% 2. QR Decomposition (Constraint Reduction)
    % Removes redundant or linearly dependent constraints (rows).
    [Q, R] = qr(D1, 0); 
    
    % Identify the numerical rank
    tol = max(size(D1)) * eps(norm(D1, 'inf'));
    rank_eff = sum(abs(diag(R)) > tol);
    
    % Project into the reduced row-space
    D2 = R(1:rank_eff, :);
    G2 = Q' * G;
    G2 = G2(1:rank_eff);
    K2 = rank_eff;

    fprintf('--> QR Reduction: Constraints reduced from %d to %d.\n', K, K2);

    
    % 3. Remove floating point issues, and update new problem dimensions.
    scale_factor = 1e5;
    D2 = round(D2 * scale_factor);
    G2 = round(G2 * scale_factor);
    % evaluate the noise norm in the transformed domain.
    x1 = zeros(size(D2,2),1);
    x1(my_feasible_sol) = 1;
    E = D2*x1 - G2;
    
    minZ2 = min(E(:));
    maxZ2 = max(E(:));
    maxZ2 = max(abs([minZ2, maxZ2]));

    GP.MAX_Zi = maxZ2;
    GP.vdim = K2;
    GP.MIN_q = 0;
    GP.MAX_q = 1.3 * K2 * maxZ2 ^ 2; 
    TBasisDictionary('BasisVectorsDB').BasisVectors = D2;
    TBasisDictionary('goalVector') = G2;
    
end
