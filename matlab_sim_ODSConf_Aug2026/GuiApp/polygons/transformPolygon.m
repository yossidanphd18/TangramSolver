function [pv_out] = transformPolygon(pv_in, tx, ty, theta_deg, flip_id, is_fwd)
    % Applies optional horizontal flip, then rotation (around origin), then translation.
    %
    % pv_in: Nx2 matrix of [x, y] coordinates of the polygon.
    % tx, ty: Translation components (dx, dy).
    % theta_deg: Rotation angle in degrees.
    % flip_id: 1 for no flip, 2 for horizontal flip (across the Y-axis).

    if(nargin < 6)
        is_fwd = 1;
    end

    if flip_id == 2
       FF = [-1, 0; 0, 1];
    else % flip_id == 1 (or any other value, defaulting to no flip)
       FF = [1, 0; 0, 1]; % Identity matrix (No change)
    end

    % clockwise rotation
    theta_rad = deg2rad(theta_deg);
    RR = [cos(theta_rad), -sin(theta_rad);
	     sin(theta_rad),  cos(theta_rad)];
    
    TT = [tx, ty];

    % FWD : Y = X(FR) + T
    % BWD : X = (Y-T)F'R'
    if(is_fwd)
        pv_out = (pv_in * FF) * RR + TT;
    else
        pv_out = (pv_in - TT) * inv(FF) * inv(RR);
    end
end