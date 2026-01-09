function [rect] = plotTrialRect(gridSize, scaling, capScore, capScoreCum, dxy, pointerState, trialNum, sessionNum, pos)
    
    xlim([scaling.min scaling.max]);
    ylim([scaling.min scaling.max]);

    dispScore    = sprintf('%.0f', capScore);
    dispScoreCum = sprintf('%.0f/%.0f', capScoreCum, (trialNum)*100);
    dispScoreCumPer = sprintf('%.0f%%', max(0, capScoreCum/(trialNum)));
    trial = sprintf('%.0f - %.0f', sessionNum, trialNum);
%     dispTime = sprintf('%.1f', time);
    text(scaling.min, scaling.min  + 1.05*dxy, dispScore, 'FontSize', 20, 'Color', 'r');
    text(scaling.min + 0.45*dxy, scaling.min + 1.05*dxy, dispScoreCum, 'FontSize', 20, 'Color', 'r');
    text(scaling.min + 0.90*dxy, scaling.min + 1.05*dxy, dispScoreCumPer, 'FontSize', 20, 'Color', 'r');
    text(scaling.min + 0.45*dxy, scaling.min - 0.05*dxy, pointerState, 'FontSize', 10, 'Color', 'b');
    text(scaling.min, scaling.min - 0.05*dxy, trial, 'FontSize', 20, 'Color', 'b');
%     if time<=3 && mod(trialNum, 2) ~= 0,   text(scaling.min + 0.90*dxy, scaling.min - 0.05*dxy, dispTime, 'FontSize', 50, 'Color', 'r'); end

    
    % Create x and y values of rectangles
    xx = scaling.min + ((1:gridSize)-1)*dxy/gridSize;
    yy = scaling.max - (1:gridSize)*dxy/gridSize;
    
    rectPositions_X = [repmat(xx, 2, gridSize); repmat(xx, 2, gridSize)+dxy/gridSize];
    rectPositions_Y = [repelem(yy, gridSize); repelem(yy+dxy/gridSize, gridSize); repelem(yy+dxy/gridSize, gridSize); repelem(yy, gridSize)];

    rect = patch(rectPositions_X, rectPositions_Y, 'w', 'EdgeColor', [0.6 0.6 0.6], 'LineWidth', 2);

    set(gca, 'color', '[0.85 0.85 0.85]')
    xticks([]);    yticks([])
    set(gcf, 'Position', pos)

end