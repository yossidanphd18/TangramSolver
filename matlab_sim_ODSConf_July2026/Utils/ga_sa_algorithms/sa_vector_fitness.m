function score = sa_vector_fitness(x, D_groups, G)
    % x: continuous vector provided by SA
    % D_groups: cell array of dictionaries
    % G: goal vector
    
    t = length(x);
    K = size(G, 1);
    R = zeros(K, 1);
    
    % Round x to the nearest integer to select dictionary indices
    indices = round(x);
    
    for i = 1:t
        idx = indices(i);
        
        % Safety check: ensure rounding doesn't exceed bounds
        idx = max(1, min(idx, size(D_groups{i}, 2)));
        
        R = R + D_groups{i}(:, idx);
    end
    
    % Minimize the norm
    score = norm(R - G);
end