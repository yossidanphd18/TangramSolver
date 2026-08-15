function plotFineTuningResults(figData, solvers)

if(nargin < 2)
    % Define the solvers you want to loop over
    solvers = {'MISOCP', 'GA', 'SA'};
end

    challenge_name = figData.challenge_name;
    saveFiguresFolder = figData.saveFiguresFolder;
    nrounds = figData.nrounds;
    i = figData.i;

    
    for s = 1:length(solvers)
        solverType = solvers{s};
        
        fig_num = i * 1000 + s * 100;
        fig = figure(fig_num);
        clf(fig);
        
        % Force figure to pop out as a separate window instead of inline embedding
        set(fig, 'Visible', 'on', ...
                 'Name', sprintf('Tangram Fine-Tuning - %s (All Iterations)', solverType), ...
                 'Position', [2 + s*290, 100, 300, 400], ...
                 'Color', [0.15 0.15 0.15]);
    
        % Use tiledlayout for a clean 3x2 arrangement
        t = tiledlayout(fig, 3, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
        
        % Title the figure
        title(t, sprintf('%s — Solver: %s', challenge_name, solverType), ...
              'Color', 'w', 'FontSize', 12, 'FontWeight', 'bold');

        for iter = 1:nrounds
            % Select data based on current solver
            switch solverType
                case 'MISOCP'
                    pa = figData.polyshapesMISOCP{iter};
                    pf = figData.polyshapesMISOCP_ft{iter};
                case 'GA'
                    pa = figData.polyshapesGA{iter};
                    pf = figData.polyshapesGA_ft{iter};
                case 'SA'
                    pa = figData.polyshapesSA{iter};
                    pf = figData.polyshapesSA_ft{iter};
            end
            
            polyG = figData.TCombinedPolygons(iter).combinedPoly_true;
            
            % Plot iteration row (Before & After)
            showFineTuningRow(t, polyG, pa, pf, solverType, iter, fig);        
        end

        % Save the figure to an image file.
        savePath = fullfile(saveFiguresFolder, sprintf('figPostFTO_%s_%s.png', solverType, challenge_name));
        exportgraphics(fig, savePath, 'BackgroundColor', 'current', 'Resolution', 300);
        fprintf('Saved figure to : %s\n', savePath);

        pause(0.1);
    end
end
