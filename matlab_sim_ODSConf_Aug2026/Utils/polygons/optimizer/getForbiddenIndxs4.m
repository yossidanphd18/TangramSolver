function [ForbiddenIndxsList, ForbiddenAreasList] = getForbiddenIndxs4(TileIDs, BasisPolygons, areaMinPercentage)

% Check intersection based on polygon vertices (rather then coveredArea vectors).
% areaMinPercentage - allowed intersection percentage e.g. 0.03 for 3% of the smaller tile from each pair.

    ForbiddenIndxsList = {};
    ForbiddenAreasList = {};
    nvars = length(TileIDs);
    for s = 1:nvars
        forbidden_indxs = zeros(1,nvars);
        forbidden_areas = zeros(1,nvars);
        pw = 1;
        % self and other
        ks = TileIDs(s);
        for o = s+1:nvars
            ko = TileIDs(o);
            if(ko ~= ks)
                P1 = BasisPolygons{s};
                P2 = BasisPolygons{o};
                % is_intersecting = check_intersection(P1, P2, areaMinPercentage); 
                [is_intersecting, intersection_area] = check_intersection_mex_o2(P1, P2, areaMinPercentage); 
                if(is_intersecting)
                    forbidden_indxs(pw) = o;
                    forbidden_areas(pw) = intersection_area;
                    pw = pw + 1;
                end
            end
        end
        ForbiddenIndxsList{s} = forbidden_indxs(1:pw-1);
        ForbiddenAreasList{s} = forbidden_areas(1:pw-1);
    end
    dbg = 1;
end

% function [is_intersecting] = check_intersection(P1, P2, areaMinPercentage)
%     % Quick Bounding Box Check (Axis-Aligned Bounding Box - AABB)
%     minP1 = min(P1, [], 1); maxP1 = max(P1, [], 1);
%     minP2 = min(P2, [], 1); maxP2 = max(P2, [], 1);
% 
%     % If bounding boxes do not overlap, they can NEVER intersect.
%     if maxP1(1) < minP2(1) || minP1(1) > maxP2(1) || ...
%        maxP1(2) < minP2(2) || minP1(2) > maxP2(2)
%         is_intersecting = false;
%         return;
%     end
% 
%     % If bounding boxes DO overlap, proceed with heavy polyshape math
%     poly1 = polyshape(P1(:,1), P1(:,2));
%     poly2 = polyshape(P2(:,1), P2(:,2));
% 
%     area1 = area(poly1);
%     area2 = area(poly2);
%     areaThreshold = areaMinPercentage * min(area1, area2);
% 
%     polyIntersection = intersect(poly1, poly2);
%     overlapArea = area(polyIntersection);
% 
%     is_intersecting = (overlapArea > areaThreshold);
% end

