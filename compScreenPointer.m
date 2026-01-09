function [handPoseRun, k, screenPointer, screenPointerDisp, currHandPose] = compScreenPointer(filePlot, k, handPoseRun, model_args, p0, scaling)

% try-catch to prevent reading an empty csv file
try
    % currHandPose = csvread(filePlot);
    currHandPose = str2num(fileread(filePlot));
%             currHandPose = handPoseRun(k, :);
    handPoseRun(k, :) = currHandPose;
    k = k+1;
catch
    % Assign last valid pose since there is no data in the .csv file
    % Another try-catch if no data on the first run
    if k-1 > 0
        currHandPose = handPoseRun(k-1, :);
    else
        currHandPose = zeros(1, model_args.joint_dim);
        handPoseRun(k, :) = currHandPose;
        k = k+1;
    end
end


% Compute the display point
screenPointer = model_args.C * (currHandPose') - p0;
screenPointer = screenPointer';

screenPointerDisp = screenPointer;

% Dealing with out of bounds
if screenPointerDisp(1) > scaling.max
    screenPointerDisp(1) = scaling.max;
elseif screenPointerDisp(1) < scaling.min
    screenPointerDisp(1) = scaling.min;
end

if screenPointerDisp(2) > scaling.max
    screenPointerDisp(2) = scaling.max;
elseif screenPointerDisp(2) < scaling.min
    screenPointerDisp(2) = scaling.min;
end

end