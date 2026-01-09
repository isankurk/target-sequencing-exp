function [likelihood] = obsEvalPF(predictedParticles, observations, R) %#codegen

% This is measurement function for simulation data where we observe x and q_dot
joint_dim = size(R, 1) - 2;
state_dim = size(predictedParticles, 1);

Jh1 = [1, zeros(1, state_dim-1);
       0, 1, zeros(1, state_dim-2)];
Jh2 = [zeros(joint_dim, 10+joint_dim), eye(joint_dim), zeros(joint_dim, joint_dim)];
Jh = [Jh1; Jh2];

predObsv = Jh * predictedParticles;

measErr = predObsv - observations;

measErrProd = dot(measErr, R \ measErr, 1);

likelihood = 1/sqrt((2*pi).^size(R,1) * det(R)) * exp(-0.5 * measErrProd);

end