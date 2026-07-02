function [found_rots_id, found_flips_id, found_txy] = extract_solution_parameters(x_sol, TImages, CountsDB)
% given a vector x_sol from the Solver, we extract the implied rotations,
% flips, and translations encoded within it.
%
    found_rots_id = [];
    found_flips_id = [];
    found_txy = {};

    npcs   = TImages.npcs;
    nflips = TImages.nflips;
    nrots  = TImages.nrots;

    pw = 1;
    p1 = 1;
    
    ai_thresh = (1.0 - 1e-6); % integer coefficient ai may be 0.999 due to floating point optim.
    
    for k = 1:npcs
        
        found_match = 0;
    
        for f = 1:nflips
            
            %Flips = TImages.Shapes{k}.Flips{f};
            %if(isempty(Flips)); break; end
    
            for r = 1:nrots
    
                PossibleTxyPerRot = TImages.Shapes{k}.PossibleTxyPerRot{f}{r};
     
                if(isempty(PossibleTxyPerRot)); continue; end
                if ~isfield(PossibleTxyPerRot, 'txyList') ; continue; end
    
                nvecs = CountsDB(k, f, r);    
                p2 = p1 +  nvecs - 1;
                
                ai_vec = x_sol(p1:p2);

                ii1 = find(ai_vec >= ai_thresh);
                if(~isempty(ii1))
                    assert(length(ii1) == 1, 'Check1 : Expecting only 1 match per piece!');
                    assert(found_match == 0, 'Check2 : Expecting only 1 match per piece!');
                    found_rots_id(pw) = r;
                    found_flips_id(pw) = f;
                    % This is where we take the non-zero valued index 'ii1' from 'x_sol' which the Solver produced.
                    % And we map this index to 't_xy' the tranlation it represents.
                    found_txy{pw} = PossibleTxyPerRot.txyList{ii1};
                    pw = pw + 1;                
                    found_match = 1;
                end
                p1 = p2 + 1;
            end
    
        end
    
    end
    assert(length(found_rots_id) == npcs, 'Expecing exactly selected npcs rotations.');
    assert(length(found_txy) == npcs, 'Expecing exactly selected npcs translations.');
end