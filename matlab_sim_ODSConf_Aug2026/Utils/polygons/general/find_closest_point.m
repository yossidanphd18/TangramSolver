function [closest_point, min_dist, index] = find_closest_point(p, A)

diff = A-p;
distances = vecnorm(diff,2,2);
[min_dist, index] = min(distances);
closest_point = A(index,:);

end