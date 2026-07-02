function appData = loadInitialPolygons(appData)

    scale = appData.Grid.scale;
    appData.BaseVrtxs{1} = scale * [[0,0];[1,0];[0.5,0.5]];
    appData.BaseVrtxs{2} = appData.BaseVrtxs{1};
    appData.BaseVrtxs{3} = scale * [[0,0];[1/2,0];[3/4,1/4];[1/4,1/4]];
    appData.BaseVrtxs{4} = scale * [[0,0];[1/2,0];[1/4,1/4]];
    appData.BaseVrtxs{5} = scale * [[0,0];[1/sqrt(8),0];[1/sqrt(8),1/sqrt(8)];[0,1/sqrt(8)]];
    appData.BaseVrtxs{6} = appData.BaseVrtxs{4};
    appData.BaseVrtxs{7} = scale * [[0,0];[2/sqrt(8),0];[1/sqrt(8),1/sqrt(8)]];
    
    % [V, Vg] = feval(['createShape_', appData.puzzle_id], scale, appData.Grid.origin_x0y0, appData.BaseVrtxs, ...
    %     appData.cameraDistortionParams, appData.user_params.target_inflation_width);
    [V, Vg] = feval(['createShape_', appData.puzzle_id], appData);

    polygons = cell(length(V), 1);
    for k = 1:length(V)
        theta = V{k}{2};
        poly_name = V{k}{7};
        [theta] = verifyPolygonAngle(theta);
        polygons{k} = struct('OriginalVertices', V{k}{1}, 'Theta', theta, ...
            'T', V{k}{3}, 'Area', V{k}{4}, 'FlipID', V{k}{5}, ...
            'FlipAgnostic', V{k}{6}, 'Name', poly_name, 'Color', V{k}{8}, ...
            'V_BL_centered', min(V{k}{1}, [], 1));
        polygons{k}.Vertices = transformPolygon(polygons{k}.OriginalVertices, ...
            polygons{k}.T(1), polygons{k}.T(2), polygons{k}.Theta, polygons{k}.FlipID);
        
        % set the non-duplicated rotation indexes.
        if(strcmp(poly_name, 'Diamond'))
            polygons{k}.RotIndxsNoDup = [1:2]; % 0, 45 degrees
        elseif(strcmp(poly_name, 'Parallelogram')) 
            polygons{k}.RotIndxsNoDup = [1:4]; % 0, 45, 90, 135 degrees
        else
            polygons{k}.RotIndxsNoDup = [1:8]; % 0, 45, 90, 135, 180, ..., 315 degrees
        end
    end

    if((appData.scale_gain < 1.0) && 0)
        inflate_tol = 0.5;
        G_poly = polyshape(Vg(:,1), Vg(:,2));
        G_sharp = polybuffer(G_poly, inflate_tol, 'JointType', 'miter', 'MiterLimit', 20);
        Vg = G_sharp.Vertices;

        if(0)
            figure;
            plot(G_poly, 'FaceColor', 'blue', 'FaceAlpha', 0.3); hold on;
            plot(G_sharp, 'FaceColor', 'red', 'FaceAlpha', 0.1);
            legend('Original', 'Inflated');
            title(['Polygon Inflation with tol = ', num2str(inflate_tol)]);
            grid on; axis equal;
        end
    end

    appData.Polygons = polygons;
    appData.Goal.Vertices = Vg;
    appData.Goal.OriginalVertices = Vg - appData.Grid.origin_x0y0;
    
    appData = updateVisualizationAndArea(appData);

    if(appData.user_params.enable_first_feasibility_check)
        appData = feasibilityCheck(appData);
    end
    
end