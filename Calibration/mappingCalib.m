function [C, p0, synergies, scalingPlot, varargout] = mappingCalib(handPoseCalib, C_syn_idx)

    % Obtaining the mapping matrix and offset from calib data using PCA
    meanPose = sum(handPoseCalib)/size(handPoseCalib, 1);
    meanPoseX = repmat(meanPose, size(handPoseCalib, 1), 1);
    handPoseCen = handPoseCalib - meanPoseX;

    [handPosePC, ~, latent] = pca(handPoseCen); 

    C_unscaled = handPosePC(:, C_syn_idx);     C_unscaled = C_unscaled';
    syn_tmp = handPosePC(:, 1:4);   synergies = syn_tmp';   

    % Scaling C_unscaled to get a [0,5] x [0,5] gaming window
    sp = C_unscaled * handPoseCalib';   % Getting unscaled sceenpoints corresponding to calib hand poses

    % mean_sp = mean(sp, 2);
    % std_sp = std(sp, 0, 2);
    % x_max_sp = mean_sp(1) + 1.5*std_sp(1);
    % y_max_sp = mean_sp(2) + 1.5*std_sp(2);
    % x_min_sp = mean_sp(1) - 1.5*std_sp(1);
    % y_min_sp = mean_sp(2) - 1.5*std_sp(2);

    x_min_sp = min(sp(1,:));    x_max_sp = max(sp(1,:));
    y_min_sp = min(sp(2,:));    y_max_sp = max(sp(2,:));

    % Scaling for a max width of 6 (5+1) between extreme points
    C = 6*[C_unscaled(1,:)/(x_max_sp-x_min_sp); C_unscaled(2,:)/(y_max_sp-y_min_sp)];       

    sp_new = C * handPoseCalib';
    p0 = [min(sp_new(1,:)); min(sp_new(2,:))];      % Shifting for min at 0 and max at 5


    % % Dr. Rajiv way of designing C
    % [l,s,~] = pca(handPoseCalib);
    % 
    % [~,~,latent] = pca(s);
    % scaling = sqrt(latent);
    % 
    % % Phi = -[l(:,1)'/scaling(1)*2.5; l(:,2)'/scaling(2)*2.5; l(:,3)'/scaling(3)*2.5; l(:,4)'/scaling(4)*2.5];
    % 
    % for i = 1:size(l,2)
    %     synergies(i,:) = -(180/pi)*l(:,i)'/scaling(i)*2.5;
    % end
    % 
    % C    = synergies(C_syn_idx, :);
    % p0   = -C * mean(handPoseCalib)' + [2.5;2.5];



    screenPoints = C * handPoseCalib' - p0;

    % Window scaling parameters - Stat Comp (1 std)
    meanSP = mean(screenPoints, 2);
    stdSP = std(screenPoints, 0, 2);
    x_max = meanSP(1) + 1*stdSP(1);
    y_max = meanSP(2) + 1*stdSP(2);
    x_min = meanSP(1) - 1*stdSP(1);
    y_min = meanSP(2) - 1*stdSP(2);
    scalingPlot.max   = min([x_max, y_max]);
    scalingPlot.min   = max([x_min, y_min]);

    varargout{1} = latent;
end