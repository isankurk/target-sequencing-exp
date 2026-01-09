function [endPt_idx, What_est, pf_obj] = nextTargetSeqMPCRLpf(env_args, policy, sp_idx, obsStates, pf_obj, pred_horizon, RESOT_pw, trialIdx, What_est) %#codegen

rng('shuffle');

mpc_mc_reps = 5;
endPt = env_args.targetSet(:, sp_idx);      % This was actually the endPt of the trial that just finished
env_args.max_k = size(obsStates, 2);

% Terminal penalty weight
env_args.beta = 1e6;


% Running Particle Filter =============================================
for k = 1:env_args.max_k
    predict(pf_obj, endPt);
    correct(pf_obj, obsStates(:, k));
end

% Getting W_hat estimate
state_est_mpc = pf_obj.getStateEstimate;
What_est  = [state_est_mpc(3:6), state_est_mpc(7:10)]';
    
x0_curr = obsStates(1:2, end);

if policy == "mpc"  % Select end_pt by MPC %%%%%%%%%%%%%%%%%

    % Running MPC from current endPt forward to decide next target ========   
    RESOT_mpc   = RESOT_pw(1:12);

    tar_seqs    = get_sequence(pred_horizon); 
    cost_arr    = zeros(1, size(tar_seqs, 2));    
    
    % Running prediction pred_horizon steps forward
    parfor i = 1:size(tar_seqs, 2)
        tar_seq = tar_seqs(:, i);
    
        if tar_seq(1) == sp_idx
            cost_arr(i) = -inf;
            continue;
        end
    
        cost = 0;
        for rep = 1:mpc_mc_reps
    
            x_i = x0_curr;                   What_i = What_est;
            startPt_idx_i = sp_idx;         RESOT_i = RESOT_mpc;
            cum_reward = 0;

            for j = 1:pred_horizon
                endPt_idx_i = tar_seq(j);
                [x_i, What_i, RESOT_i, reward] = HML_model_trial(x_i, What_i, RESOT_i, env_args, startPt_idx_i, endPt_idx_i);
    
                if j == pred_horizon
                    cum_reward = cum_reward + env_args.beta*reward;
                else
                    cum_reward = cum_reward + reward;
                end

                startPt_idx_i = endPt_idx_i;
            end            
            cost = cost + cum_reward;
        end
        cost_arr(i) = cost_arr(i) + cost / mpc_mc_reps;
    end
    % cost_arr
    % [~, endPt_idx] = max(cost_arr);
    cost_idx = randsample(1:size(tar_seqs, 2), 1, true, my_softmax(cost_arr', 0.2));
    endPt_idx = tar_seqs(1, cost_idx);


elseif policy == "manual"  % Select endPt by manual curriculum %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if trialIdx < 13    % deterministic sequencing for first 12 trials to collect RESOT data
        endPt_idx  = env_args.manual_seq(trialIdx);
    else                % Sequencing based on worst RESOT
        RESOT_metric = RESOT_pw(1:6) + 10*RESOT_pw(7:12);

        % Starting from current idx, which tp has highest RESOT_metric
        valid_idx = env_args.action_space;      valid_idx(valid_idx == sp_idx) = [];

        % Choose random with some probability, otherwise use maual curriculum design
        if rand() < 0.2
            endPt_idx = valid_idx(randi(3));
        else
            if sp_idx == 2 || sp_idx == 3
                valid_idx(2) = valid_idx(2) + 3;
            end
            valid_tp_idx = valid_idx + sp_idx - 2;
    
            resot_idx = zeros(6,1);     resot_idx(valid_tp_idx) = 1;
    
            RESOT_metric(~resot_idx) = 0;
    
            [~, tp_idx] = max(RESOT_metric);
            tp_idx = tp_idx + 2;
    
            endPt_idx = tp_idx - sp_idx;
    
            if endPt_idx > 4
                endPt_idx = endPt_idx - 3;
            end
        end
    end


else           % Select end point randomly %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Random Selection of target point --------------------------------
    ep_index = env_args.action_space;        ep_index(ep_index == sp_idx) = [];
    endPt_idx = ep_index(randi(3));
    % endPt = env.envArgs.targetSet(:, endPt_idx);
end


% Running model with the obtained endPt to obtain W_hat for next trial
[~, What_est, ~, ~] = HML_model_trial(x0_curr, What_est, RESOT_pw(1:12), env_args, sp_idx, endPt_idx);