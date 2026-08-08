function [KPIs, x_my_sol] = checkIfFeasibleSol(GP, TBasisDictionary, x_my_sol, flag_complex_valued_optim)            

if(nargin < 4)
    flag_complex_valued_optim = 0;
end

if nargin < 3
    x_my_sol = [];
end

BasisVectors = TBasisDictionary('BasisVectors');
npcs = GP.npcs;

if(isempty(x_my_sol))
    most_true_solution_idxs = TBasisDictionary('most_true_solution_idxs');
    % npcs   = length(most_true_solution_idxs);
    
    [~, nbasis_vectors] = size(BasisVectors);
    len_qZ_block =  (GP.vdim + 1) ;
    x_my_sol = zeros(len_qZ_block + nbasis_vectors, 1);
    
    for kt = 1:npcs
        var_index = most_true_solution_idxs(kt);
        x_my_sol(var_index) = 1;
    end
else
    most_true_solution_idxs = find(x_my_sol ~= 0);
    most_true_solution_idxs = most_true_solution_idxs(1:npcs);
end

goalVector = TBasisDictionary('goalVector');
vec_dim = length(goalVector);
% vec_dim = GP.vdim; % vectors dimension

rows_BB = GP.rows_BB;
cols_BB = GP.cols_BB;
r1 = rows_BB(1);
r2 = rows_BB(2);
c1 = cols_BB(1); 
c2 = cols_BB(2);

Nr = r2-r1+1;
Nc = c2-c1+1;
Nr2 = Nr;

clear r1 r2 c1 c2

% flag_complex_valued_optim = GP.flag_complex_valued_optim;
% nfft   = GP.nfft;
% Nr = GP.Nr_w_pad;
% Nc = GP.Nc;
% Nr2 = GP.Nr_wo_pad;


%====================================================================
% feasibility check using basis-vectors dictionary approach
%====================================================================    
accVectorFD = zeros(vec_dim, 1);

for k = 1:npcs
    var_idx = most_true_solution_idxs(k);
    basisVector = BasisVectors(:,var_idx);
    accVectorFD = accVectorFD + basisVector;
end

if(flag_complex_valued_optim)
    sigFD2 = real(ifft(accVectorFD));
    [reconImage] = reshapeTo2D(sigFD2, Nr, Nc);

    goalFD2 = real(ifft(goalVector));
    [refImage] = reshapeTo2D(goalFD2, Nr, Nc);
else
    [reconImage] = reshapeTo2D(accVectorFD, Nr, Nc);
    [refImage] = reshapeTo2D(goalVector, Nr, Nc);
end

solImage = reconImage(1:Nr2,:);
% refImage = TImages.Goal.puzzle;
diffImage = abs(refImage-solImage);
maxAbsDiff = max(diffImage(:));
mseCheck = mean(diffImage(:).^2);

if(GP.flag_show_final_result_figure || 1)
    figure; 
    subplot(2,2,1);
    imagesc(refImage); title('Ref'); colorbar;
    subplot(2,2,2);
    imagesc(solImage); title('Solver result'); colorbar;
    subplot(2,2,3);
    imagesc(diffImage); title('FD AbsDiff (sol vs. ref)'); colorbar;
end

fprintf('\n****************************************************************');
fprintf('\n**** Optimization results {true_result , our_result}    ********');
fprintf('\n****************************************************************\n\n');

if(strcmp(GP.challenge_type,'polygons'))
    TH = 2;
else
    TH = 1e-7;
end

success = 0;

if(maxAbsDiff < TH)
    fprintf(['---> Solver vs Ref maxAbsDiff = ', num2str(maxAbsDiff), ', mseCheck = ', num2str(mseCheck), '. --> SUCCESS.\n']);
    success = 1;
else
    fprintf(['---> Solver vs Ref maxAbsDiff = ', num2str(maxAbsDiff), ', mseCheck = ', num2str(mseCheck), '. --> ** FAILED **.\n']);
end

KPIs = [];
KPIs.maxAbsDiff = maxAbsDiff;
KPIs.success = success;

end % end of function
