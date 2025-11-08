%% Build atmo table
% build_atmosphere_lookup(-100, ft2m(120000), 250);
%% Rest of the script

% function [obj, S, T] = planeEval(W0, Lambda_LE, Lambda_TE, c_avg, span, mission_set, engine, W_F, W_P)
matlabSetup();

% W0, Lambda_LE, Lambda_TE, c_avg, tr, mission_set, engine, W_F, W_P

f18 = planeObj("FA18", lb2N(34000), 29.3, 0, 5.02, 0.374, 2, [], "F414", lb2N(1000), lb2N(2000));
% f18.buildPolars()
% f18.buildPerformance(1)
% f18.buildEngineMap(1)
% [turn_rate, n] = f18.getMaxTurn(1000, 0.8, f18.W0, 6.5)

fprintf("The F18 has a unit cost of %.2f million dollars and a stall speed of %.2f kt", f18.calcUnitCost(), ms2kt( f18.calcStallSpeed(0, f18.MTOW) ) );

[climbRate, climbAngle, climbSpeed] = f18.calcMaxClimbRate(0, f18.MTOW, 1);
fprintf("\nSealevel max climb rate = %.3f kft/min with a climb angle of %.2f deg at a speed of %.3f m/s", m2ft(climbRate) * 60 / 1000, climbAngle, climbSpeed);

[turn_rate, n] = f18.getMaxTurn(0, 0.5, f18.MTOW, 6.5);
fprintf("\nSealevel, Mach 0.5 max turn rate = %.2f deg/s at a load factor of %.2f", turn_rate, n)

% [excessPower, speed] = f18.calcMaxExcessPower( 0, f18.W0, 1)