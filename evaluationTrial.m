function [screenPointerData, handPoseRun, evalError] = evaluationTrial(gridSize, scaling, dx, dy, dxy, plotPos, evalW, figPts, filePlot, handPoseRun, modelParams, C, p0, stopThreshold, capStay, rectIndex, evalTimeSec)

%%% Evaluation trial function
% wSquares = zeros(length(figPts), 1);
endPtIndex = figPts(1);
capCounter = 0;
pointerState = 'moving';
stopped = false;
k=1;
i = 1;
evalTimeFlag = 0;
close all;
% evalError = zeros(200, 1);

fprintf('Press any key to start the evaluation trial!\n')
pause;

while true
    
    % Sequential assignment of endpoints from evalW
    if strcmpi(pointerState, 'hovering') && i < length(figPts)
        i = i+1;
        endPtIndex = figPts(i);
    end

    [handPoseRun, k, screenPointer, ~] = compScreenPointer(filePlot, k, handPoseRun, modelParams, C, p0, scaling);
    screenPointerData(k, :) = screenPointer;

    if ~evalTimeFlag && i > 1,      evalStart = tic;   evalTimeFlag = 1;    end  % Starting eval time

    % Calculating error as distance from W segment currently active
    if endPtIndex == figPts(i) && i>1
        evalError(k) = point_to_line(screenPointer, evalW(i-1,:), evalW(i,:));
    else
        evalError(k) = 0;
    end

    % Calculating elapsed time
    if i>1, evalElapsed = evalTimeSec-toc(evalStart);
    else, evalElapsed = evalTimeSec; end

    % Plot eval grid
    plot(0,0, '.', 'color', '[0.85 0.85 0.85]');    
    rect = plotEvalRect(gridSize, scaling, evalError(k), dx, dy, plotPos, evalElapsed);
    hold on;

    % Pointer Hover Check
    [xEnd, yEnd] = find(rectIndex==endPtIndex);
    endRect = rect(xEnd, yEnd);
    pos = endRect.Position;
    xv = [pos(1), pos(1)+pos(3), pos(1)+pos(3), pos(1), pos(1)];    yv = [pos(2), pos(2), pos(2)+pos(4), pos(2)+pos(4), pos(2)];
    if (inpolygon(screenPointer(1), screenPointer(2), xv, yv))
        pointerState = 'hovering';
        endRect.FaceColor = [0, 1, 0];
    else
        pointerState = 'moving';
        endRect.FaceColor = [1, 0, 0];
    end

    if i==length(figPts) && strcmpi(pointerState, 'hovering')
        % Pointer Stop Check in desired Square
        if k > 2
            if norm(screenPointerData(k, :) - screenPointerData(k-1, :)) < dxy*stopThreshold/100
                capCounter = capCounter + 1;
                if capCounter == capStay
                    stopped = true;
                    pointerState = 'stopped';
                end
            else
                capCounter = 0;
            end
        end
    end

    % Plot fig and screen pointer
    if i>1,    plot(evalW(:, 1)', evalW(:, 2)', 'yellow', 'LineWidth', 20); end
    plot(screenPointer(1), screenPointer(2), '.k', 'MarkerSize', 20)
%     hold off;
    drawnow;
    hold off;

    if i>1 %&& exist('evalStart','var')
        if stopped || toc(evalStart) > evalTimeSec, break; end
    end

end

fprintf('Evaluation ends! Press any key to resume the training!\n')
pause;
end