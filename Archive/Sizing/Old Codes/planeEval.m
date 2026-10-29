% Inputs

function [obj, S, T] = planeEval(W0, Lambda_LE, Lambda_TE, c_avg, tr, mission_set, engine, W_F, W_P)

% Assign a W0, will penalize if it cannot complete missions
% Lambda_LE, Lambda_TE (deg)
% tr - taper ratio
% c_avg
% mission_set (array of flightSegment objects)
% engine (string)
% W_F - fixed weight (like avionics)
% W_P - payload weight (extra weight that can be removed)
% *Maybe something to do with the tail. Otherwise for now just apply some correction for full body lift

% Repaced span with tr so you can't make illegal wings

%% To-Do / Notes
% tr needs to be constrained to keep wings healthy. Lambda_TE must be less than Lambda_LE (and both must be positive)

%% Fill in wing geometry variables

c_t = 2*c_avg / (1 + 1 / tr);
c_r = c_t / tr;
span = 2*(c_r - c_avg) / ( tand(Lambda_LE) - tand(Lambda_TE) );
AR = span / c_avg;

S_wing = span*c_avg;
S_ref = S_wing; % Typical defenition for reference area

Lambda_qc = atand(tand(Lambda_LE) - ( 1 - tr)/(AR*(1+tr))); % Compute the quarter-chord sweep angle (deg) - HW4

%% Assign Foil Parameters (can make input later)
a0 = -1; % deg
cl_alpha = 0.1; % foil lift sope
tc = 0.04; % airfoil thickness

%% Parasite Drag CD0

% Historical regression for S_wet from HW4 (Parasite drag due to friction)
c = -0.1289; d = 0.7506;
S_wet = 10^c  * W0^d; %ft^2
Cf = 0.0035; % For fighters?
CD_min = Cf * S_wet/S_ref;

% Induced Drag Polar
e_notoswald = 2/(2 - AR + sqrt(4 + AR^2 * (1 + (tand(Lambda_LE))^2))); % Lambda_LE, not Lmabda_max
e_osw = (4.61 * (1-0.045*AR^0.68)) * cosd(Lambda_LE)^0.15 - 3.1; %MUST USE RAYMER 12.50

%CL_alpha - for the wing?
CL_alpha = cl_alpha/(1 + 57.3 * cl_alpha/(pi * e_notoswald * AR));

% CL_min_D
CL_min_D = CL_alpha*-a0/2;

% Can reuse these later
k1_sub = 1 / (pi * e_osw* AR);
k2_sub = -2 * k1_sub * CL_min_D;

% CD_0
CD0 = CD_min + k1_sub*CL_min_D^2 + k2_sub*CL_min_D; % Actuall has k2 term

%% Wave Drag (A_max, A0, E_WD,)

% Parameters from HW4 that need to become inputs - can we estimate required volume?
L_fuselage = 48.30; %ft
A_max = 25.11; %ft^2
A_0 = 0.0; %ft^2
E_WD = 2.2; 

M_Crit = 1.0 - 0.065*(cosd(Lambda_LE))^0.6 * (100*tc)^0.6; % Critical Mach Number
M_CD0_max = 1/(cosd(Lambda_LE))^0.2; % I assume this is a regression
CD_wave = @(M) 4.5 * pi / S_ref * ((A_max - A_0)/L_fuselage)^2 * E_WD * (0.74 + 0.37 * cosd(Lambda_LE)) * (1 - 0.3*sqrt(M - M_CD0_max));

% CD_wave(1.5)

% Calculate c_root, c_tip, S_wing, e_os
% Calculate W0 inside
% Check fuel burn and penalize if not big enough
% Penalize for not hitting performance constraints

obj = 0;
W0 = 0;
S = 0;
T = 0;
end