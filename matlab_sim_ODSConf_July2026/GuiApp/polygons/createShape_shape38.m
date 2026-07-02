function [V, G] = createShape_shape38(appData)
    
scale_factor = appData.Grid.scale;
t_xy_common = appData.Grid.origin_x0y0;
base_vrtxs = appData.BaseVrtxs;
cameraDistortionParams = appData.cameraDistortionParams;
target_inflation_width = appData.user_params.target_inflation_width;

% if(nargin < 4)
%     cameraDistortionParams.enabled = 0;
%     cameraDistortionParams.intensity = 0;    %  Camera Perspective distortion
%     cameraDistortionParams.inflate_ratio = 1.0;  % Inflate or Shrink
% end

    % Vertexes:
    k = 1;
    flip_id = 1; % 1 for no flip, 2 for horizontally flipped.
    flip_id2 = 2;

    % Polygon 1: Big Right Triangle
    theta_deg = 135; % anti-clockwise
    txy = scale_factor * [1/sqrt(2),1/sqrt(2)] + t_xy_common;
    h = (1/2)*scale_factor; w = 1*scale_factor;
    area = (0.5*h*w);
    flip_agnostic = 1;
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'LargeTriangle1', [1.0 0.5 0.5]}; k = k + 1;

    % Polygon 2: Big Right Triangle
    theta_deg = 135;
    txy = scale_factor * [2/sqrt(2) + sqrt(2)/4, 1/sqrt(2)] + t_xy_common;
    flip_agnostic = 1;
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'LargeTriangle2', [0.7 0.8 0.5]}; k = k + 1;

    % Polygon 3: Parallelogram
	if(1)
		theta_deg = 135;
		txy = scale_factor * [2/sqrt(2), 1/sqrt(2)] + t_xy_common;
		h = (1/4)*scale_factor; w = (1/2)*scale_factor;
		area = (2*w*h)/2;
		flip_agnostic = 0; % this tile is not flip agnostic
		V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'Parallelogram', [0.2 0.4 0.7]}; k = k + 1;
	else
		theta_deg = -45;
		txy = scale_factor * [1/sqrt(2) + sqrt(2)/4, 0] + t_xy_common;
		h = (1/4)*scale_factor; w = (1/2)*scale_factor;
		area = (2*w*h)/2;
		flip_agnostic = 0; % this tile is not flip agnostic
		V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'Parallelogram', [0.2 0.4 0.7]}; k = k + 1;
	end
    
    % Polygon 4: Small Triangle
    theta_deg = -135;
    txy = scale_factor * [1/sqrt(2) + sqrt(2)/4, sqrt(2)/4] + t_xy_common;
    h = (1/4)*scale_factor; w = (1/2)*scale_factor;
    area = (0.5*h*w);
    flip_agnostic = 1;
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'SmallTriangle1', [0.3 0.6 0.9]}; k = k + 1;
    
    % Polygon 5: Square
    theta_deg = 0;
    txy = scale_factor * [1/sqrt(2) , 0] + t_xy_common;
    h = 0.25*sqrt(2)*scale_factor; w = 0.25*sqrt(2)*scale_factor;
    area = (w*h);
    flip_agnostic = 1;
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'Diamond', [0.3 0.3 0.1]}; k = k + 1;

    % Polygon 6: Small Triangle
    theta_deg = -45;
    txy = scale_factor * [sqrt(2), sqrt(2)/4] + t_xy_common;
    h = (1/4)*scale_factor; w = (1/2)*scale_factor;
    area = (0.5*h*w);
    flip_agnostic = 1;
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'SmallTriangle2', [0.5 0.3 0.8]}; k = k + 1;

    % Polygon 7: Medium Triangle
    theta_deg = 180;
    txy = scale_factor * [sqrt(2) , 1/sqrt(2)] + t_xy_common;
    h = (1/4)*scale_factor; w = (1/2)*scale_factor;
    area = (0.5*h*w);
    flip_agnostic = 1;
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'MediumTriangle', [0.2 0.8 0.6]}; k = k + 1;

    % The Goal polygon.
    G = scale_factor * [[0,0]; [2/sqrt(2)+0.25*sqrt(2),0] ; [2/sqrt(2)+0.25*sqrt(2), 1/sqrt(2)] ; [1/sqrt(2), 1/sqrt(2)]] + t_xy_common;
	
    if(cameraDistortionParams.enabled)
        G = distortAndScalePolygon(G, cameraDistortionParams.intensity, cameraDistortionParams.inflate_ratio);
    end
end