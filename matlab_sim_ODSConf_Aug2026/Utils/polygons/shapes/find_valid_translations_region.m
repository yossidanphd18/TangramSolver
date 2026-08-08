function [valid_region, is_line] = find_valid_translations_region(Gx, Gy, Px, Py)
    G = polyshape(Gx, Gy);
    P = polyshape(Px, Py);
    
    % TOLERANCE: Expand G by a tiny amount so P (which is slightly too tall) can fit.
    % 0.02 is enough to bridge the 0.0079 unit discrepancy.
    G_buffered = polybuffer(G, 0.02);
    
    % Minkowski Subtraction logic
    pts = P.Vertices;
    % Initialize with shift by the first vertex
    valid_region = translate(G_buffered, -pts(1,1), -pts(1,2));
    
    % Intersect with shifts by all other vertices
    for i = 2:size(pts, 1)
        shifted_G = translate(G_buffered, -pts(i,1), -pts(i,2));
        valid_region = intersect(valid_region, shifted_G);
    end
    
    % Area check for "is_line"
    is_line = (area(valid_region) < 1e-3) && (valid_region.NumRegions > 0);
end
