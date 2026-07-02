function [ForbiddenIndxsList] = getForbiddenIndxs3(TileIDs, BasisVectors, threshold)

    ForbiddenIndxsList = {};
    nvars = length(TileIDs);
    
    most_true_solution_keep = [127, 742, 1286, 4913, 5201, 7700, 9811];

    for s = 1:nvars
        forbidden_indxs = zeros(1,nvars);
        pw = 1;
        % self and other
        ks = TileIDs(s);
        for o = s+1:nvars
            ko = TileIDs(o);
            if(ko ~= ks)
                vec1 = BasisVectors(:,s);
                vec2 = BasisVectors(:,o);
                is_intersecting = check_intersection(vec1, vec2, threshold); 
     
                if(is_intersecting)
                    forbidden_indxs(pw) = o;
                    pw = pw + 1;
                end
            end
        end
        if(s == 127)
            dbg = 1;
        end
        ForbiddenIndxsList{s} = forbidden_indxs(1:pw-1);
    end
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

