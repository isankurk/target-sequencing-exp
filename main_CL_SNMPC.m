clc;    clearvars -except C p0 synergies scaling targetSet trialMoveDist rectIndex dx dy dxy data; 
close all;
addpath(genpath(pwd));

rng('shuffle');
waitfor(TSexp_GUI);
% load acAgentLfaResot_001.mat acAgentLfa_resot

% Load environment (HML model)
env_args = get_HML_args();
mpc_pred_horizon = MPC_predHorizon;

% Policy to use: options - rand, mpc, rl
env_args.policy = convertCharsToStrings(policy);
env_args.params = str2num(HMLparams);

% Filtered derivative system tf
num = num2cell(eye(env_args.joint_dim));
num(logical(eye(env_args.joint_dim))) = {[1, 0]};
fil_der_sys = tf(num, [0.01, 10]);

if env_args.policy == "mpc" && isempty(gcp('nocreate'))
    parpool;
end

if env_args.policy == "rl"
    rlAgent = rlSaveFile.acAgentLfa_resot;
else
    rlAgent = [];
end


% Subject Information
subjectName   = subjectID;
fileName      = sprintf('subject_%s', subjectName);

filenameTrial = sprintf('subjectTrial_%s', subjectName);

% Creating and managing directories and files
if ~exist("/SubjectData", 'dir')
       mkdir("./SubjectData")
end
fileGlovePose = 'DaqCpp/record/pose.csv';

% Position of display window
plotPos = [3043         -3         994         994];
% plotPos = [460, 0, 1000, 1000];    % Center of the current 1080p screen (or 460 pixel from L, 0 from D)

% Rectangle Colors
rect_red   = [1.0, 0.4, 0.4];
rect_green = [0.4, 1.0, 0.4];
rect_gray  = [0.6, 0.6, 0.6];

% Gridsze and corresponding targetSet (numbered 1:gridSize), L2R, UppL-to-LowR
gridSize = 5;
targetSetIdx = [1, 13, 23, 5];

% Experimental Parameters and Flags
calibFlag = calibrationFlag;    calibSigns  = 33; 
familFlag = familiarizationFlag;
trialFlag = runTrialFlag;

firstTrial = true;
stopped    = false;
endPt_idx = 1;
   
% Time parameters for loops & stopping cond.
trialTimeFlag   = true;
trialTimeSec    = 10000;
familTimeSec    = 10;

capStay       = 20;
stopThreshold = 0.7;
ballisticTime = 2.0; %in s

capturedFlag    = false;

% Initializing data arrays
handPoseRun     = zeros(5000, env_args.joint_dim);
RESOT_pw = zeros(12,1);
W_hat_prev = 0.0001* [zeros(2,env_args.syn-2), eye(2)];


sessions = 8;
trials   = 60;


tictoc_trial = [];

i=1;    k=1;    trialNum = 1;   sessionNum = 1;

%%%%%%%%%%%%%%%%%%%%%%%%% Calibration Phase %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if calibFlag == true
    [C, p0, synergies, scaling, targetSet, rectIndex, dxy, calibFlag] = runCalibration_ASL(gridSize, targetSetIdx, calibSigns, subjectName, env_args.joint_dim, plotPos, C_syn_idx);
end
env_args.C              = C;
env_args.phi            = synergies;
env_args.w_orig         = C * pinv(synergies);
env_args.targetSet      = targetSet';

trialMoveDist           = 0.2 * dxy/gridSize; % 20% of the block size as the movement start radius
env_args.action_space   = [1,2,3,4];
env_args.ep_ball        = trialMoveDist;

%%%%%%%%%%%%%%%%%%%%%%%% Familiarization Phase %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if familFlag == true

    fprintf('Press any key to start the familiarization phase:\n')
    pause
    familStart = tic;
    while true
        % try-catch to prevent reading an empty csv file
        try
            currHandPose = str2num(fileread(fileGlovePose));
            handPoseRun(i, :) = currHandPose;
            i = i+1;
        catch
            % Assign last valid pose since there is no data in the .csv file
            % Another try-catch if no data on the first run
            try
                currHandPose = handPoseRun(i-1, :);
            catch
                currHandPose = zeros(1, env_args.joint_dim);
            end
        end

        % Compute the display point
        screenPointer = C * currHandPose' - p0;   % Both C and currHandPose are unscaled
        screenPointer = screenPointer';
        % screenPointerData(i, :) = screenPointer;

        % Dealing with out of bounds
        if screenPointer(1) > scaling.max
            screenPointer(1) = scaling.max;
        elseif screenPointer(1) < scaling.min
            screenPointer(1) = scaling.min;
        end
        
        if screenPointer(2) > scaling.max
            screenPointer(2) = scaling.max;
        elseif screenPointer(2) < scaling.min
            screenPointer(2) = scaling.min;
        end


        % Real time plot of screen pointer
        plot(screenPointer(1), screenPointer(2), '.k', 'MarkerSize', 20);
        hold on;
        plotFamilRect(gridSize, scaling, dxy, plotPos)
        hold off;
        drawnow;

        familElapsed = toc(familStart);
        if familElapsed > familTimeSec,     break;  end
    end
    close all;
    familFlag   = false;
    handPoseRun = zeros(5000, env_args.joint_dim);
    fprintf('Familiriaziation Phase ends.\nPress any key to start the trials:\n')
    pause;
end


%%%%%%%%%%%%%%%%%%%%%%%%%% Trial Run Phase %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initializing the Particle Filter ========================================
pf_obj = particleFilter_init(env_args);


while trialFlag
    
    % Timing trial
    trial_tt = tic;

    % Collect hand Data and compute screen Pointer
    [handPoseRun, k, screenPointer, screenPointerDisp, ~] = compScreenPointer(fileGlovePose, k, handPoseRun, env_args, p0, scaling);
    screenPointerData(k, :) = screenPointer;


    % Trial 1 jobs
    if trialNum == 1 && firstTrial
        firstTrial  = false;
        trialNum    = 0;  % disregarding the first trial
        startPt_idx = endPt_idx;
        endPt_idx   = 2;
        startPt     = targetSet(startPt_idx, :);
        endPt       = targetSet(endPt_idx, :);
        capScore    = 0;    capCounter = 0;           capScoreCum = 0;
    end

    % Calculate movement, and trial start
    if trialTimeFlag && norm(screenPointer - startPt) > trialMoveDist
        trialStart = tic;   trialTimeFlag = false; ballisticFlag = true;
        trialStartIdx = k-1;
        pointerState = 'ballistic';
    elseif trialTimeFlag
        pointerState = 'atStart';  ballisticFlag = false;
    end

    % Initialize plot with the end point
    if strcmpi(pointerState, "ballistic") || strcmpi(pointerState, "atStart")
        plot(endPt(1), endPt(2), 'xr', 'MarkerSize', 20, 'LineWidth', 2)
    else
        plot(endPt(1), endPt(2), 'xb', 'MarkerSize', 10, 'LineWidth', 2)
    end
    % Real time plot of grid squares
    rect = plotTrialRect(gridSize, scaling, capScore, capScoreCum, dxy, pointerState, trialNum, sessionNum, plotPos);
    hold on;

    
    if ~trialTimeFlag               % When trial starts after the participant starts moving

        % Persistent display of screen pointer at the end of ballistic phase
        if ~(strcmpi(pointerState, "ballistic") && strcmpi(pointerState, "atStart")) && exist("screenPointerEnd", 'var')
            plot(screenPointerEnd(1), screenPointerEnd(2), '.black', 'MarkerSize', 20)
        end

        % Finding rectangle corresponding to endPt
        endRectIdx = targetSetIdx(endPt_idx);
        endRect_X  = rect.XData(:, endRectIdx);
        endRect_Y  = rect.YData(:, endRectIdx);

        % [xEnd, yEnd] = find(rectIndex==targetSetIdx(endPtIndex));
        % endRect = rect(xEnd, yEnd);
        % pos = endRect.Position;
        % xv = [pos(1), pos(1)+pos(3), pos(1)+pos(3), pos(1), pos(1)];    yv = [pos(2), pos(2), pos(2)+pos(4), pos(2)+pos(4), pos(2)];

        % Calculating index at ---- BALLISTIC PHASE ---- end (use this index later in analysis)
        if toc(trialStart) > ballisticTime && ballisticFlag
            ballisticEndIdx = k-1;  ballisticFlag = false;
            screenPointerEnd = screenPointer;

            second_exit_flag = true;

            if inpolygon(screenPointer(1), screenPointer(2), endRect_X, endRect_Y)
                capturedFlag = true;
            else
                capturedFlag = false;
            end
        end

        % Captured flag false if exit the target square after ballistic period
        if toc(trialStart) > ballisticTime && second_exit_flag && ~inpolygon(screenPointer(1), screenPointer(2), endRect_X, endRect_Y)
            capturedFlag = false;
            second_exit_flag = false;
        end

        % Coloring the end rectangle green if captured in ballistic, red if not, and gray if moving
        if (~ballisticFlag && capturedFlag) || (ballisticFlag && strcmpi(pointerState, 'hovering'))
            endRect_color = rect_green;
        elseif ~ballisticFlag && ~capturedFlag
            endRect_color = rect_red;
        else
            endRect_color = rect_gray;
        end
        patch(endRect_X, endRect_Y, endRect_color);

        % Checking hovering
        if (inpolygon(screenPointer(1), screenPointer(2), endRect_X, endRect_Y))
            pointerState = 'hovering';
            plotCapCircle(endPt, trialMoveDist);
        elseif ~ballisticFlag && ~trialTimeFlag  % basically to check if the trial (timing) has started; no conflicts with ballistic or atStart
            pointerState = 'moving';
        end


        % Pointer Stop Check in desired target circle
        if strcmpi(pointerState, 'hovering')
            % If static in capture circle, scaling screenpointer with dx and dy to check in circle and not ellipse
            if ( norm(screenPointerData(k, :) - screenPointerData(k-1, :)) < dxy*stopThreshold/100 ) && norm(screenPointer  - endPt) < trialMoveDist
                capCounter = capCounter + 1;
                if capCounter == capStay
                    stopped = true;
                    trialEndIdx = k-1;
                    % endRect.FaceColor = [0.4, 0.4, 0.4];
                end
            else
                capCounter = 0;
            end
        end

    end

    if strcmpi(pointerState, "ballistic") || strcmpi(pointerState, "atStart")
        plot(endPt(1), endPt(2), 'xr', 'MarkerSize', 20, 'LineWidth', 5)
    else
        plot(endPt(1), endPt(2), 'xb', 'MarkerSize', 10, 'LineWidth', 2)
    end        
    plot(screenPointerDisp(1), screenPointerDisp(2), '.k', 'MarkerSize', 20)
    hold off;
    drawnow;

    % Trial End Jobs ------------------------------------ 
    if exist("trialStart", 'var')
        if toc(trialStart) > trialTimeSec || stopped
            
            % Trimming data
            handPoseRun = handPoseRun(1:k-1, :);
            screenPointerData = screenPointerData(2:k, :);

            %Calculating score
            stopped = false;
            SOT = trajStraightness(screenPointerData', startPt, endPt);
            capScore = 100 - (norm(screenPointerData(end, :) - endPt) * 5 * sqrt(2) /dxy ) - 2*(trialEndIdx-trialStartIdx)*0.01 - 50 * SOT - 10*~capturedFlag;
            if capScore < 0 || isnan(capScore),    capScore = 0;   end    
            capScoreCum = capScoreCum + capScore;

            % Saving data
            if trialNum > 0
                data(sessionNum, trialNum).x          = screenPointerData';
                data(sessionNum, trialNum).q          = handPoseRun';
                data(sessionNum, trialNum).startPt    = startPt';
                data(sessionNum, trialNum).endPt      = endPt';
                data(sessionNum, trialNum).capScore   = capScore; 
                data(sessionNum, trialNum).startk     = trialStartIdx;
                data(sessionNum, trialNum).ballistick = ballisticEndIdx;
                data(sessionNum, trialNum).endk       = trialEndIdx;
            end
            
            
            % MPC Target sequencing: Getting next target %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            % Prepping data for PF ----------------------------------------
            % Obtaining q_dot data from q (handPoseRun)
            time_vec = 0:0.01:(k-2)*0.01;
            qdot_obs_full = lsim(fil_der_sys, handPoseRun, time_vec)';
            qdot_obs = [qdot_obs_full(:,2), qdot_obs_full(:, 2:end)];

            obsStates = [screenPointerData';
                         qdot_obs];

            % Compute RE and SOT for MPC and RL agent ---------------------
            trialIdx = (sessionNum-1) * 60 + trialNum + 1;
            if trialNum > 0
                reEvalt = min(ballisticEndIdx, size(screenPointerData, 1));
                currRE  = norm(screenPointerData(reEvalt, :) - endPt);
    
                currSOT = trajStraightness(screenPointerData', startPt', endPt');
    
                if (startPt_idx == 2 && endPt_idx == 3) || (startPt_idx == 3 && endPt_idx == 2)
                    targetPairIdx = 6;
                else
                    targetPairIdx = startPt_idx + endPt_idx - 2;
                end
    
                RESOT_pw(targetPairIdx)     = (RESOT_pw(targetPairIdx) + currRE)/2;
                RESOT_pw(6+targetPairIdx)   = (RESOT_pw(6+targetPairIdx) + currSOT)/2;
            end

            ts_policy = env_args.policy;

            % Computing next endPt starting from current endPt(startPt for next trial)
            startPt_idx = endPt_idx;
            [endPt_idx, W_hat, pf_obj] = nextTargetSeqMPCRLpf(env_args, ts_policy, startPt_idx, obsStates, pf_obj, mpc_pred_horizon, RESOT_pw, trialIdx, W_hat_prev);

            if trialNum > 0
                data(sessionNum, trialNum).W_hat = W_hat;
                W_hat_prev = W_hat;
            end

            startPt = targetSet(startPt_idx, :);
            endPt   = targetSet(endPt_idx, :);

            fprintf('Trial %d ends\n', trialNum)
            trialNum = trialNum + 1;
            k = 1;
            handPoseRun = zeros(5000, env_args.joint_dim);
            trialTimeFlag = true;
            capturedFlag  = false;
            clearvars screenPointerEnd W_hat
            fprintf('Continuing to next trial!\n')

            % if env_args.policy == ['rand']    % MPC already pauses for long enough during next Target Selection
            %     pause(0.5);
            % end
        end
    end
    
    
    % Session End Jobs ------------------------------------------------
    if trialNum == trials + 1
        fprintf('Session %d ends\n', sessionNum)
        sessionNum = sessionNum + 1;
        trialNum = 1;
        firstTrial = true;
        cd SubjectData
        save(filenameTrial)
        cd ../
    end

    % End 
    if sessionNum == sessions + 1,     break;  end

    tictoc_trial(end+1) = toc(trial_tt);
end

cd SubjectData
save(fileName)
cd ../


%{ 
Changes
1. Implement traj straightness in scores! - DONE!
%}
