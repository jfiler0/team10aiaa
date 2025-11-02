% function [obj, S, T] = planeEval(W0, Lambda_LE, Lambda_TE, c_avg, span, mission_set, engine, W_F, W_P)
clear; clc;

% W0, Lambda_LE, Lambda_TE, c_avg, tr, mission_set, engine, W_F, W_P

f18 = planeObj("FA18", 28000 * 9.805, 29.3, 0, 5.02, 0.374, [], "F404", lb2N(1000), lb2N(2000));
% f18.buildPolars()
f18.buildPerformance()