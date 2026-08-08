function verifyMySolution(x_sol, GP, TImages, TImagesFD, CountsDB)            

% x_sol = gurobi_result.x;
            
p1 = 1;
TH = 1.0 - 1e-9;

if(GP.flag_use_true_rots)
    
    for k = 1:GP.npcs

        rot_idx_true = TImagesFD.true_rot_idxs(k);
        txy_true = TImagesFD.true_translations{k};
        
        txyList = TImages.Shapes{k}.PossibleTxyPerRot{rot_idx_true}.txyList ;
    
        nbasis_vecs = CountsDB(k, rot_idx_true);

        p2 = p1 +  nbasis_vecs - 1;
        ai_vec = x_sol(p1:p2);
        ii1 = find(ai_vec >= TH);
        txy = txyList{ii1};
        
        p1 = p2 + 1;

        msg = ['\n---> Piece ', num2str(k), ': rot index = {', num2str(rot_idx_true), ', ', num2str(rot_idx_true),'}. Txy = { [', num2str(txy_true(1)), ',' , num2str(txy_true(2)), ']' , ', ',  '[', num2str(txy(1)), ',' , num2str(txy(2)), ']',  '}\n'];
        fprintf(msg);
        dbg = 1;

    end
    
else

    found_rots_id = [];
    found_txy = {};
    pw = 1;
    for k = 1:GP.npcs
        for r = 1:GP.nrots
            txyList = TImages.Shapes{k}.PossibleTxyPerRot{r}.txyList ;
            nbasis_vecs = CountsDB(k,r);
            assert(length(txyList) == nbasis_vecs);
            
            p2 = p1 +  nbasis_vecs - 1;
            ai_vec = x_sol(p1:p2);
            ii1 = find(ai_vec >= TH);
            if(~isempty(ii1))
                assert(length(ii1) == 1);
                found_rots_id(pw) = r;
                found_txy{pw} = txyList{ii1};
                pw = pw + 1;
            end
            p1 = p2 + 1;
        end
    end

    fprintf('\n****************************************************************');
    fprintf('\n**** Optimization results {true_result , our_result}    ********');
    fprintf('\n**** Checkers {txy, rot} > 0 means SUCCESS              ********');
    fprintf('\n****************************************************************\n');

    total_checkers = 1;

    for k = 1:GP.npcs

        rot_idx_true = TImagesFD.true_rot_idxs(k);
        txy_true     = TImagesFD.true_translations{k};
        rot_idx_sym  = TImages.true_rot_idxs_with_symetry{k};

        txy_ = found_txy{k};
        rot_idx_ = found_rots_id(k);

        % verify translation match the true one        
        if (sum(txy_true - txy_) == 0) 
            txy_pass = 1; 
        else
            txy_pass = 0;
        end

        % verify rotation match the true one (or symmetric to it).
        if ((rot_idx_true - rot_idx_) == 0) 
            rot_pass = 1;
        else 
            check_sym = any(rot_idx_sym(:) == rot_idx_true) && any(rot_idx_sym(:) == rot_idx_);
            if(check_sym)
                rot_pass = 2; % passed with symmetric rotation
            else
                rot_pass = 0; 
            end
        end
        
        if((rot_pass == 0) || (txy_pass == 0))
            total_checkers = 0;
        end

        msg_checks = [' checkersTxyRot = {', num2str(txy_pass), ', ', num2str(rot_pass),'}.'];

        msg = ['\n---> Piece ', num2str(k), ': rot index = {', num2str(rot_idx_true), ', ', num2str(rot_idx_),'}, Txy = {[', num2str(txy_true(1)), ',' , num2str(txy_true(2)), ']' , ', ',  '[', num2str(txy_(1)), ',' , num2str(txy_(2)), ']',  '},', msg_checks, '\n'];
        
        fprintf(msg);
        dbg = 1;

    end
    
    if(total_checkers > 0)
        fprintf(['\n---> TOTAL CHECKERS PASSED. \n']);
    else
        fprintf(['\n---> TOTAL CHECKERS **FAILED**. \n']);
    end

end % end of if-else

%======================================================================
%======================================================================
N = length(CountsDB);
assert(N==GP.npcs);
prod = 1;
for k = 1:N
    ncombs = sum(CountsDB(k,:)) - k + 1; % after placing the k-th piece we lose k places.
    prod = prod * ncombs;
end
% msg = ['\n**** npcs = ', num2str(N), ', i.e. for this puzzle it means ', num2str(prod), ' combinations!'];
fprintf('\n********************************************************************');
fprintf('\n Wow - note that %d puzzle pieces lead to %.3e combinations!', N, prod);
fprintf('\n********************************************************************\n');

end % end of function
