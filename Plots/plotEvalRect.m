function [rect] = plotEvalRect(gridSize, scaling, evalError, dx, dy, plotPos, evalElapsed)

    % Plotting the grid/ game window
    xlim([scaling.x_min scaling.x_max]);
    ylim([scaling.y_min scaling.y_max]);
    errDisp = sprintf('%.1f', evalError*10);
    dispTime = sprintf('%.0f', evalElapsed);
    text(scaling.x_min + 0.42*dx, scaling.y_min + 1.05*dy, 'Evaluation', 'FontSize', 20, 'Color', 'r');
    text(scaling.x_min + 0.48*dx, scaling.y_min + 0.8*dy, errDisp, 'FontSize', 20, 'Color', 'r');
    text(scaling.x_min + 0.90*dx, scaling.y_min - 0.05*dy, dispTime, 'FontSize', 50, 'Color', 'r');
    rectplot = @(x1,x2) rectangle('Position',[x1 x2 dx/gridSize dy/gridSize], EdgeColor=[0.6 0.6 0.6], LineWidth=2);
    for i = 1:gridSize
        for j= 1:gridSize
            rect(i, j) = rectplot(scaling.x_min + (j-1)*dx/gridSize, scaling.y_max - (i)*dy/gridSize);
        end
    end
    set(gca, 'color', '[0.85 0.85 0.85]')
    xticks([]);    yticks([])
    set(gcf, 'Position', plotPos)

end