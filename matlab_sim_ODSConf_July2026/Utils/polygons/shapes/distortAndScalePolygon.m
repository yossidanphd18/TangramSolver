function V_out = distortAndScalePolygon(V, intensity, scaleRatio)
% DISTORTANDSCALEPOLYGON Simulates camera distortion followed by resizing.
%
% Inputs:
%   V:          Nx2 array of vertices [x, y].
%   intensity:  0.0 to 1.0 (Camera perspective distortion amount).
%   scaleRatio: Factor for polybuffer.
%               1.1 = Inflate by 10%.
%               0.9 = Shrink by 10%.
%
% Output:
%   V_out:      Nx2 array of the final transformed vertices.

    % --- STEP 1: Camera Perspective Distortion ---
   
    % 1. Center the polygon
    centroid = mean(V, 1);
    V_centered = V - centroid;
   
    % 2. Define Camera Parameters
    % Max tilt/pan angle in radians (approx 70 degrees)
    max_angle = 1.2;
   
    % Generate random Tilt/Pan scaled by intensity
    x_angle = (rand - 0.5) * 2 * max_angle * intensity;
    y_angle = (rand - 0.5) * 2 * max_angle * intensity;
    z_angle = (rand - 0.5) * 0.2 * intensity; % Slight roll
   
    % 3. Rotation Matrices
    Rx = [1 0 0; 0 cos(x_angle) -sin(x_angle); 0 sin(x_angle) cos(x_angle)];
    Ry = [cos(y_angle) 0 sin(y_angle); 0 1 0; -sin(y_angle) 0 cos(y_angle)];
    Rz = [cos(z_angle) -sin(z_angle) 0; sin(z_angle) cos(z_angle) 0; 0 0 1];
   
    R = Rx * Ry * Rz;
   
    % 4. Apply 3D Rotation
    V_3D = [V_centered, zeros(size(V, 1), 1)];
    V_rotated = V_3D * R;
   
    % 5. Apply Perspective Projection
    radius = max(sqrt(sum(V_centered.^2, 2)));
    cam_dist = radius * 3; % Camera distance heuristic
   
    % Depth factor calculation
    depth_factor = 1 - (V_rotated(:,3) / cam_dist);
    depth_factor(depth_factor < 0.1) = 0.1; % Safety floor
   
    V_projected = V_rotated(:, 1:2) ./ depth_factor;
   
    % Restore position (this is the distorted, un-scaled polygon)
    V_distorted = V_projected + centroid;

    % --- STEP 2: Inflate/Shrink (Buffering) ---
   
    % Create polyshape
    ps = polyshape(V_distorted(:,1), V_distorted(:,2));
   
    if scaleRatio ~= 1
        % Calculate buffer distance based on area heuristic
        current_area = area(ps);
        if current_area < 1e-6
             warning('Polygon is too small or invalid after distortion.');
             V_out = V_distorted;
             return;
        end
       
        equiv_radius = sqrt(current_area / pi);
        buffer_dist = (scaleRatio - 1.0) * equiv_radius;
       
        % Apply buffer with 'Miter' to keep sharp angles
        % MiterLimit controls how pointy the corners can get before getting cut off.
        ps_final = polybuffer(ps, buffer_dist, 'JointType', 'miter', 'MiterLimit', 5);
    else
        ps_final = ps;
    end

    % --- STEP 3: Output ---
   
    if ps_final.NumRegions == 0
        warning('Polygon shrunk to nothingness.');
        V_out = [];
    else
        % Return the vertices of the largest boundary
        [r_x, r_y] = boundary(ps_final, 1);
        V_out = [r_x, r_y];
    end
end