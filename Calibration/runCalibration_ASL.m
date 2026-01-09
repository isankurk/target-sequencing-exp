function [C, p0, synergies, scaling, targetSet, rectIndex, dxy, calibFlag] = runCalibration_ASL(gridSize, targetSetIdx, calibSigns, subject, joint_dim, pos, C_syn_idx)

    if calibSigns > 35, calibSigns = 35; end
    fprintf('Press any key to start calibration by ASL Alphabets!\n')
    pause;
    handPoseCalib   = zeros(calibSigns, joint_dim);

    % Collecting data for calibration
    for j = 1:calibSigns
        fprintf('Create the indicated letter and press any key\n')
        signName = sprintf('ASLAlphabet/%d.png', j);
        imshow(signName)
        set(gcf, 'Position', pos)
        pause;
        readFile = false;
        while ~readFile
        % try-catch to prevent reading an empty csv file
            try
                handPose = str2num(fileread('DaqCpp/record/pose.csv'))
    %                 handPose = handPoseCalib(j, :);
                handPoseCalib(j, :) = handPose;
                readFile = true;
            catch
            end  
        end
    end

    
    % fname_load = ['calibDataASL_', subject, '.mat'];
    % load(fname_load);

    
    % Getting mapping matrix and offset
    [C, p0, synergies, scaling] = mappingCalib(handPoseCalib, C_syn_idx);

    % Target Points
    dxy = scaling.max - scaling.min;

    rectIndex = reshape(1:gridSize^2, gridSize, gridSize)';

    targetSet = [];
    for i = targetSetIdx
        [yInd, xInd] = find(rectIndex==i);
        targetSet(end+1, :) = [scaling.min + (xInd-0.5)*dxy/gridSize,  scaling.max - (yInd-0.5)*dxy/gridSize];
    end

    calibFlag = false;    % Set the calib flag to false
    fname = ['calibDataASL_', subject];
    cd Calibration
    save(fname);  % Saving the calibration data
    cd ../
    close all;
    fprintf('Calibration phase ends.\n')
    pause;

end