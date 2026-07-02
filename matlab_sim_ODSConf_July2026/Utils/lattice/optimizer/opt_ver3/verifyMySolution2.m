function [KPIs] = verifyMySolution2(x_sol, GP, TImages, TImagesFD, CountsDB)            

KPIs = [];

% x_sol = gurobi_result.x;
            
flag_complex_valued_optim = GP.flag_complex_valued_optim;
nfft   = GP.nfft;
npcs   = TImages.npcs;
nflips = TImages.nflips;
nrots  = TImages.nrots;

Nr = GP.Nr_w_pad;
Nc = GP.Nc;
im_dims = [Nr, Nc];
Nr2 = GP.Nr_wo_pad;

found_rots_id = [];
found_flips_id = [];
found_txy = {};
pw = 1;
p1 = 1;
TH = 1.0 - 1e-9;

for k = 1:npcs
    
    %rot_idx_options = TImages.Shapes{k}.rot_idx_options; 
    %nrots = length(rot_idx_options);
    found_match = 0;

    for f = 1:nflips
        
        %if(found_match)
        %    continue;
        %end

        Flips = TImages.Shapes{k}.Flips{f};
        if(isempty(Flips)); break; end

        for r = 1:nrots

            PossibleTxyPerRot = TImages.Shapes{k}.PossibleTxyPerRot{f}{r};
            
            if(isempty(PossibleTxyPerRot)); break; end

            txyList = PossibleTxyPerRot.txyList ;
            %rot_idx = rot_idx_options(r);
            nbasis_vecs = CountsDB(k, f, r);
    
            if(strcmp(GP.challenge_type, 'polygons'))
                assert(abs(length(txyList) - nbasis_vecs) <= 1);
            else
                assert(length(txyList) == nbasis_vecs);
            end

            p2 = p1 +  nbasis_vecs - 1;
            ai_vec = x_sol(p1:p2);
            ii1 = find(ai_vec >= TH);
            if(~isempty(ii1))
                assert(length(ii1) == 1);
                found_rots_id(pw) = r;
                found_flips_id(pw) = f;
                found_txy{pw} = txyList{ii1};
                pw = pw + 1;
                assert(found_match == 0, 'Expecting only 1 match per piece!')
                found_match = 1;
            end
            p1 = p2 + 1;
        end

    end

end
assert(length(found_rots_id) == npcs, 'Expecing exactly selected npcs rotations.');
assert(length(found_txy) == npcs, 'Expecing exactly selected npcs translations.');

%====================================================================
% feasibility check using basis-vectors dictionary approach
%====================================================================    
accVectorFD = zeros(nfft, 1);

for k = 1:npcs
    rot_idx = found_rots_id(k);
    txy = found_txy{k};
    flip_id = found_flips_id(k);

    % take the source image (in freq-domain) and translate it in
    % freq-domain using the needed phaseShift.
    if(flag_complex_valued_optim)
        sigFD = TImagesFD.Shapes{k}.Flips{flip_id}.RotatedImagesFD{rot_idx};
        sigFD = sigFD.';        
        [phaseShift, ~] = calcImageTranslationPhase(im_dims, txy, nfft);
        basisVector = phaseShift.*sigFD;
    else
        sigFD = TImagesFD.Shapes{k}.Flips{flip_id}.RotatedImagesFD{rot_idx};
        Im1 = reshapeTo2D(sigFD, Nr, Nc);
        Im1 = imtranslate(Im1, txy , 'FillValues', 0);
        basisVector = reshapeTo1D(Im1);
        basisVector = basisVector.';
    end
    accVectorFD = accVectorFD + basisVector;
end

if(flag_complex_valued_optim)
    sigFD2 = real(ifft(accVectorFD));
    [reconImage] = reshapeTo2D(sigFD2, Nr, Nc);
else
    [reconImage] = reshapeTo2D(accVectorFD, Nr, Nc);
end

solImage = reconImage(1:Nr2,:);
refImage = TImages.Goal.puzzle;
diffImage = abs(refImage-solImage);

if(strcmp(GP.challenge_type,'polygons'))
    TH = 2;
else
    TH = 1e-7;
end

if(GP.flag_show_final_result_figure || 1)
    figure; 
    subplot(2,2,1);
    imagesc(solImage); title('Solver result'); colorbar;
    subplot(2,2,2);
    imagesc(diffImage); title('FD AbsDiff (sol vs. ref)'); colorbar;
end

fprintf('\n****************************************************************');
fprintf('\n**** Optimization results {true_result , our_result}    ********');
fprintf('\n****************************************************************\n\n');

maxAbsDiff = max(diffImage(:));
meanMSE = mean(diffImage(:).^2);

success = 0;

if(maxAbsDiff < TH)
    fprintf(['---> Solver vs Ref maxAbsDiff = ', num2str(maxAbsDiff), ', meanMSE = ', num2str(meanMSE) , '. --> SUCCESS.\n']);
    success = 1;
else
    fprintf(['---> Solver vs Ref maxAbsDiff = ', num2str(maxAbsDiff), ', meanMSE = ', num2str(meanMSE) , '. --> ** FAILED **.\n']);
end

%======================================================================
%======================================================================
% assert(N==npcs);
prod = 1;
for k = 1:npcs
    ncombs = 0;
    for f = 1:nflips
        for r = 1:nrots
            ncombs = ncombs + CountsDB(k,f,r);
            if (ncombs <= 0); ncombs = 1; end            
        end
    end
    prod = prod * ncombs;
end
fprintf('\n********************************************************************');
fprintf('\n Note that this puzzle have %.3e raw combinations (possible translations)', prod);
fprintf('\n********************************************************************\n');

KPIs.ncombinations = prod;
KPIs.maxAbsDiff = maxAbsDiff;
KPIs.success = success;

end % end of function
