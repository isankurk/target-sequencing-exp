function pf_obj = particleFilter_init(env_args)

    % STATE_DIM = 2+8+21*3;
    OBSV_DIM  = 2+env_args.joint_dim;
    
    What0 = 0.0001* [zeros(2,env_args.syn-2), eye(2)];
    
    % Initializing process and meas noise
    Q = 0.001 * diag([0.01*ones(1,2), 0.01*ones(1,8), sqrt(env_args.dt)*env_args.params(6)*ones(1, env_args.joint_dim), sqrt(env_args.dt)*env_args.params(5)*ones(1, env_args.joint_dim), 0.01*ones(1, env_args.joint_dim)]);
    R = 0.1 * eye(OBSV_DIM);
    
    % % Filtered derivative system tf
    % num = num2cell(eye(19));
    % num(logical(eye(19))) = {[1, 0]};
    % fil_der_sys = tf(num, [0.01, 10]);
    
    numParticles = 1000;
    
    % State transition and measurement functions
    % state = [x, W_hat1, W_hat2, delta_q, u, q]
    stateTransitionFcn = @(state, endPt)stateEvalPF_mex(state, endPt, env_args.dt, [env_args.params, env_args.a], env_args.w_orig, env_args.phi);
    measurementFcn     = @(state, observations)obsEvalPF(state, observations, R);
    
    q0 = 0.1 * ones(env_args.joint_dim, 1);
    initialState = [env_args.C*q0; What0(1,:)'; What0(2,:)'; zeros(env_args.joint_dim,1); zeros(env_args.joint_dim,1); q0];
    covarianceX0 = Q;        % Informative prior
    
    % Particle Filter for rand player --------------------------
    pf_obj = particleFilter(stateTransitionFcn, measurementFcn);
    initialize(pf_obj, numParticles, initialState, covarianceX0);  %DO THIS WHEN GAME STARTS 
    
    % Setting particle filter parameters
    pf_obj.StateEstimationMethod = 'mean';
    pf_obj.ResamplingMethod      = 'systematic';

end