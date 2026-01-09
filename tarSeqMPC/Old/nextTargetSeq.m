function [endPt_idx] = nextTargetSeq(env, sp_idx, policy, varargin) %#codegen

% arguments
%     env (1,1) struct
%     sp_idx (1,1) int8
%     policy string
% end

rng('shuffle');

if strcmp(policy, 'mpc')                % Select end_pt by pred_horizon-MPC
    pred_horizon = varargin{1};
    C_hat = varargin{2};
    mpc_params = varargin{3};
    mpc_mc_reps = 5;
    mpc_w = mpc_params.w;


    % Computing W_hat from the C_hat estimate
    W_hat = C_hat * pinv(env.envArgs.syn);
    
    % MPC based target selection ---------------------------------------------    
    cost_arr = zeros(1, env.action_space_size);  
    
    % Generating target sequence
    tar_seqs = genTargetSeq(env.action_space, sp_idx, pred_horizon);
    
    % Running prediction pred_horizon steps forward --------------
    for tar_seq = tar_seqs'             % Transpose because MATLAB for-loop goes column-wise
    
        cost = 0;
        for rep = 1:mpc_mc_reps
            start_pt_i = env.envArgs.targetSet(:, tar_seq(1));
            state_i = [start_pt_i; W_hat(1,:)'; W_hat(2,:)'];
            
            % Predicting pred_horizon steps forward
            cum_reward = 0;
            next_ep = tar_seq(2);
            for action = tar_seq(2:end)'                    % First point is the start point in tar_seq
                end_pt_i = env.envArgs.targetSet(:, action);
                [next_state_i, ~, reward_i, ~] = env.step(end_pt_i, start_pt_i, false, state_i);
    
                % Calculating perf and learning metrics for MPC cost function
                err_w   = -reward_i;
                % re      = calculateRE(state_dict_i.x, end_pt_i, env_args.dt, 2);
                % sot     = trajStraightness(state_dict_i.x, start_pt_i, end_pt_i);
                % cot     = calculateCurvature(state_dict_i.x);
    
                costFun_i = mpc_w * err_w; % + mpc_w.re * re + mpc_w.sot * sot + mpc_w.cot * cot;
                cum_reward = cum_reward + costFun_i;
    
                % Prepping for next iteration
                state_i = next_state_i;      start_pt_i = end_pt_i;
            end
            
            cost = cost + cum_reward;
        end
        cost_arr(next_ep) = cost_arr(tar_seq(1)) + cost / mpc_mc_reps;
    end

    if strcmp(mpc_params.maxmin, 'min')
        cost_arr(sp_idx) = inf;                 % To avoid selecting the same point
        [~, endPt_idx] = min(cost_arr);
    elseif strcmp(mpc_params.maxmin, 'max')
        cost_arr(sp_idx) = -inf;
        [~, endPt_idx] = max(cost_arr);
    else
        fprintf('Invalid optimization params %s for MPC cost function!\n Restart game...', mpc_params.maxmin);
        pause;
    end

    % endPt = env.envArgs.targetSet(:, endPt_idx);


else                                % Select end point randomly

    % Random Selection of target point --------------------------------
    ep_index = env.action_space;        ep_index(ep_index == sp_idx) = [];
    endPt_idx = ep_index(randi(3));
    % endPt = env.envArgs.targetSet(:, endPt_idx);
end