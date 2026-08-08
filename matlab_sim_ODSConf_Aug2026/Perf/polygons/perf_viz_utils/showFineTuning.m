function showFineTuning(fig_num, polyshapeG, polyshapesP_a, polyshapesP_f, solverType)
    % 1. Create or select the target figure explicitly
    fig = figure(fig_num);
    clf(fig); 
    
    set(fig, 'Name', sprintf('Tangram Fine-Tuning - %s', solverType), ...
             'Position', [100 + mod(fig_num, 50), 100 + mod(fig_num, 50), 1200, 500], ...
             'Color', [0.15 0.15 0.15]);
         
    N = length(polyshapesP_a);
    colors = lines(N);
    
    % 2. Explicitly create independent Left Axes (Before Fine-Tuning)
    ax1 = axes('Parent', fig, 'Position', [0.07, 0.15, 0.40, 0.75]);
    hold(ax1, 'on');
    plot(ax1, polyshapeG, 'FaceColor', [0.9 0.9 0.9], 'EdgeColor', 'k', 'LineWidth', 1.5);
    for n = 1:N
        plot(ax1, polyshapesP_a{n}, 'FaceColor', colors(n,:), 'FaceAlpha', 0.6, 'EdgeColor', 'k');
    end
    title(ax1, ['[', solverType, '] Before Fine-Tuning'], 'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold');
    axis(ax1, 'equal'); grid(ax1, 'on'); hold(ax1, 'off');
    
    % 3. Explicitly create independent Right Axes (After Fine-Tuning)
    ax2 = axes('Parent', fig, 'Position', [0.54, 0.15, 0.40, 0.75]);
    hold(ax2, 'on');
    plot(ax2, polyshapeG, 'FaceColor', [0.9 0.9 0.9], 'EdgeColor', 'k', 'LineWidth', 1.5);
    for n = 1:N
        plot(ax2, polyshapesP_f{n}, 'FaceColor', colors(n,:), 'FaceAlpha', 0.6, 'EdgeColor', 'k');
    end
    title(ax2, ['[', solverType, '] After Fine-Tuning'], 'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold');
    axis(ax2, 'equal'); grid(ax2, 'on'); hold(ax2, 'off');
    
    % Apply your custom dark styling to both panels
    styleAxes(ax1);
    styleAxes(ax2);
end

function styleAxes(ax)
    set(ax, 'Color', [0.1 0.1 0.1], 'XColor', [0.8 0.8 0.8], 'YColor', [0.8 0.8 0.8]);
    set(findall(ax, 'type', 'text'), 'Color', 'w'); 
end