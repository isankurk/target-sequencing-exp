function [x_end, What_end, RESOT_pw, reward] = HML_model_trial(x0, What0, RESOT_pw, args, startPt_idx, endPt_idx)  %#codegen

% Computing end pt, start pt, and target pair idx being operated on
startPt = args.targetSet(:, startPt_idx);
endPt   = args.targetSet(:, endPt_idx);

if (startPt_idx == 2 && endPt_idx == 3) || (startPt_idx == 3 && endPt_idx == 2)
    targetPairIdx = 6;
else
    targetPairIdx = startPt_idx + endPt_idx - 2;
end


maxSize = 1e6;
x       = zeros(2, maxSize);
W_hat   = zeros(2,4, maxSize);
u       = zeros(args.joint_dim, maxSize);
deltaQ  = zeros(args.joint_dim, maxSize);

x(:, 1)         = x0;
W_hat(:, :, 1)  = What0;

gamma   = args.params(1);
eta     = args.params(2);
mu      = args.params(3);
k_p     = args.params(4);
sigma_u = args.params(5);
sigma_q = args.params(6);
a       = args.a;

dt = args.dt;
Phi = args.phi;
joint_dim = args.joint_dim;
W_orig = args.w_orig;

k = 1;
        
% Trial run starts ----------------------------------------
while norm(x(:, k) - endPt) > args.ep_ball %&& k < args.max_k
    x(:, k+1) = x(:, k) + dt * args.C * u(: ,k);

    Ch = W_hat(:, :, k) * Phi;
    u1 = Ch' * (Ch * u(:, k));
    u(:, k+1) = u(:, k) - dt * eta * ( u1 + mu * u(:, k) - k_p * Ch' * (endPt - x(:, k)) ) + sqrt(dt) * sigma_u * randn(joint_dim, 1);
    
    deltaQ(:, k+1) = deltaQ(:, k) + dt * (-a * deltaQ(:, k) + u(:, k)) + sqrt(dt) * sigma_q * randn(joint_dim, 1);

    Phi_deltaq = Phi * deltaQ(:, k);
    W_hat(:, :, k+1) = W_hat(:, :, k) - dt * gamma * ((W_hat(:, :, k) - W_orig) * Phi_deltaq) * Phi_deltaq';

    k = k + 1;
end
%%%%%%%----------------------------------------------------
% Trimming states
x = x(:, 1:k);    W_hat = W_hat(:, :, 1:k);

x_end    = x(:, end);
What_end = W_hat(:, :, end);

W_reward   = -norm(W_orig - W_hat(:, :, end), 2);
%%%%%%%%%%%%%%%%%%%% Computing reward based on norm of RE and SOT
reEvalt = min(2/args.dt + 1, k);
currRE = norm(x(:, reEvalt) - endPt);
currSOT = trajStraightness(x, startPt, endPt);

% reward = -norm(RESOT_pw(1:6)) - norm(RESOT_pw(7:12));

% Set reward based on improvement in the current targetpair's RESOT values
% RE_reward  = RESOT_pw(targetPairIdx) - currRE;
% SOT_reward = RESOT_pw(6+targetPairIdx) - currSOT;

% Set reward based the current targetpair's RESOT values
RE_reward  = - currRE;
SOT_reward = - currSOT;

% W_reward
% RE_reward
% SOT_reward

reward = 100 * W_reward + RE_reward + 2 * SOT_reward;


RESOT_pw(targetPairIdx)   = currRE;
RESOT_pw(6+targetPairIdx) = currSOT;

end