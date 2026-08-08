function [V, G, H, Gi, Gd] = createShape_shape17(appData)
 
	H = {}; 
	scale_factor = appData.Grid.scale;
	t_xy_common = appData.Grid.origin_x0y0;
	base_vrtxs = appData.BaseVrtxs;
	cameraDistortionParams = appData.cameraDistortionParams;
	target_inflation_width = appData.user_params.target_inflation_width;
    
    tiny_shift = 0.0;
    x0 = 0 + tiny_shift;
    x1 = 1/8;
    x2 = 1/sqrt(8);
    x4 = x1 + 1/4;
    x5 = 1/2;
    x6 = x1 + 1/2;
    x3 = x6 - 1/sqrt(8);
    x7 = x1 + 1;
    x8 = x6 + 1/sqrt(2);
    x9 = x8 + 1/4;
    
    y0 = 0;
    y1 = 1/sqrt(8) + 1/2 - 1/sqrt(2);
    y2 = 1/sqrt(8);
    y5 = y1 + 1/sqrt(2);
    y1 = y5 - 1;
    y3 = y5 - 1/4;
    y6 = y5 + 1/4;
    y7 = y6 + 1/8;
    y4 = y7 - 1/2;
    y8 = y7 + 1/sqrt(8);

    % Vertexes:
    k = 1;
    flip_id = 1; % 1 for no flip, 2 for horizontally flipped.
    flip_id2 = 2;
    
    % Polygon 1: Big Right Triangle
    theta_deg = 0; % anti-clockwise
    txy = scale_factor * [x1,y2] + t_xy_common;
    h = (1/2)*scale_factor; w = 1*scale_factor;
    area = (0.5*h*w);
    flip_agnostic = 1;
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'LargeTriangle1', [1.0 0.5 0.5]}; k = k + 1;
    
    % Polygon 2: Big Right Triangle
    theta_deg = 45;
    txy = scale_factor * [x6,y5] + t_xy_common;
    flip_agnostic = 1;
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'LargeTriangle2', [0.7 0.8 0.5]}; k = k + 1;
    
    % Polygon 3: Parallelogram 
	if(1)
		theta_deg = 135;
		txy = scale_factor * [x0,y7] + t_xy_common;
		h = (1/4)*scale_factor; w = (1/2)*scale_factor;
		area = (2*w*h)/2;
		flip_agnostic = 0; % this tile is not flip agnostic
		V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id2, flip_agnostic, 'Parallelogram', [0.2 0.4 0.7]}; k = k + 1;
    else
		theta_deg = -45;
		txy = scale_factor * [x2+1/sqrt(8),y8] + t_xy_common;
		h = (1/4)*scale_factor; w = (1/2)*scale_factor;
		area = (2*w*h)/2;
		flip_agnostic = 0; % this tile is not flip agnostic
		V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id2, flip_agnostic, 'Parallelogram', [0.2 0.4 0.7]}; k = k + 1;
	end
	
    % Polygon 4: Small Triangle
    theta_deg = -45;
    txy = scale_factor * [x3,y0] + t_xy_common;
    h = (1/4)*scale_factor; w = (1/2)*scale_factor;
    area = (0.5*h*w);
    flip_agnostic = 1;
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'SmallTriangle1', [0.3 0.6 0.9]}; k = k + 1;
    
    % Polygon 5: Square
    theta_deg = 45;
    txy = scale_factor * [x1, y5] + t_xy_common;
    h = 0.25*sqrt(2)*scale_factor; w = 0.25*sqrt(2)*scale_factor;
    area = (w*h);
    flip_agnostic = 1;
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'Diamond', [0.3 0.3 0.1]}; k = k + 1;
    
    % Polygon 6: Small Triangle
    theta_deg = 90;
    txy = scale_factor * [x8,y6] + t_xy_common;
    h = (1/4)*scale_factor; w = (1/2)*scale_factor;
    area = (0.5*h*w);
    flip_agnostic = 1;
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'SmallTriangle2', [0.5 0.3 0.8]}; k = k + 1;
    
    % Polygon 7: Medium Triangle
    theta_deg = -45;
    txy = scale_factor * [x0,y4] + t_xy_common;
    h = (1/4)*scale_factor; w = (1/2)*scale_factor;
    area = (0.5*h*w);
    flip_agnostic = 1;
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'MediumTriangle', [0.2 0.8 0.6]}; k = k + 1;
    
     % The Goal polygon.
    G = scale_factor * [[x3,y0] ; [x6,y2] ; [x7,y2]; [x8,y5-1/sqrt(2)] ; [x8,y3]; [x9,y5] ; [x8,y6]; ... 
                        [x8,y5] ; [x6,y5] ; [x4,y6]; [x5,y7] ; [x2,y7]; [x2+1/sqrt(8),y8] ; [x2,y8];... 
                        [x0,y7] ; [x0,y4] ; [x1,y5] ; [x4,y3] ; [x1,y2] ; [x3,y2] ;] + t_xy_common;

    % inflated and distorted goals.
    Gi = G;
    Gd = G;

    if(target_inflation_width > 0)
        polyOriginal = polyshape(G(:,1), G(:,2));
        polyInflated = polybuffer(polyOriginal, target_inflation_width, 'JointType', 'miter');
        Gi = polyInflated.Vertices;
    end

    if(cameraDistortionParams.enabled)
        Gd = distortAndScalePolygon(Gi, cameraDistortionParams.intensity, cameraDistortionParams.inflate_ratio);
    end
end





