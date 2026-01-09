function [] = plotTrial(scaling, capScore, capScoreCum, dx, dy)

    dispScore    = sprintf('%.0f', capScore);
    dispScoreCum = sprintf('%.0f/6000', capScoreCum);
    dispScoreCumPer = sprintf('%.0f', capScoreCum/60);
    text(scaling.x_min, scaling.y_min  + 1.05*dy, dispScore, 'FontSize', 20, 'Color', 'r')
    text(scaling.x_min + 0.45*dx, scaling.y_min + 1.05*dy, dispScoreCum, 'FontSize', 20, 'Color', 'r')
    text(scaling.x_min + 0.90*dx, scaling.y_min + 1.05*dy, dispScoreCumPer, 'FontSize', 20, 'Color', 'r')
    xlim([scaling.x_min scaling.x_max])
    ylim([scaling.y_min scaling.y_max])
    grid on;
    xticks(scaling.x_min:0.2*dx:scaling.x_max)
    yticks(scaling.y_min:0.2*dy:scaling.y_max)
    set(gcf, 'Position', [460, 0, 1000, 1000])
    set(gca, 'LineWidth', 3, 'color', '[0.85 0.85 0.85]')

end