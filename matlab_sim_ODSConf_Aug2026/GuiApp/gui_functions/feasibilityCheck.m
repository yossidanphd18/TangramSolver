function appData = feasibilityCheck(appData)
    % 1. Use isgraphics for the handle to avoid errors if it was deleted
    % Safe check: exists, not empty, and all handles are valid graphics objects
    if isfield(appData, 'handleFeasFig') && ~isempty(appData.handleFeasFig) && all(isgraphics(appData.handleFeasFig))
        delete(appData.handleFeasFig); 
    end

    % 2. Create the Figure based on mode
    figTitle = 'Feasibility Check';
    if appData.isWeb
        % Web Mode: Must use uifigure
        appData.handleFeasFig = uifigure('Name', figTitle, 'Color', [0.15 0.15 0.15]);
        % Create axes explicitly inside the uifigure
        ax1 = uiaxes(appData.handleFeasFig, 'BackgroundColor', [0.1 0.1 0.1]);
        ax1.Position = [50 50 460 380]; % Optional: Use normalized if inside a panel
    else
        % Desktop Mode
        appData.handleFeasFig = figure('Color', [0.15 0.15 0.15], 'Name', figTitle); 
        ax1 = subplot(1,1,1);
    end

    % 3. Common Plotting Logic (Always target ax1 explicitly)
    hold(ax1, 'on'); axis(ax1, 'equal'); grid(ax1, 'on');
    
    pv = appData.Goal.Vertices;
    gg0 = polyshape(pv(:,1), pv(:,2));
    
    % Use the axes handle 'ax1' in every plotting command
    plot(ax1, gg0, 'FaceColor', [1 0.8 0.8], 'EdgeColor', [0.99, 0.11, 0.02], 'LineStyle', '--', 'LineWidth', 3.5);
    
    styleAxes(ax1); % Ensure this function is "Web-Safe" (see below)

    for k = 1:length(appData.Polygons)
        poly_data = appData.Polygons{k};
        pv = transformPolygon(poly_data.OriginalVertices, poly_data.T(1), poly_data.T(2), poly_data.Theta, poly_data.FlipID);
        plot(ax1, polyshape(pv(:,1), pv(:,2)), 'FaceColor', [0.8 0.8 1], 'EdgeColor', 'w', 'LineWidth', 0.6);
    end
    
    title(ax1, 'Feasibility Check', 'Color', 'w');

    % --- Additional Figures Logic ---
    enable_additional_figures = 0;
   
    if(enable_additional_figures)
        if appData.isWeb
            hFig = uifigure('Name', 'Heatmap Export', 'Color', [0.1 0.1 0.1]);
            % Renderer 'opengl' is default for Web, but setting it explicitly can crash uifigure
            visPanel2 = uipanel(hFig, 'BackgroundColor', [0.1 0.1 0.1], 'Units', 'normalized', 'Position', [0 0 1 1]);
            ax_heat_handle = uiaxes(visPanel2, 'BackgroundColor', [0.1 0.1 0.1]);
        else
            hFig = figure('Color', [0.1 0.1 0.1], 'Renderer', 'opengl');
            visPanel2 = uipanel(hFig, 'BackgroundColor', [0.1 0.1 0.1], 'Units', 'normalized', 'Position', [0 0 1 1]);
            ax_heat_handle = axes(visPanel2);
        end
        
        dimWhite = [0.7 0.7 0.7];

        % Set Position and Axis styling
        set(ax_heat_handle, 'Position', [0.15 0.15 0.65 0.75], 'XColor', dimWhite, 'YColor', dimWhite, ...
            'FontSize', 11, 'FontWeight', 'normal');
        
        % Data Plotting
        [M, N] = size(appData.CombinedAreas);
        imagesc(ax_heat_handle, [0.5, N-0.5], [0.5, M-0.5], appData.CombinedAreas); 
        
        % Formatting
        set(ax_heat_handle, 'YDir', 'normal');
        colormap(ax_heat_handle, hot); 
        clim(ax_heat_handle, [0 1]);
        axis(ax_heat_handle, 'equal'); axis(ax_heat_handle, 'tight');
        
        % Note: 'XAxis.Color' works on both uiaxes and axes
        ax_heat_handle.XAxis.Color = dimWhite;
        ax_heat_handle.YAxis.Color = dimWhite;
        
        xlabel(ax_heat_handle, 'Grid X', 'Color', dimWhite);
        ylabel(ax_heat_handle, 'Grid Y', 'Color', dimWhite);
        title(ax_heat_handle, 'Solver Goal', 'Color', dimWhite);
        colorbar(ax_heat_handle, 'Color', dimWhite);
    end
end

function styleAxes(ax)
    % Web Compatibility: Use isgraphics to ensure the handle is valid
    if ~isgraphics(ax), return; end
    
    % Use 'BackgroundColor' for uiaxes, 'Color' for standard axes
    if isa(ax, 'matlab.ui.control.UIAxes')
        set(ax, 'BackgroundColor', [0.1 0.1 0.1]);
    else
        set(ax, 'Color', [0.1 0.1 0.1]);
    end
    
    set(ax, 'XColor', [0.8 0.8 0.8], 'YColor', [0.8 0.8 0.8]);
    
    % Findall is safe on both, but uiaxes doesn't use the same text structure
    tObjects = findall(ax, 'type', 'text');
    if ~isempty(tObjects)
        set(tObjects, 'Color', 'w'); 
    end
end