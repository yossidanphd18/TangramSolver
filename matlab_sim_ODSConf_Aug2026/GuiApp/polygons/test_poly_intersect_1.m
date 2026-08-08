clc; clear; close all;

% Square P
Px = [0 2 2 0]; Py = [0 0 2 2];
% Triangle G (shifting it to test)
Gx = [1 3 2]; Gy = [1 1 3];

Pxy = [Px;Py].';
Gxy = [Gx;Gy].';

is_intersecting = check_intersection(Pxy, Gxy); 

function [is_intersecting] = check_intersection(Pxy, Gxy)
    polyP = polyshape(Pxy(:,1), Pxy(:,2));
    polyG = polyshape(Gxy(:,1), Gxy(:,2));

    % overlaps() is highly optimized for boolean intersection checks
    is_intersecting = overlaps(polyP, polyG);
end

% function [is_intersecting] = check_intersection(Px, Py, Gx, Gy)
%     % 1. Create the polyshape objects
%     polyP = polyshape(Px, Py);
%     polyG = polyshape(Gx, Gy);
% 
%     % 2. Check for overlap (Boolean result)
%     is_intersecting = overlaps(polyP, polyG);
% 
%     % 3. Visualization (Optional - for debugging)
%     figure;
%     hold on;
%     plot(polyP, 'FaceColor', 'blue', 'FaceAlpha', 0.3, 'DisplayName', 'Polygon P');
%     plot(polyG, 'FaceColor', 'red', 'FaceAlpha', 0.3, 'DisplayName', 'Polygon G');
% 
%     if is_intersecting
%         % Calculate and plot the actual intersection area in green
%         polyOverlap = intersect(polyP, polyG);
%         plot(polyOverlap, 'FaceColor', 'green', 'FaceAlpha', 0.8, 'DisplayName', 'Intersection');
%         title('Polygons Intersect!');
%     else
%         title('No Intersection Detected');
%     end
%     legend show;
%     grid on;
% end




