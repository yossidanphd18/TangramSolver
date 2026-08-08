function verifyTxyList(txy_true, txyList, challenge_type, txy_winners_threshold, Options_k)

    % verify that the true txy found in the txyList (once or approx once).
    N = length(txyList);
    
    count = 0;
    
    % For polygons, the true translation is fractional so exact match is not a must.
    if(strcmp(challenge_type,'polygons'))
        txy_true = round(txy_true);

        NormTH = 0;                
        count2 = 0;
        for t = 1:length(Options_k)
            TxyInfo = Options_k{t}.TxyInfo;
            t_xy = TxyInfo.t_xy;
            check_norm2 = norm(txy_true-t_xy);
            if(check_norm2 <= NormTH)
                count2 = count2 + 1;
            end
        end
        assert(count2 > 0, 'true txy does not found in candidators.');
        
        for n = 1:N
            check_norm = norm(txy_true-txyList{n});
            if(check_norm <= NormTH)
                count = count + 1;
            end
        end
%         if(count >= txy_winners_threshold || count == 0)
%             dbg = 1;
%         end
        assert(((count <= txy_winners_threshold + 6) && (count > 0)), 'true txy does not found or found too many in the txyList!');
    else
        
        for n = 1:N
            check_diff = sum(abs(txy_true-txyList{n}));
            if(check_diff == 0)
                count = count + 1;
            end
        end
        
        assert(count == 1, 'true txy does not found exactly 1 time in the txyList!');
    end
end