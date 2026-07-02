function score = ga_vector_fitness(indices, D_groups, goalVector)
    % Sum the vectors corresponding to the chosen indices
    ngroups = length(indices);
    vec_len = size(goalVector, 1);
    acc = zeros(vec_len, 1);
    
    for i = 1:ngroups
        idx = indices(i);
        acc = acc + D_groups{i}(:, idx);
    end
    
    % Objective: Minimize the Euclidean distance to goalVector
    score = norm(acc - goalVector);
end