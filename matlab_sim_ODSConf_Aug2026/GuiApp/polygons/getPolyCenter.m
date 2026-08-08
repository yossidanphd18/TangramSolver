function [center] = getPolyCenter(polygon_vertices)
    % Calculates the simple vertex centroid and centers the polygon
    N = size(polygon_vertices, 1);
    center = sum(polygon_vertices, 1) / N;
end 