function [] = plotFamilRect(gridSize, scaling, dxy, pos)

    xlim([scaling.min scaling.max])
    ylim([scaling.min scaling.max])

    rectplot = @(x1,x2) rectangle('Position',[x1 x2 dxy/gridSize dxy/gridSize], EdgeColor=[0.6 0.6 0.6], LineWidth=2);
    for i = 1:gridSize
        for j= 1:gridSize
            r(i, j) = rectplot(scaling.min + (j-1)*dxy/gridSize, scaling.max - (i)*dxy/gridSize);
        end
    end

    set(gca, 'color', '[0.85 0.85 0.85]')
    xticks([]);    yticks([]);
    set(gcf, 'Position', pos)

end