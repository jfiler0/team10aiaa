% NEXT: Need conditions to update properly in a useful way

% NAME: test_functions_2
% PURPOSE:
%   Replaces test_functions with the new aircraft class. Demonsrates how to load in all the classes and run basic calls

% MAKE SURE TO RUN initialize.m
initialize
matlabSetup

settings = readSettings();
geom = loadAircraft("f18_superhornet");
cond = generateCondition(geom, 1000, 1.2, 0.1, 0.5, 1);

model = model_class(settings, geom, cond);

% N = 100;
% cond = generateCondition(geom, linspace(0, 1000, N), linspace(0.5, 2, N), linspace(0, 1, N), linspace(0, 1, N), linspace(0, 1, N));
% (geom, h, M_vel, CL, W, throttle)
% cond = generateCondition(geom, 0, 0.5, 0.1, 0.5, 1);
% model.COST;
% PROP = model.PROP;
% TA = PROP(:, 1);
% TSFC = PROP(:, 2);
% alpha = PROP(:, 3);

% Actually calling the big 4 analyisis functions:
fprintf("cost = %.6f mil\n", model.COST )
fprintf("CDW = %.6f\n", model.CDw )
fprintf("CLa = %.6f\n", model.CLa )
fprintf("CDi = %.6f\n", model.CDi )

% The propulsion function is a bit more complicated beacuse it outputs a vector [Thrust Available, TSFC, alpha] instead of a scaler
prop_out = model.PROP;
fprintf("For h = %.0f m + M = %.3f. TA = %.3f kN, TSFC = %.3g kg/(Ns), alpha = %.4f\n", cond.h.v, cond.M.v, prop_out(1)/1000, prop_out(2), prop_out(3))

% PLOTTING
%     Runs the main models with vector calls instead and plots them
plot_models(geom, model, 80)

%% TESTING PERFORMANCE
%                        h  M    CL   W  throt
% aircraft.updateCondition(0, 0.6, 0.1, 1, 0.9)
% 
% perf = performance_class(aircraft);
% 
% fprintf("\nCD = %.4g, CDi = %.4g, CDW = %.4g, CD0 = %.4g, TSFC = %4g, TA = %.4g", perf.CD, perf.CDi, perf.CDW, perf.CD0, perf.TSFC, perf.TA)

%% Weight Calculation

weight_comps = getRaymerWeightStruct(geom);

generatePlane(geom); % For AVL