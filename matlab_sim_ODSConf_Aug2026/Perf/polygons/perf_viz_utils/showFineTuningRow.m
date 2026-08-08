function showFineTuningRow(t, polyshapeG, polyshapesP_a, polyshapesP_f, solverType, iter, fig)
    N = length(polyshapesP_a);
    colors = lines(N);
    
    figure(fig);
    
    % --- Column 1: Before Fine-Tuning ---
    ax1 = nexttile(t);
    hold(ax1, 'on');
    plot(ax1, polyshapeG, 'FaceColor', [0.9 0.9 0.9], 'EdgeColor', 'k', 'LineWidth', 1.2);
    for n = 1:N
        plot(ax1, polyshapesP_a{n}, 'FaceColor', colors(n,:), 'FaceAlpha', 0.6, 'EdgeColor', 'k');
    end
    title(ax1, sprintf('Iter %d: Before', iter), 'Color', 'w', 'FontSize', 10, 'FontWeight', 'bold');
    axis(ax1, 'equal'); grid(ax1, 'on'); hold(ax1, 'off');
    styleAxes(ax1);
    
    % --- Column 2: After Fine-Tuning ---
    ax2 = nexttile(t);
    hold(ax2, 'on');
    plot(ax2, polyshapeG, 'FaceColor', [0.9 0.9 0.9], 'EdgeColor', 'k', 'LineWidth', 1.2);
    for n = 1:N
        plot(ax2, polyshapesP_f{n}, 'FaceColor', colors(n,:), 'FaceAlpha', 0.6, 'EdgeColor', 'k');
    end
    title(ax2, sprintf('Iter %d: After', iter), 'Color', 'w', 'FontSize', 10, 'FontWeight', 'bold');
    axis(ax2, 'equal'); grid(ax2, 'on'); hold(ax2, 'off');
    styleAxes(ax2);
end

function styleAxes(ax)
    set(ax, 'Color', [0.1 0.1 0.1], 'XColor', [0.8 0.8 0.8], 'YColor', [0.8 0.8 0.8], 'FontSize', 8);
    set(findall(ax, 'type', 'text'), 'Color', 'w'); 
end