% Trimming and saving everything into data_all struct
scaling = 1;

C_aug = C * scaling;
synergies_aug = synergies * scaling;
for session = 1:8
    for trial = 1:60
        q_data = data(session, trial).q / scaling;
        x_data = C_aug * q_data - p0;

        % Removing zero handposes data
        zerok = find(all(q_data == 0, 1));
        for k = zerok
            q_data(:, k) = q_data(:, k+1);
            x_data(:, k) = x_data(:, k+1);
        end

        % Trimming to start from movement start
        startk = 1;%data(session, trial).startk;
        q_data = q_data(:, startk:end);
        x_data = x_data(:, startk:end);

        % Removing jumps in data
        trial_x = x_data(1, :);
        trial_y = x_data(2, :);

        threshold = 2;
        traj = [trial_x; trial_y];

        for i = 1:size(trial_x, 2)-2
            if norm(traj(:, i) - traj(:, i+1)) > norm(traj(:,i) - traj(:,i+2)) + threshold
                trial_x(1, i+1) = (trial_x(1,i) + trial_x(1,i+2))/2;
                trial_y(1, i+1) = (trial_y(1,i) + trial_y(1,i+2))/2;

                q_data(:,i+1) = (q_data(:,i) + q_data(:,i+2))/2;
            end
        end

        data_all(session, trial).x       = [trial_x; trial_y];
        data_all(session, trial).q       = q_data;
        data_all(session, trial).endPt   = data(session, trial).endPt;
        data_all(session, trial).startPt = data(session, trial).startPt;
        data_all(session, trial).time    = [0:0.01:(data(session, trial).endk-startk)*0.01]';
        data_all(session, trial).endk    = data(session, trial).endk;
        if env_args.policy == ['mpc']
            data_all(session, trial).W_hat = data(session, trial).W_hat;
        end
    end
end

%%
close all;

for session = 1:8
    figure;
    for trial = 1:60
        startk = data(session, trial).startk;
        plot(data_all(session, trial).x(1, startk:end), data_all(session, trial).x(2, startk:end), 'blue');
        hold on;
    end
    hold off;
    axis([-1 6 -1 6])
end


%%
data_save.data_all = data_all;
data_save.C = C_aug;
data_save.Phi = synergies_aug;
data_save.ep_ball = trialMoveDist;
data_save.targetSet = targetSet';

save data_044.mat data_save