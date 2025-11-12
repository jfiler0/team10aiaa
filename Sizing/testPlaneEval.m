%% Build atmo table
% build_atmosphere_lookup(-5000, ft2m(120000), 500);
%% TO DO
% - Plot atmosphere
% - Read in atmosphere limits
% - Sensitivties

%% Rest of the script

% function [obj, S, T] = planeEval(W0, Lambda_LE, Lambda_TE, c_avg, span, mission_set, engine, W_F, W_P)
matlabSetup();

fixed_input.L_fuselage = 17.54; % m -> FA18 fuselage length
fixed_input.A_max = 5; % m2 -> trying to get the right FA18 wave drag
fixed_input.g_limit = 7; % G -> FA18 limit
fixed_input.max_alpha = 12; % deg -> Guess

% WE, Lambda_LE, Lambda_TE, c_avg, tr, mission_set, engine, W_F, W_P
f18 = planeObj(fixed_input, "FA18", lb2N(34000), 29.3, 0, 5.02, 0.374, 2, [], "F414", lb2N(2000), ["AIM-9X", "FPU-12", "AIM-120", "AIM-120", "FPU-12", "AIM-9X"]);
% f18.buildPolars()
% f18.buildPerformance(1)
% f18.buildEngineMap(1)
% [turn_rate, n] = f18.getMaxTurn(1000, 0.8, f18.W0, 6.5)

fprintf("The F18 has a unit cost of %.2f million dollars and a stall speed of %.2f kt", f18.calcUnitCost(), ms2kt( f18.calcStallSpeed(0, f18.MTOW) ) );

[climbRate, climbAngle, climbSpeed] = f18.calcMaxClimbRate(0, f18.MTOW, 1);
fprintf("\nSealevel max climb rate = %.3f kft/min with a climb angle of %.2f deg at a speed of %.3f m/s", m2ft(climbRate) * 60 / 1000, climbAngle, climbSpeed);

[turn_rate, n] = f18.getMaxTurn(0, 0.5, f18.MTOW);
fprintf("\nSealevel, Mach 0.5 max turn rate = %.2f deg/s at a load factor of %.2f", turn_rate, n)

fprintf("\nF18 spot factor = %.3f", f18.calcSpotFactor(0.3193) )

[maxAlt, maxAltMach, excessPower] = f18.calcMaxAlt(f18.MTOW, 1);
fprintf("\nThe F18 has a service ceiling of %.2f kf (does Mach %.2f at its ceiling with a CL of %.3f).", m2ft(maxAlt)/1000, maxAltMach, f18.calcTrimCL(maxAlt, maxAltMach, f18.MTOW))

[maxMach, maxMachAlt] = f18.calcMaxMach(f18.MTOW, 1);
fprintf("\nThe F18 has a maximum mach number of %.3f which it reaches at %.2f kf", maxMach, m2ft(maxMachAlt)/1000)

[h_maxR, M_maxR, V_maxR, L2D_maxR] = f18.findMaxRangeState(f18.MTOW);
[h_maxE, M_maxE, V_maxE, LD_maxE] = f18.findMaxEnduranceState(f18.MTOW);
fprintf("\nMax range altitude = %.2f kf at Mach %.2f with a speed of %.2f m/s and L^(1/2)/D ratio of %.2f", m2ft(h_maxR)/1000, M_maxR, V_maxR, L2D_maxR);
fprintf("\nMax endurance altitude = %.2f kf at Mach %.2f with a speed of %.2f m/s and L/D ratio of %.2f", m2ft(h_maxE)/1000, M_maxE, V_maxE, LD_maxE);

% f18.buildPlots(f18.MTOW, 50)

% f18.calcMaxMachFixedAlt(10000, f18.MTOW, 1)