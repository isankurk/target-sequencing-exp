function [fun] = stateEvalPF(state, xdes, d, params, W_orig, Phi) %#codegen

dim = size(Phi, 2);
numParticles = size(state, 2);

% State declaration
w1h = zeros(4,1,numParticles);    w2h = w1h;

x = state(1:2, :);
w1h(:, 1, :)  = state(3:6, :);   w2h(:, 1, :)  = state(7:10, :);
delta_q  = state(11:11+dim-1, :);      u = state(11+dim:11+2*dim-1, :);
q = state(11+2*dim:end, :);

gamma = params(1);   eta = params(2);    mu = params(3);    kp = params(4);     sigma_u = params(5);    sigma_q = params(6);    a = params(7);

fx = x + d * (W_orig * Phi* u);

Phi_deltaq = reshape(Phi * delta_q, [], 1, numParticles);
dw1 = w1h - W_orig(1, :)';
dw2 = w2h - W_orig(2, :)';

fw1 = w1h + d * -gamma .* sum(Phi_deltaq .* dw1, 1) .* Phi_deltaq;
fw2 = w2h + d * -gamma .* sum(Phi_deltaq .* dw2, 1) .* Phi_deltaq;

fdq = delta_q + d * (-a*delta_q + u) + sqrt(d) * sigma_q * randn(dim, numParticles);

Ch1t = Phi' * squeeze(w1h);
Ch2t = Phi' * squeeze(w2h);

Cht_u = Ch1t .* sum(Ch1t .* u, 1) + Ch2t .* sum(Ch2t .* u, 1);
ex = xdes - x;

fu1 = -(d* eta) .* (Cht_u + mu .* u);
fu2 = (d * eta * kp) .* (Ch1t .* ex(1,:) + Ch2t .* ex(2,:));
fu3 = sqrt(d) * sigma_u * randn(dim, numParticles);
fu = u + fu1 + fu2 + fu3;

fq  = q + d * u;

fun = [fx; squeeze(fw1); squeeze(fw2); fdq; fu; fq];

end