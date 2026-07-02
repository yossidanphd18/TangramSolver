function [forbidden_indxs] = getForbiddenIndxs(challenge_type, self_TxyInfo, self_idx, txyInfoList)

    pw = 1;
    
    % self info.
    selfOrientationInfo = self_TxyInfo.tileInfo;
    ks = selfOrientationInfo.tile_id;
    % fs = selfOrientationInfo.flip_id;
    % rs = selfOrientationInfo.rot_idx;
    txys = self_TxyInfo.t_xy;
    ns = self_idx;

    Ps_xy = selfOrientationInfo.vertices + txys;
    
    % self_tile = selfOrientationInfo.tile;
    
    N = length(txyInfoList);
    forbidden_indxs = zeros(1,N);
    
    if(~strcmp(challenge_type,'polygons')) 
        error('Need to take care for non-polygonial challenges.');
    end

    for n = (ns+1):N
        otherOrientationInfo = txyInfoList{n}.tileInfo;
        txyo =  txyInfoList{n}.t_xy;
        Po_xy = otherOrientationInfo.vertices + txyo;

        ko = otherOrientationInfo.tile_id;
        %fo = otherOrientationInfo.flip_id;
        %ro = otherOrientationInfo.rot_idx;        
     
        % forbid only if its other tile!
        if(ko ~= ks)
            % other_tile = otherOrientationInfo.tile;
    
            is_intersecting = check_intersection(Ps_xy, Po_xy); 
     
            if(is_intersecting)
                forbidden_indxs(pw) = n;
                pw = pw + 1;
            end
        end

    end

    % remove irrelevant elements.
    forbidden_indxs = forbidden_indxs(1:pw-1);
    dbg = 1;

end

function [is_intersecting] = check_intersection(Pxy, Gxy)
    polyP = polyshape(Pxy(:,1), Pxy(:,2));
    polyG = polyshape(Gxy(:,1), Gxy(:,2));

    % overlaps() is highly optimized for boolean intersection checks
    is_intersecting = overlaps(polyP, polyG);
end

% function [has_collision] = check_intersection(I1, I2, txy_1, txy_2)    
%     [R1, C1] = find(I1);
%     [R2, C2] = find(I2);
% 
%     if isempty(R1) || isempty(R2)
%         has_collision = false;
%         return;
%     end
% 
%     % BB1 Bounds
%     R1_min = min(R1); R1_max = max(R1);
%     C1_min = min(C1); C1_max = max(C1);
% 
%     % BB2 Bounds
%     R2_min = min(R2); R2_max = max(R2);
%     C2_min = min(C2); C2_max = max(C2);
% 
%     Cmin = min([C1_min, C2_min]) - 1;
%     Cmax = max([C1_max, C2_max]) + 1;
%     Rmin = min([R1_min, R2_min]) - 1;
%     Rmax = max([R1_max, R2_max]) + 1;
% 
%     I1 = I1(Rmin:Rmax,Cmin:Cmax);
%     I2 = I2(Rmin:Rmax,Cmin:Cmax);
% 
%     together_image = imtranslate(I1, txy_1, 'FillValues', 0) + imtranslate(I2, txy_2, 'FillValues', 0);
%     check_max = max(together_image(:));
%     has_collision = (check_max > 1.0+1e-4);
% 
% end % End of function