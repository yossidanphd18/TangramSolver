function [valid_region, is_line] = find_translations_robust(Gx, Gy, Px, Py, boundary_only, inflate_tol)
    G = polyshape(Gx, Gy);
    P = polyshape(Px, Py);
    
    % 1. Buffer G to handle the tolerance
    G_buffered = polybuffer(G, inflate_tol);
    
    % 2. Minkowski Subtraction: Find the Feasible Region (where P is inside G)
    pts = P.Vertices;
    feasible_poly = translate(G_buffered, -pts(1,1), -pts(1,2));
    
    for i = 2:size(pts, 1)
        shifted_G = translate(G_buffered, -pts(i,1), -pts(i,2));
        feasible_poly = intersect(feasible_poly, shifted_G);
    end
    
    % 3. Determine if we return the full area or just the perimeter
    if boundary_only
        % Extract boundary coordinates and re-wrap in a polyshape
        [bx, by] = boundary(feasible_poly);
        valid_region = polyshape(bx, by);
    else
        valid_region = feasible_poly;
    end
    
    % 4. Area check for "is_line" 
    % (Based on the original feasible area before extracting boundary)
    is_line = (area(feasible_poly) < 1e-3) && (feasible_poly.NumRegions > 0);
end
