function expectation = custom_discrete_mutation(parents, options, nvars, FitnessFcn, state, thisScore, thisPopulation, group_sizes, m_prob)
    % Custom mutation to ensure indices stay within group-specific ranges
    % parents: Indices of parents chosen for mutation
    % group_sizes: The array [N1, N2, ... Nt]
    
    %mutationRate = 0.1; % Probability of a gene mutating
    mutationRate = m_prob;
    expectation = thisPopulation(parents, :); % Start with parent copies
    
    for i = 1:length(parents)
        for j = 1:nvars
            if rand < mutationRate
                % Pick a random integer between 1 and the size of Group J
                expectation(i, j) = randi([1, group_sizes(j)]);
            end
        end
    end
end