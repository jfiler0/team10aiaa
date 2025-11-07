%% Build atmo table
% build_atmosphere_lookup(-100, ft2m(120000), 250);
%% Rest of the script

% function [obj, S, T] = planeEval(W0, Lambda_LE, Lambda_TE, c_avg, span, mission_set, engine, W_F, W_P)
matlabSetup();

% W0, Lambda_LE, Lambda_TE, c_avg, tr, mission_set, engine, W_F, W_P

f18 = planeObj("FA18", lb2N(60000), 29.3, 0, 5.02, 0.374, 2, [], "F414", lb2N(1000), lb2N(2000));
% f18.buildPolars()
f18.buildPerformance(1)
% f18.buildEngineMap(1)