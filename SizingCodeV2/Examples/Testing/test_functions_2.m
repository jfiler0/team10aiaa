% Whats next?
%   General function for making a map to speed up using interpolation
%   Actually running missions - with the sub missions
%       Finding/tracking the optimal TSFC
%   Calculate trim condition set
%   Make sure performance functions can deal with vector conditions (mesh grids would be cool)
%   Console interaction

% NAME: test_functions_2
% PURPOSE:
%   Replaces test_functions with the new aircraft class. Demonsrates how to load in all the classes and run basic calls

% MAKE SURE TO RUN initialize.m
initialize
matlabSetup

settings = readSettings();
geom = loadAircraft("f18_superhornet");

geom = setLoadout(geom, ["AIM-9X" "" "" "AIM-120" "AIM-120" "" "" "AIM-9x"]);

% Set the condition
cond = generateCondition(geom, 1000, 0.8, 1.7, 0.5, 1);

% TODO: Finish vectorizing this
% N = 10;
% cond = generateCondition(geom, ...
%     linspace(0, 5000, N), ... % Altitude
%     linspace(0.5, 2, N), ... % Mach Number
%     linspace(1, 2, N), ... % Load Factor
%     linspace(0, 1, N), ... % Weight
%     linspace(0.5, 1, N)); % Throttle

model = model_class(settings, geom, cond);
perf = performance_class(model);

% Actually calling the big 4 analyisis functions:
% fprintf("cost = %.6f mil\n", model.COST )
% fprintf("CDW = %.6f\n", model.CDw )
% fprintf("CLa = %.6f\n", model.CLa )
% fprintf("CDi = %.6f\n", model.CDi )

% The propulsion function is a bit more complicated beacuse it outputs a vector [Thrust Available, TSFC, alpha] instead of a scaler
prop_out = model.PROP;
fprintf("For h = %.0f m + M = %.3f. TA = %.3f kN, TSFC = %.3g kg/(Ns), alpha = %.4f\n", cond.h.v, cond.M.v, prop_out(:, 1)/1000, prop_out(:, 2), prop_out(:, 3))

% PLOTTING
%     Runs the main models with vector calls instead and plots them

% plot_models(geom, model, 200)
% plot_performance(geom, perf, 200);

% geom = editGeom(geom, "wing.AR", 2);

%% Weight Calculation

% Builds a struct of weight components
weight_comps = getRaymerWeightStruct(geom);

% For AVL
generatePlane(geom);

% perf.ClimbAngle

% cost_struct = xanderscript_modified(geom, true, false);

% model.COST

perf.e_osw

% Make a way of plotting the current geometry in matlab
% Then can take those points into idrag for actual results
% Connect that to the models
% finally work on adding the fucking vectorization
% Remove vtail and LERX requirements to be more general to other planes
% Want the geometry display figure to show stores as cylinders