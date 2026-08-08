function [forbidden_indxs] = getForbiddenIndxs2(challenge_type, self_TxyInfo, self_idx, txyInfoList, maybe_true_solution_idxs)

    pw = 1;
    
    % self info.
    selfOrientationInfo = self_TxyInfo.tileInfo;

    ks = selfOrientationInfo.tile_id;
    fs = selfOrientationInfo.flip_id;
    rs = selfOrientationInfo.rot_idx;
    txys = self_TxyInfo.t_xy;
    ns = self_idx;
    
    self_tile = selfOrientationInfo.tile;
    % already done before
    % self_tile = min(self_tile, 1); % remove the center marker
    % ones_tile = ones(size(self_tile));
    
    N = length(txyInfoList);
    forbidden_indxs = zeros(1,N);
    
    collision_TH = 0.5 + 1e-1;

    for n = (ns+1):N
        otherOrientationInfo = txyInfoList{n}.tileInfo;
        txyo =  txyInfoList{n}.t_xy;
        ko = otherOrientationInfo.tile_id;
        %fo = otherOrientationInfo.flip_id;
        %ro = otherOrientationInfo.rot_idx;        
     
        % forbid only if its other tile!
        if(ko ~= ks)
            if(strcmp(challenge_type,'polygons'))                
                other_tile = otherOrientationInfo.tile;
                % already done before
                % other_tile = min(other_tile, 1); % remove the center marker

                [Is,Js] = find(self_tile > collision_TH);
                self_Row_Col = [Is,Js];
                
                % drow is dy, dcol is dx
                self_Row_Col(:,1) = self_Row_Col(:,1) + txys(2);
                self_Row_Col(:,2) = self_Row_Col(:,2) + txys(1);
                
                kprime1 = 7; kprime2 = 9;
                                    
                hash1 = (kprime1.^self_Row_Col(:,1)).* (kprime2.^self_Row_Col(:,2));
                
                [Io,Jo]  = find(other_tile > collision_TH);
                other_Row_Col = [Io,Jo];
                
                % drow is dy, dcol is dx
                other_Row_Col(:,1) = other_Row_Col(:,1) + txyo(2);
                other_Row_Col(:,2) = other_Row_Col(:,2) + txyo(1);
                
                hash2 = (kprime1.^other_Row_Col(:,1)).* (kprime2.^other_Row_Col(:,2));
                
                [is_in, ~] = ismember(hash1, hash2);
                
                has_collision = any(is_in);

                % Don't forbid between possible options, it will make the problem infeasible!!
                %
                if(ismember(ns,maybe_true_solution_idxs) && ismember(n,maybe_true_solution_idxs) && has_collision)
                    % figure; imagesc(imtranslate(self_tile, txys, 'FillValues', 0) + imtranslate(other_tile, txyo, 'FillValues', 0));colorbar;
                    % has_collision2 = check_intersection(self_tile, other_tile, txys, txyo)
                    % warning('Unexpected Forbidden Indexes - Solver will Fail!!!');
                    has_collision = 0;
                else
                    dbg = 1;
                end                


                % has_collision = sum(any(is_in),2);
                % has_collision = (max(has_collision) >= 2);

                % Don't forbid maybe true indexes.
                % has_collision = (has_collision && ~ismember(n, maybe_true_solution_idxs));
                % 
                % if(has_collision && (ks == 1 && ko==2))
                %     % figure(9346); imagesc(imtranslate(self_tile,txys) + imtranslate(other_tile,txyo));title('Collision !');
                %     dbg = 1;
                % else
                %     % figure(9347); imagesc(imtranslate(self_tile,txys) + imtranslate(other_tile,txyo));title('No Collision');
                %     dbg = 1;
                % end

                if(has_collision)
                    forbidden_indxs(pw) = n;
                    pw = pw + 1;
                end
            else
                self_dRow_dCol = selfOrientationInfo.hit_dRow_dCol.dRow_dCol;
                % drow is dy, dcol is dx
                self_dRow_dCol(:,1) = self_dRow_dCol(:,1) + txys(2);
                self_dRow_dCol(:,2) = self_dRow_dCol(:,2) + txys(1);

                other_dRow_dCol = otherOrientationInfo.hit_dRow_dCol.dRow_dCol;
                % drow is dy, dcol is dx
                other_dRow_dCol(:,1) = other_dRow_dCol(:,1) + txyo(2);
                other_dRow_dCol(:,2) = other_dRow_dCol(:,2) + txyo(1);

                % check intersection post translation
                checker = sum(abs(self_dRow_dCol-other_dRow_dCol), 2);
                if(any(checker==0))
                    forbidden_indxs(pw) = n;
                    pw = pw + 1;
                end
            end
        end

    end

    % remove irrelevant elements.
    forbidden_indxs = forbidden_indxs(1:pw-1);
    dbg = 1;

end


function [has_collision] = check_intersection(I1, I2, txy_1, txy_2)    
    [R1, C1] = find(I1);
    [R2, C2] = find(I2);
    
    if isempty(R1) || isempty(R2)
        has_collision = false;
        return;
    end
        
    % BB1 Bounds
    R1_min = min(R1); R1_max = max(R1);
    C1_min = min(C1); C1_max = max(C1);
    
    % BB2 Bounds
    R2_min = min(R2); R2_max = max(R2);
    C2_min = min(C2); C2_max = max(C2);
    
    Cmin = min([C1_min, C2_min]) - 1;
    Cmax = max([C1_max, C2_max]) + 1;
    Rmin = min([R1_min, R2_min]) - 1;
    Rmax = max([R1_max, R2_max]) + 1;

    I1 = I1(Rmin:Rmax,Cmin:Cmax);
    I2 = I2(Rmin:Rmax,Cmin:Cmax);

    together_image = imtranslate(I1, txy_1, 'FillValues', 0) + imtranslate(I2, txy_2, 'FillValues', 0);
    check_max = max(together_image(:));
    has_collision = (check_max > 1.0+1e-4);

end % End of function