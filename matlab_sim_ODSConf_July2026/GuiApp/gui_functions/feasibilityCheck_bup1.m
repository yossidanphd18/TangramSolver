function appData = feasibilityCheck(appData)
    
    % if ishandle(appData.handleFeasFig), close(appData.handleFeasFig); end
    if isgraphics(appData.handleFeasFig), delete(appData.handleFeasFig); end
    appData.handleFeasFig = figure('Color', [0.15 0.15 0.15], 'Name', 'Feasibility Check'); 
    hold on; axis equal; grid on;
    pv = appData.Goal.Vertices;
    gg0 = polyshape(pv(:,1), pv(:,2));
    ax1 = subplot(1,1,1);
    plot(gg0, 'FaceColor', [1 0.8 0.8], 'EdgeColor', [0.99, 0.11, 0.02], 'LineStyle', '--', 'LineWidth', 3.5);
    styleAxes(ax1);
    for k = 1:length(appData.Polygons)
        poly_data = appData.Polygons{k};
        pv = transformPolygon(poly_data.OriginalVertices, poly_data.T(1), poly_data.T(2), poly_data.Theta, poly_data.FlipID);
        plot(polyshape(pv(:,1), pv(:,2)), 'FaceColor', [0.8 0.8 1], 'EdgeColor', 'w', 'LineWidth', 0.6);
    end
    title('Feasibility Check', 'Color', 'w');

    % Plot additional figures (for paper needs).
    enable_additional_figures = 0;
   
    if(enable_additional_figures)

        % 1. Create figure with OpenGL for sharpest rendering
        hFig = figure('Color', [0.1 0.1 0.1], 'Renderer', 'opengl');
        visPanel2 = uipanel(hFig, 'BackgroundColor', [0.1 0.1 0.1], 'Units', 'normalized', 'Position', [0 0 1 1]);
        
        dimWhite = [0.7 0.7 0.7];

        % 2. Setup Axes with the dimmed color
        ax_heat_handle = axes(visPanel2, ...
            'Position', [0.15 0.15 0.65 0.75], ... 
            'Color', [0.1 0.1 0.1], ... 
            'XColor', dimWhite, ... % Set axis line, ticks, and labels to dim white
            'YColor', dimWhite, ... 
            'FontSize', 11, ...      % Slightly smaller font also helps reduce "strength"
            'FontWeight', 'normal'); % Change from 'bold' to 'normal' to reduce intensity
        
        % 3. Plot Data
        if (~isfield(appData, 'CombinedAreas') || isempty(appData.CombinedAreas))
            error('Could not find a valid appData.CombinedAreas member!');
        end

        [M, N] = size(appData.CombinedAreas);
        imagesc(ax_heat_handle, [0.5, N-0.5], [0.5, M-0.5], appData.CombinedAreas); 
        
        % 4. Formatting
        set(ax_heat_handle, 'YDir', 'normal');
        colormap(ax_heat_handle, hot); 
        clim(ax_heat_handle, [0 1]);
        axis(ax_heat_handle, 'equal'); 
        axis(ax_heat_handle, 'tight');
        
        % 5. Apply the Dim color to the Ruler objects directly
        ax_heat_handle.XAxis.Color = dimWhite;
        ax_heat_handle.YAxis.Color = dimWhite;
        ax_heat_handle.XAxis.LineWidth = 0.8; % Thinning the line also reduces visual "strength"
        ax_heat_handle.YAxis.LineWidth = 0.8;
        
        % 6. Adjust Ticks
        xticks(ax_heat_handle, 0:max(1, round(N/10)):N);
        yticks(ax_heat_handle, 0:max(1, round(M/10)):M);
        
        % 7. Soften the Grid
        grid(ax_heat_handle, 'on');
        set(ax_heat_handle, ...
            'GridColor', [1 1 1], ...      
            'GridAlpha', 0.15, ...         % Lowered alpha for a ghost-like grid
            'Layer', 'top', ...            
            'TickDir', 'out');
        
        % 8. Update Labels to match the dimmed aesthetic
        xlabel(ax_heat_handle, 'Grid X', 'Color', dimWhite);
        ylabel(ax_heat_handle, 'Grid Y', 'Color', dimWhite);
        title(ax_heat_handle, 'Solver Goal (covered-area for pixel values)', 'Color', dimWhite);
        
        cb = colorbar(ax_heat_handle, 'Color', dimWhite);

        dbg = 1;
    end
end

function styleAxes(ax)
    set(ax, 'Color', [0.1 0.1 0.1], 'XColor', [0.8 0.8 0.8], 'YColor', [0.8 0.8 0.8]);
    set(findall(ax, 'type', 'text'), 'Color', 'w'); 
end
