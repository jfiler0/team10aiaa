% NEXT: Need conditions to update properly in a useful way

% NAME: test_functions_2
% PURPOSE:
%   Replaces test_functions with the new aircraft class. Demonsrates how to load in all the classes and run basic calls

% MAKE SURE TO RUN initialize.m
initialize
matlabSetup

settings = readSettings();
geom = loadAircraft("f18_superhornet");

N = 20;

cond = generateCondition(geom, linspace(0, 1000, N), linspace(1.29, 2, N), linspace(0, 1, N), linspace(0, 1, N), linspace(0, 1, N));

model = model_class(settings, geom, cond);

% model.CD0(settings.codes.OVER_NO_WRITE)

% model.CDi

% model.CDw

plot(cond.M.v, model.CDi)

% TODO
%   - Get condition function vectorized
%   - Get all models properly implemented and vectorized
%   - Same for performance class

%% RUN BASIC MODEL CALLS
% aircraft = aircraft_class(models, geom, settings);
%     % Passes in our current models, geometry, condition, and settings construtors
%     % All edits to those variables are now done through aircraft.
%     % aircraft also handles models calls. This is way it can easy handle redundant calls and history
% 
% aircraft.setGeomVar("wing.span", 8);
% % aircraft.setGeomVar("weights.empty", 1E5) -> this throws an error (as it should)
%     % Example call of how a variable would be changed. Note that the write "structChain" (that first part) is critical.
% 
% % Actually calling the big 4 analyisis functions:
% fprintf("cost = %.6f mil\n", aircraft.call("cost") )
% fprintf("CDW = %.6f\n", aircraft.call("CDW") )
% fprintf("CLa = %.6f\n", aircraft.call("CLa") )
% fprintf("CDi = %.6f\n", aircraft.call("CDi") )
% 
% % The propulsion function is a bit more complicated beacuse it outputs a vector [Thrust Available, TSFC, alpha] instead of a scaler
% prop_out = aircraft.call("PROP");
% fprintf("For h = %.0f m + M = %.3f. TA = %.3f N, TSFC = %.3g kg/(Ns), alpha = %.4f\n", aircraft.cond.h.v, aircraft.cond.M.v, prop_out(1), prop_out(2), prop_out(3))
% 
% % PLOTTING
% % plot_models(aircraft, 80)
%     % Runs the main models with vector calls instead and plots them
% 
% %% TESTING PERFORMANCE
% %                        h  M    CL   W  throt
% aircraft.updateCondition(0, 0.6, 0.1, 1, 0.9)
% 
% perf = performance_class(aircraft);
% 
% fprintf("\nCD = %.4g, CDi = %.4g, CDW = %.4g, CD0 = %.4g, TSFC = %4g, TA = %.4g", perf.CD, perf.CDi, perf.CDW, perf.CD0, perf.TSFC, perf.TA)
% 
% %% Weight Calculation
% 
% weight_comps = getRaymerWeightStruct(aircraft.geom);
% 
% generatePlane(aircraft.geom)