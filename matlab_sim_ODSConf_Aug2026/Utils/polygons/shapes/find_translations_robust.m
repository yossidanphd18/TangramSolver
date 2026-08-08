function [valid_region, is_line] = find_translations_robust(Gx, Gy, Px, Py, boundary_only, inflate_tol)
    G = polyshape(Gx, Gy);
    P = polyshape(Px, Py);
    
    % Buffer G for the tolerance
    G_buffered = polybuffer(G, inflate_tol);
    
    % Get the "Bounding Box" of possible translations
    % We don't need to check the whole world, just where P overlaps G.
    [Gx_min, Gx_max, Gy_min, Gy_max] = deal(min(Gx), max(Gx), min(Gy), max(Gy));
    [Px_min, Px_max, Py_min, Py_max] = deal(min(Px), max(Px), min(Py), max(Py));
        
    pts = P.Vertices;
    % Initial guess using vertex-only intersection (your original method)
    valid_region = translate(G_buffered, -pts(1,1), -pts(1,2));
    for i = 2:size(pts, 1)
        shifted_G = translate(G_buffered, -pts(i,1), -pts(i,2));
        valid_region = intersect(valid_region, shifted_G);
    end
 
    is_line = (area(valid_region) < 1e-3) && (valid_region.NumRegions > 0);

    dbg = 1;
end