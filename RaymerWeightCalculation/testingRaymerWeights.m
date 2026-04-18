%% testRaymerF18.m
% Test script for calcRaymerWeights with F/A-18 example
clear; clc;

% Input struct (metric units: m, m^2, N)
input = struct();

% -----------------------------
% Basic aircraft parameters
% -----------------------------
input.Wdg    = lb2N(60000);   % Design gross weight [N] ~ 15000 kg
input.Nz     = 9;            % Ultimate load factor
input.Sw     = 37;           % Wing area [m^2]
input.AR     = 4.5;          % Wing aspect ratio
input.tc_root= 0.12;         % t/c at root
input.lambda = 0.3;          % Wing taper
input.sweep  = 45;           % Wing sweep [deg]
input.Scsw   = 2;            % Wing control-surface area [m^2]
input.K_dw   = 1;             % Wing design correction
input.K_vs   = 1;             % Wing structural factor

% Horizontal tail
input.Sht    = 10;           % Horizontal tail area [m^2]
input.F_w    = 0.2;          % F_w/B_h factor
input.B_h    = 2;             % Horizontal tail span factor

% Vertical tail
input.Svt    = 6;            % Vertical tail area [m^2]
input.K_rht  = 1;             % Correction factor
input.H_t    = 2; 
input.H_v    = 3; 
input.M      = 0.9;           % Mach factor for tail
input.L_t    = 5;            % Tail moment arm [m]
input.S_r    = 1;            % Additional area
input.A_vt   = 1.5;          % Vertical tail aspect ratio
input.lam_vt = 0.4;          % Vertical tail taper
input.sweep_vt = 40;         % Sweep [deg]

% Fuselage
input.L      = 15;           % Length [m]
input.D      = 2;            % Diameter [m]
input.W_param= 1000;         % W parameter for fuselage
input.K_dwf  = 1;             % Correction

% Landing gear
input.WNl    = 15000*9.81;   % Landing weight [N]
input.K_cb   = 1; 
input.K_tpg  = 1; 
input.Lm     = 2;             % Main gear length [m]
input.Ln     = 1.5;           % Nose gear length [m]
input.Nnw    = 2;             % Number of nose wheels

% Engines
input.Nen    = 2;             % Number of engines
input.T      = 77000;         % Total thrust [N] per engine ~ 77000 N
input.Wen    = 2000*9.81;     % Engine weight [N]
input.Sfw    = 1;             % Firewall area [m^2]
input.K_vg   = 1;
input.Ld     = 2;             % Intake length [m]
input.Kd     = 1;
input.Ls     = 1.5;           % Intake sub-length [m]
input.De     = 1;             % Engine diameter [m]
input.Ltp    = 2;             % Tailpipe length [m]
input.Lsh    = 1;             % Engine cooling length [m]
input.Te     = 500;           % Starter pneumatic param

% Fuel system
input.Vt     = 3;             % Total fuel volume [m^3]
input.Vi     = 2;             % Internal volume [m^3]
input.Vp     = 1;             % External volume [m^3]
input.Nt     = 2;             % Number of tanks
input.SFC    = 0.8;           % Specific fuel consumption

% Flight controls, instruments, crew
input.Mach   = 0.9;
input.Scs    = 5; 
input.Ns     = 4; 
input.Nc     = 1; 
input.Nu     = 3; 
input.K_vsh  = 1; 
input.K_mc   = 1; 
input.R_kva  = 50; 
input.Ngen   = 2; 
input.La     = 1; 
input.W_uav  = 100; 
input.Nci    = 1; 
input.Lec    = 1;

% -----------------------------
% Call Raymer weight function (metric)
% -----------------------------
output = calcRaymerWeights(input);

% -----------------------------
% Display results
% -----------------------------
disp('Raymer component weights for F/A-18 (approximate, N):');
disp(output);

% Optional: sum total weight
total_weight = sum(struct2array(output));
fprintf('Total estimated weight: %.2f N (%.3g lb)\n', total_weight, N2lb(total_weight));
