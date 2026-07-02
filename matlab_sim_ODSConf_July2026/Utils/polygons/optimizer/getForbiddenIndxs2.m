function [forbidden_indxs] = getForbiddenIndxs2(challenge_type, self_TxyInfo, self_idx, txyInfoList, BasisVectors, threshold)

    % self info.
    selfOrientationInfo = self_TxyInfo.tileInfo;
    ks = selfOrientationInfo.tile_id;
    % fs = selfOrientationInfo.flip_id;
    % rs = selfOrientationInfo.rot_idx;
    % txys = self_TxyInfo.t_xy;
    ns = self_idx;

    % Ps_xy = selfOrientationInfo.vertices + txys;
    
    % self_tile = selfOrientationInfo.tile;
    
    N = length(txyInfoList);
    forbidden_indxs = zeros(1,N);
    
    if(~strcmp(challenge_type,'polygons')) 
        error('Need to take care for non-polygonial challenges.');
    end

    pw = 1;
    for n = (ns+1):N
        otherOrientationInfo = txyInfoList{n}.tileInfo;
        %txyo =  txyInfoList{n}.t_xy;
        %Po_xy = otherOrientationInfo.vertices + txyo;

        ko = otherOrientationInfo.tile_id;
        %fo = otherOrientationInfo.flip_id;
        %ro = otherOrientationInfo.rot_idx;        
     
        % forbid only if its other tile!
        if(ko ~= ks)
            % other_tile = otherOrientationInfo.tile;
            vec1 = BasisVectors(:,ns);
            vec2 = BasisVectors(:,n);
            is_intersecting = check_intersection(vec1, vec2, threshold); 
     
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

function [is_intersecting] = check_intersection(vec1, vec2, threshold)
    % CHECK_INTERSECTION Determines if two vectors "intersect" based on a threshold.
    %
    % Inputs:
    %   vec1, vec2 : Nx1 column vectors with values in [0, 1.0]
    %   threshold  : Scalar value for the intersection count comparison
    %
    % Output:
    %   is_intersecting : Logical 1 (true) if count > threshold, else 0 (false)

    % Find indices where both vectors have values >= 1.0
    % Using logical AND (&)
    % intersection_mask = (vec1 >= 1.0) & (vec2 >= 1.0);
    tol = 1e-2;
    intersection_mask = ((vec1 + vec2) > (1.0 + tol));

    % Count the number of cells (K) that meet the condition
    count_intersected = sum(intersection_mask);
    
    % Determine if K is greater than the threshold
    is_intersecting = (count_intersected > threshold);
end

