function [hit_dRow_dCol] = findRelativeHits(tile, TH_edges)

TH_center = 1.6;

if nargin < 2
    TH_edges = 0;
end

    % find hit location relative to center.
    [r1,c1] = find(tile > TH_center);
%     if((length(r1) > 1))
%         dbg = 1;
%     end
%     if((length(r1) == 0))
%         dbg = 1;
%     end
    [I1,J1] = find(tile > TH_edges);
    I2 = I1 - r1;
    J2 = J1 - c1;

    hit_dRow_dCol.center = [r1,c1];
    hit_dRow_dCol.dRow_dCol = [I2,J2]; % relative coordinates
    hit_dRow_dCol.Row_Col = [I1,J1]; % absolute coordinates
end
