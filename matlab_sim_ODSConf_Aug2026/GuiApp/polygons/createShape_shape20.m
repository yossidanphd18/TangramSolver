function [V, G, H, Gi, Gd] = createShape_shape20(appData)
    
	H = {}; % H for holes in the puzzle (see e.g. shape60).
	scale_factor = appData.Grid.scale;
	t_xy_common = appData.Grid.origin_x0y0;
	base_vrtxs = appData.BaseVrtxs;
	cameraDistortionParams = appData.cameraDistortionParams;
	target_inflation_width = appData.user_params.target_inflation_width;
    
    tiny_shift = 0.0;
    x0 = 0 + tiny_shift; 
    x4 = 1/2 + 1/sqrt(8);
    x1 = x4-1/2;
    x3 = x4 - 1/8;
    x2 = x3-1/4;
    x5 = x4 + 1/8;
    x6 = x4 + 1/4;
    x7 = x4 + 1/2;
    x8 = x7 + (1/sqrt(2) - 1/2);
    x9 = x1 + 5/4;
    
    y0 = 0;
    y1 = 1/8;
    y3 = 1/sqrt(8);
    y4 = 9/8 - 1/sqrt(2);
    y2 = y4 - 1/4;
    y5 = y1 + 1/2 - 1/(2*sqrt(8));
    y6 = y5 + 1/(2*sqrt(8));
    y7 = y5 + 1/sqrt(8);
    y8 = y6 + 1/2;
    
    
    % Vertexes:
    k = 1;
    flip_id = 1; % 1 for no flip, 2 for horizontally flipped.
    flip_id2 = 2;
    
    % Polygon 1: Big Right Triangle
    theta_deg = -90; % anti-clockwise
    txy = scale_factor * [x4,y1] + t_xy_common;
    h = (1/2)*scale_factor; w = 1*scale_factor;
    area = (0.5*h*w);
    flip_agnostic = 1;
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'LargeTriangle1', [1.0 0.5 0.5]}; k = k + 1;
    
    % Polygon 2: Big Right Triangle
    theta_deg = -135;
    txy = scale_factor * [x8,y4] + t_xy_common;
    flip_agnostic = 1;
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'LargeTriangle2', [0.7 0.8 0.5]}; k = k + 1;
    
    % Polygon 3: Parallelogram
    theta_deg = 0;
    txy = scale_factor * [x9,y2] + t_xy_common;
    h = (1/4)*scale_factor; w = (1/2)*scale_factor;
    area = (2*w*h)/2;
    flip_agnostic = 0; % this tile is not flip agnostic
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id2, flip_agnostic, 'Parallelogram', [0.2 0.4 0.7]}; k = k + 1;
    
    % Polygon 4: Small Triangle
    theta_deg = 45;
    txy = scale_factor * [x0,y5] + t_xy_common;
    h = (1/4)*scale_factor; w = (1/2)*scale_factor;
    area = (0.5*h*w);
    flip_agnostic = 1;
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'SmallTriangle1', [0.3 0.6 0.9]}; k = k + 1;
    
    % Polygon 5: Square
    theta_deg = 0;
    txy = scale_factor * [x0, y5] + t_xy_common;
    h = 0.25*sqrt(2)*scale_factor; w = 0.25*sqrt(2)*scale_factor;
    area = (w*h);
    flip_agnostic = 1;
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'Diamond', [0.3 0.3 0.1]}; k = k + 1;
    
    % Polygon 6: Small Triangle
    theta_deg = 0;
    txy = scale_factor * [x2,y0] + t_xy_common;
    h = (1/4)*scale_factor; w = (1/2)*scale_factor;
    area = (0.5*h*w);
    flip_agnostic = 1;
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'SmallTriangle2', [0.5 0.3 0.8]}; k = k + 1;
    
    % Polygon 7: Medium Triangle
    theta_deg = -45;
    txy = scale_factor * [x1,y6] + t_xy_common;
    h = (1/4)*scale_factor; w = (1/2)*scale_factor;
    area = (0.5*h*w);
    flip_agnostic = 1;
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'MediumTriangle', [0.2 0.8 0.6]}; k = k + 1;
    
     % The Goal polygon.
    G = scale_factor * [[x2,y0] ; [x5,y0] ; [x4,y1] ; [x4,y4] ; [x6,y2] ; [x9,y2] ; ...
                        [x7,y4] ; [x8,y4] ; [x4,y8] ; [x1,y8] ; [x1,y7] ; [x0,y7] ; [x0,y5] ; ...
                        [x1,y5-1/sqrt(8)]; [x1,y6]; [x3,1/4] ] + t_xy_common;

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





