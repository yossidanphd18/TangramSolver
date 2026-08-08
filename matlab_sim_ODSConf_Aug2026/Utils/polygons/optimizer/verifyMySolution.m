function [KPIs, SOLVER_RESULT] = verifyMySolution(x_sol, GP, TImages, CountsDB, user_flag)            
    if(nargin < 5)
        user_flag = 1;
    end
    
    % for later debug
    save x_sol x_sol
    save GP GP
    save TImages TImages
    save CountsDB CountsDB

    % Load the true solution (our golden reference)
    challenges_path = GP.challenge_db_save_folder_path;
    [challenge_name] = extractShapeID(GP.db_save_folder_path);
    [challengeData, true_txy, true_flips, true_rot_idxs] = loadTrueResult(challenges_path, challenge_name);
    
    if(isempty(challengeData) || isempty(challenge_name))
        error('Could not find .mat files for %s\n', challenge_name);
    end

    % Extract our solver solution
    [found_rots_id, found_flips_id, found_txy] = extract_solution_parameters(x_sol, TImages, CountsDB);
    theta_degs = 0:45:(360-0.1);  % For mapping rotation index 0,1,2.. to degree angle 0,45,90,...
    [solImage, refImage, diffImage] = deriveSolutionImages(GP, found_rots_id, found_txy, found_flips_id, TImages);
    absDiffImage = abs(diffImage);

    npcs = TImages.npcs;
    if(GP.user_params.show_final_result_figure && user_flag)
        summaryFig = figure('Color', [0.15 0.15 0.15], 'Name', 'Results: True vs Ours'); 
        set(summaryFig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
        
        % --- 1. Define the Shared Colors ---
        colorAzure = [0.3 0.6 1];     % True/Reference
        colorOlive = [0.3 0.6 0];     % Solver/Ours
        colorBlack = [0.15 0.15 0.15]; % Background
        
        % --- 2. Create Smooth Gradient Colormaps (256 levels) ---
        % Gradient from Background Black to Olive
        mapSolver = [linspace(colorBlack(1), colorOlive(1), 256)', ...
                     linspace(colorBlack(2), colorOlive(2), 256)', ...
                     linspace(colorBlack(3), colorOlive(3), 256)'];
        
        % Gradient from Background Black to White (for differences)
        mapDiff = [linspace(colorBlack(1), 1, 256)', ...
                   linspace(colorBlack(2), 1, 256)', ...
                   linspace(colorBlack(3), 1, 256)'];

        if ishandle(summaryFig)
             sgtitle(summaryFig, 'True Result (Azure) vs. Solver Result (Olive)', ...
                'Color', 'w', 'FontSize', 16, 'FontWeight', 'bold');
        end
        
        xy_shift_true = round([18, 18] * GP.user_params.scale_gain);
        xy_shift_ours = -xy_shift_true;
        Polygons = challengeData.TilesInfo.FinalPlacement.Polygons;
        
        % --- Subplot 1: Solver Result ---
        max_pixel = max(solImage(:));
        ax1 = subplot(2, 2, 1);
        imagesc(ax1, fliplr(imrotate(solImage,180))); 
        colormap(ax1, mapSolver); 
        clim(ax1, [0 max_pixel]); % Force mapping from 0 to 2.2
        axis(ax1, 'equal'); grid(ax1, 'on'); hold(ax1, 'on');
        styleAxes(ax1);
        set(ax1, 'XTick', [], 'YTick', []);
        title('Solver Recon Image', 'Color', 'w');

        % --- Subplot 2: Difference ---
        ax2 = subplot(2, 2, 2);
        imagesc(ax2, fliplr(imrotate(absDiffImage,180)));
        colormap(ax2, mapDiff);   
        % Scale based on actual max diff, but at least 0.1 to avoid errors
        clim(ax2, [0 max(0.1, max(absDiffImage(:)))]); 
        axis(ax2, 'equal'); grid(ax2, 'on'); hold(ax2, 'on');
        styleAxes(ax2);
        set(ax2, 'XTick', [], 'YTick', []);
        title('Abs Diff (True vs. Ours)', 'Color', 'w');

        % --- Subplot 3: Comparison (Polyshape Mode) ---
        ax3 = subplot(2, 2, 3);
        hold(ax3, 'on'); axis(ax3, 'equal'); grid(ax3, 'on');
        
        gv = TImages.Goal.Vertices;
        plot(translate(polyshape(gv(:,1), gv(:,2)), xy_shift_true), 'FaceColor', [1 0.8 0.8], 'EdgeAlpha', 0.3, 'LineStyle', '--');
        plot(translate(polyshape(gv(:,1), gv(:,2)), xy_shift_ours), 'FaceColor', [1 0.3 0.6], 'EdgeAlpha', 0.3, 'LineStyle', '--');
        
        for k = 1:npcs
            txy_ours = found_txy{k} + challengeData.Grid.origin_x0y0 + xy_shift_ours;
            txy_true = true_txy{k} + challengeData.Grid.origin_x0y0 + xy_shift_true;
            
            pv = Polygons{k}.OriginalVertices;
            pv_ours = transformPolygon(pv, txy_ours(1), txy_ours(2), theta_degs(found_rots_id(k)), found_flips_id(k));
            pv_true = transformPolygon(pv, txy_true(1), txy_true(2), theta_degs(true_rot_idxs(k)), true_flips(k));
    
            plot(ax3, polyshape(pv_true(:,1), pv_true(:,2)), 'FaceColor', colorAzure, 'EdgeColor', 'w', 'LineWidth', 0.6);
            plot(ax3, polyshape(pv_ours(:,1), pv_ours(:,2)), 'FaceColor', colorOlive, 'EdgeColor', 'w', 'LineWidth', 0.6);
        end
        styleAxes(ax3);
        set(ax3, 'XTick', [], 'YTick', []);
        title('True (azure) vs. Solver (olive)', 'Color', 'w');
        
        drawnow limitrate;
    end

    % --- KPI Calculation ---
    maxAbsDiff = max(absDiffImage(:));
    meanMSE = mean(diffImage(:).^2);
    ERROR_TH = if_else(strcmp(GP.challenge_type,'polygons'), 2, 1e-7);
    
    success = (maxAbsDiff < ERROR_TH);
    fprintf('\n****************************************************************');
    fprintf('\n**** Optimization results {true_result , our_result}    ********');
    fprintf('\n****************************************************************\n\n');
    
    status_str = if_else(success, 'SUCCESS', '** FAILED **');
    fprintf('---> Solver vs Ref maxAbsDiff = %.4f, meanMSE = %.4e. --> %s.\n', ...
            maxAbsDiff, meanMSE, status_str);
    
    % Combinations Count
    ncombs_prod = 1;
    for k = 1:npcs
        TM = CountsDB(k,:,:);
        ncombs_prod = ncombs_prod * sum(TM(:));
    end
    fprintf('\n Note that this puzzle has %.3e raw combinations.\n', ncombs_prod);
    
    SOLVER_RESULT.scale_gain = GP.user_params.scale_gain;
    SOLVER_RESULT.found_rots_id = found_rots_id;
    SOLVER_RESULT.found_flips_id = found_flips_id;
    SOLVER_RESULT.found_txy = found_txy;
    
    KPIs = struct('ncombinations', ncombs_prod, 'maxAbsDiff', maxAbsDiff, 'MSE', meanMSE, ...
                  'success', success, 'refImage', refImage, ...
                  'solImage', solImage, 'diffImage', diffImage);
end

% Helper for clean code
function val = if_else(condition, true_val, false_val)
    if condition, val = true_val; else, val = false_val; end
end

function [challengeData, true_txy, true_flips, true_rot_idxs] = loadTrueResult(challengesPath, challenge_name)
    challengeData = [];
    true_txy = [];
    true_flips = [];
    true_rot_idxs = [];

    matFile = fullfile(challengesPath, [char(challenge_name),'_data.mat']);
    if isfile(matFile)
        data = load(matFile);
        challengeData = data.SaveDB;
        true_txy = challengeData.Goal.true_translations;
        true_flips = challengeData.Goal.true_flips;
        true_rot_idxs = challengeData.Goal.true_rot_idxs;
    end
end

function [solImage, refImage, diffImage] = deriveSolutionImages(GP,found_rots_id, found_txy, found_flips_id, TImages)
    solImage = zeros(GP.im_dims);
    for k = 1:TImages.npcs
        rot_idx = found_rots_id(k);
        txy = found_txy{k};
        flip_id = found_flips_id(k);
        rotImage = TImages.Shapes{k}.Flips{flip_id}.RotatedImages{rot_idx}.rotImage;
        rotImage = imtranslate(rotImage, txy , 'FillValues', 0);
        solImage = solImage + rotImage;
    end
    refImage = TImages.Goal.puzzle;
    diffImage = refImage - solImage;
end

% --- Helper to apply the dark theme to the axes ---
function styleAxes(ax)
    set(ax, 'Color', [0.1 0.1 0.1], ...     % Darker axis background
            'XColor', [0.8 0.8 0.8], ...    % Light gray ticks
            'YColor', [0.8 0.8 0.8]);
    set(findall(ax, 'type', 'text'), 'Color', 'w'); % All text white
end

