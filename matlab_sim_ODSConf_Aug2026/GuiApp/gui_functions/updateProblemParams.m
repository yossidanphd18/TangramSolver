function appData = updateProblemParams(appData)

    scale_gain = appData.user_params.scale_gain;
    % time_limit_secs = appData.user_params.time_limit_secs;

    assert((scale_gain >= 0.2) && (scale_gain < 10.0), 'Invalid scale gain...');

    GRID_X_MIN = 0;
    GRID_X_MAX = round(scale_gain * 151);
    if(mod(GRID_X_MAX , 2) == 0); GRID_X_MAX = GRID_X_MAX + 1; end
    
    SCALE = round(4*(7*scale_gain));
    SCALE = round(SCALE / 4) * 4;

    GRID_Y_MIN = GRID_X_MIN;
    GRID_Y_MAX = GRID_X_MAX; 
    GRID_WIDTH = GRID_X_MAX - GRID_X_MIN;
    GRID_HEIGHT = GRID_Y_MAX - GRID_Y_MIN;
    GRID_ORIGIN_X0Y0 = [0.5*(GRID_X_MAX+1), 0.5*(GRID_Y_MAX+1)];

    appData.scale_gain = scale_gain;
    appData.Grid.xmin = GRID_X_MIN; 
    appData.Grid.xmax = GRID_X_MAX;
    appData.Grid.ymin = GRID_Y_MIN; 
    appData.Grid.ymax = GRID_Y_MAX;
    appData.Grid.origin_x0y0 = GRID_ORIGIN_X0Y0 + [1,1];
    appData.Grid.scale = SCALE;
    appData.scratch_size = [GRID_X_MAX, GRID_Y_MAX]; 
    appData.GridWidth = GRID_WIDTH;
    appData.GridHeight = GRID_HEIGHT;
    appData.GridXRange = [GRID_X_MIN, GRID_X_MAX];
    appData.GridYRange = [GRID_Y_MIN, GRID_Y_MAX];
    % appData.CombinedAreas = zeros(GRID_HEIGHT, GRID_WIDTH);

    % appData.challenge_db_save_path = ['./Challenges_scale_',num2str(scale_gain,'%.1f'),'/polygons/'];
    appData.challenge_db_save_path = appData.user_params.challenges_path;

    [appData] = handleHeuristicIntensity(appData);
 
    [appData] = prepareRunParams(appData);
      
    [appData] = loadInitialPolygons(appData);

    if(appData.flag_save_db)
        appData = handleSavedDB(appData, false);
    end
end