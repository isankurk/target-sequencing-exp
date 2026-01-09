classdef HML_model < handle
    properties
        envArgs
        observation_space
        action_space
        action_space_size
        state_log
    end
    
    methods
        function obj = HML_model(envArgs)
            obj.envArgs = envArgs;
            obj.observation_space = randn(2 + obj.envArgs.syn * 2, 1);
            obj.action_space = [1, 2, 3, 4];
            obj.action_space_size = length(obj.action_space);
        end
        
        function state_log = reset(obj)
            % Reset function to start a new session
            % Initialize the states
            x0 = [2.5; 2.5] + 0.01 * randn(2, 1);
            w_hat0 = 0.0001 * [zeros(2, obj.envArgs.syn - 2), eye(2)];
            obj.state_log = [x0; w_hat0(1, :)'; w_hat0(2, :)'];
            
            state_log = obj.state_log;
        end

        function [next_state, state, Reward, Skip] = step(obj, endPt, startPt, progress, varargin)

            rng('shuffle');

            % Unpacking states, envArgs, and HML model params
            if progress
                state = obj.state_log;
            else
                state = varargin{1};
            end

            x       = state(1:2, 1);
            wHatVec = state(end-obj.envArgs.syn*2+1:end, 1)';
            W_hat   = [wHatVec(1, 1:obj.envArgs.syn); wHatVec(1, obj.envArgs.syn+1:end)];
            u       = zeros(obj.envArgs.joint_dim, 1);
            deltaQ  = zeros(obj.envArgs.joint_dim, 1);
        
            gamma   = obj.envArgs.params(1);
            eta     = obj.envArgs.params(2);
            mu      = obj.envArgs.params(3);
            k_p     = obj.envArgs.params(4);
            sigma_u = obj.envArgs.params(5);
            sigma_q = obj.envArgs.params(6);
            a       = obj.envArgs.a;
        
            dt = obj.envArgs.dt;
            Phi = obj.envArgs.phi;
            joint_dim = obj.envArgs.joint_dim;
            W_orig = obj.envArgs.w_orig;
        
            Skip = false;

            % Computing reward as -norm(W_tilde)
            % If action chooses endPt the same as startPt, then set a very high penalty (-ve reward)
            if isequal(startPt, endPt)
                Skip = true;
                k = -1;
                Reward = -1000;
            else % Else simulate the model forward for one trial/step
                k = 1;        
                % Trial run starts ----------------------------------------
                while norm(x(:, k) - endPt) > obj.envArgs.ep_ball
                    x(:, k+1) = x(:, k) + dt * obj.envArgs.C * u(: ,k);
                    u(:, k+1) = u(:, k) - dt * eta * ( (Phi' * (W_hat(:, :, k)' * W_hat(:, :, k) * Phi) + mu * eye(joint_dim)) * u(:, k) - k_p * Phi' * W_hat(:, :, k)' * (endPt - x(:, k))) + sqrt(dt) * sigma_u * randn(joint_dim, 1);
                    
                    deltaQ(:, k+1) = deltaQ(:, k) + dt * (-a * deltaQ(:, k) + u(:, k)) + sqrt(dt) * sigma_q * randn(joint_dim, 1);
                    W_hat(:, :, k+1) = W_hat(:, :, k) - dt * gamma * (W_hat(:, :, k) - W_orig) * Phi * (deltaQ(:, k) * deltaQ(:, k)') * Phi';
        
                    k = k + 1;
                end
                %%%%%%%----------------------------------------------------
                Reward = -norm(W_orig - W_hat(:, :, end), 2);
            end

            % Logging HML state, maxIters, and steps
            next_state = [x(:, end); W_hat(1, :, end)'; W_hat(2, :, end)'];
            if progress
                obj.state_log = next_state;
            end
        
            state = struct('x', x, 'W_hat', W_hat, 'u', u);
        end
    end
end
