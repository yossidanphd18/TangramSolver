%% Optimized Sparse Subset Sum Solver
% Dimensions: D (K x N), G (K x 1), x (N x 1 binary)
% Problem: Minimize sum(x) subject to D*x = G

clear; clc; close all

%% 0. Setup Dummy Data
K = 80;    % Dimensionality
N = 1500;  % Dictionary size
D_raw = randi([0, 10], K, N);
true_indices = randperm(N, 12);
G_raw = sum(D_raw(:, true_indices), 2);

fprintf('Starting Optimization Pipeline...\n');
fprintf('Original Dimensions: %d constraints, %d variables\n', K, N);

%% 1. Pruning (Variable Reduction)
% Valid if D and G are non-negative. Removes vectors that cannot fit in the sum.
feasible_mask = all(D_raw <= G_raw, 1);
D_pruned = D_raw(:, feasible_mask);
original_map = find(feasible_mask); % To map back to original indices later

fprintf('1. Pruning: Removed %d impossible vectors.\n', N - size(D_pruned, 2));

%% 2. QR Decomposition (Constraint Reduction)
% Removes redundant or linearly dependent constraints (rows).
[Q, R] = qr(D_pruned, 0); 

% Identify the numerical rank
tol = max(size(D_pruned)) * eps(norm(D_pruned, 'inf'));
rank_eff = sum(abs(diag(R)) > tol);

% Project into the reduced row-space
D_reduced = R(1:rank_eff, :);
G_reduced = Q' * G_raw;
G_reduced = G_reduced(1:rank_eff);

fprintf('2. QR Reduction: Constraints reduced from %d to %d.\n', K, rank_eff);

%% 3. Symmetry Breaking (Duplicate Vector Handling)
% Groups identical columns to prevent Gurobi from exploring redundant permutations.
[D_unique, ~, ic] = unique(D_reduced', 'rows');
D_unique = D_unique'; % Transpose back to (Rank x N_unique)
max_usage = accumarray(ic, 1); 

fprintf('3. Symmetry: Grouped identical vectors. Unique vectors: %d\n', size(D_unique, 2));

%% 4. Row Scaling (Numerical Stability)
% Scales each constraint so the maximum coefficient is 1.0.
row_max = max(abs(D_unique), [], 2);
row_max(row_max == 0) = 1; % Prevent division by zero

D_final = D_unique ./ row_max;
G_final = G_reduced ./ row_max;

fprintf('4. Scaling: Matrix coefficients normalized to [0, 1].\n');

%% 5. Gurobi Optimization
model.A = sparse(D_final);
model.rhs = G_final;
model.sense = repmat('=', size(D_final, 1), 1);
model.obj = ones(size(D_final, 2), 1); % Minimize number of vectors used
model.modelsense = 'min';

% Variable types: Binary if unique, Integer if duplicates exist
vtypes = repmat('B', size(D_final, 2), 1);
vtypes(max_usage > 1) = 'I';
model.vtype = vtypes;
model.ub = max_usage;

% Solver Parameters for speed
params.Presolve = 2;       % Aggressive presolve
params.MIPFocus = 1;       % Focus on finding feasible solutions quickly
params.TimeLimit = 60;     % Stop after 60 seconds

% Solve
result = gurobi(model, params);

%% 6. Post-Processing: Retrieve Indices
if strcmp(result.status, 'OPTIMAL') || strcmp(result.status, 'SUBOPTIMAL')
    % result.x tells us how many of each 'unique' vector we used
    chosen_unique_idx = find(result.x > 0.5);
    
    fprintf('\nSolution Found!\n');
    fprintf('Number of vectors used: %d\n', sum(result.x));
else
    fprintf('No solution found. Status: %s\n', result.status);
end