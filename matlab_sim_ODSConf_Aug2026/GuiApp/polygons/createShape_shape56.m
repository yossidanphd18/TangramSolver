function [V, G, H, Gi, Gd] = createShape_shape56(appData)
    
    H = {};
 
	scale_factor = appData.Grid.scale;
	t_xy_common = appData.Grid.origin_x0y0;
	base_vrtxs = appData.BaseVrtxs;
	cameraDistortionParams = appData.cameraDistortionParams;
	target_inflation_width = appData.user_params.target_inflation_width;

    tiny_shift = 0.0;
    x0 = 0 + tiny_shift; 
    x1 = 1/4;
    x12 = x1 + 1/4;
    x2 = 3/4;
    x3 = x2 + 1/4;
    x4 = x3 + 1/4;
    x5 = x4 + 1/4;
    x6 = x5 + 1/4;
    x7 = x6 + 1/4;
    x8 = x7 + 1/4;
    x91 = x4+ 1;
    x10 = x7 + 1/2;
    x01 = x4 - 1; 
    x23 = x4 - 1/sqrt(8);
    x56 = x4 + 1/sqrt(8);
    
    y0 = 0;
    y1 = 1/4;
    y2 = 1/2;
    y3 = y2 + 1/sqrt(8);
    
    % Vertexes:
    k = 1;
    flip_id = 1; % 1 for no flip, 2 for horizontally flipped.
    flip_id2 = 2;
    
    % Polygon 1: Big Right Triangle
    theta_deg = 180; % anti-clockwise
    txy = scale_factor * [x4,y2] + t_xy_common;
    h = (1/2)*scale_factor; w = 1*scale_factor;
    area = (0.5*h*w);
    flip_agnostic = 1;
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'LargeTriangle1', [1.0 0.5 0.5]}; k = k + 1;
    
    % Polygon 2: Big Right Triangle
    theta_deg = 180;
    txy = scale_factor * [x8,y2] + t_xy_common;
    flip_agnostic = 1;
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'LargeTriangle2', [0.7 0.8 0.5]}; k = k + 1;
    
    % Polygon 3: Parallelogram
    theta_deg = 0;
    txy = scale_factor * [x2,y0] + t_xy_common;
    h = (1/4)*scale_factor; w = (1/2)*scale_factor;
    area = (2*w*h)/2;
    flip_agnostic = 0; % this tile is not flip agnostic
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id2, flip_agnostic, 'Parallelogram', [0.2 0.4 0.7]}; k = k + 1;
    
    % Polygon 4: Small Triangle
    theta_deg = 0;
    txy = scale_factor * [x6,y0] + t_xy_common;
    h = (1/4)*scale_factor; w = (1/2)*scale_factor;
    area = (0.5*h*w);
    flip_agnostic = 1;
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'SmallTriangle1', [0.3 0.6 0.9]}; k = k + 1;
    
    % Polygon 5: Square
    theta_deg = 45;
    txy = scale_factor * [x3, y1] + t_xy_common;
    h = 0.25*sqrt(2)*scale_factor; w = 0.25*sqrt(2)*scale_factor;
    area = (w*h);
    flip_agnostic = 1;
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'Diamond', [0.3 0.3 0.1]}; k = k + 1;
    
    % Polygon 6: Small Triangle
    theta_deg = 180;
    txy = scale_factor * [x10,y1] + t_xy_common;
    h = (1/4)*scale_factor; w = (1/2)*scale_factor;
    area = (0.5*h*w);
    flip_agnostic = 1;
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'SmallTriangle2', [0.5 0.3 0.8]}; k = k + 1;
    
    % Polygon 7: Medium Triangle
    theta_deg = 0;
    txy = scale_factor * [x23,y2] + t_xy_common;
    h = (1/4)*scale_factor; w = (1/2)*scale_factor;
    area = (0.5*h*w);
    flip_agnostic = 1;
    V{k} = {base_vrtxs{k}, theta_deg, txy, area, flip_id, flip_agnostic, 'MediumTriangle', [0.2 0.8 0.6]}; k = k + 1;
    
     % The Goal polygon.
    G = scale_factor * [[x1,y0] ; [x2,y0] ; [x3,y1] ; [x4,y0] ; [x5,y1] ; [x6,y0] ; [x8,y0] ;...
                        [x10,y1] ; [x7,y1] ; [x8,y2] ; [x56,y2] ; [x4,y3] ; [x23,y2] ; ...
                        [x01,y2] ; [x12,y1] ; [x0,y1] ] + t_xy_common;

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





