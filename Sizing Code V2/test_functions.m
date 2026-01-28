%% Calls all functions are checks they work
% clear models
% matlabSetup
addAllPath
close all;

%% BUILD A MODELS FILE

% the first two inputs are the ones that will be plotted
% settings should never be an input - it is a constant
CD0_model = model_def( "CD0", @CD0_basic, [model_input("geometry.weights.empty", false), model_input("geometry.ref_area", false)] );

COST_model = model_def( "cost", @unitcost_wrapper, [model_input("geometry.weights.empty", true, 50, [1E2 1E6]), model_input("geometry.input.kloc", true, 1)] );

CDW_model = model_def( "CDW", @CDW_basic, [model_input("condition.M", false, 30, [0.3 2]), model_input("geometry.fuselage.max_area", false, 1), ...
    model_input("geometry.fuselage.length", false, 1), model_input("geometry.wing.le_sweep", false, 1),  model_input("geometry.fuselage.E_WD", false, 1) ], 'makima' );

CLa_model = model_def( "CLa", @CLa_basic, [model_input("condition.M", false)] );

CDi_model = model_def( "CDi", @CDi_simple, [model_input("condition.CL", false), model_input("geometry.wing.AR", false, 1), ...
    model_input("geometry.wing.le_sweep", false, 1)] );

Prop_model = model_def( "PROP", @Prop_Raymer, [model_input("condition.M", false, 10, [0.3 1.5]), model_input("condition.h", false, 10, [0 10000])]);

models = models_class([CD0_model COST_model CDW_model CLa_model CDi_model Prop_model]);

build_models_file(models, "primary_models")

clear; % not needed but keeps things cleaner

%% OPTIONAL UPDATES
build_default_settings(); % rebuilds the setting file to a defined default 
build_f18_template(); % creates a sample JSON file called f18_superhornet

%% READ IN DATA FILES
settings = readSettings();
models = read_models_file("primary_models");
geom = readAircraftFile("f18_superhornet"); % Get a geometry input file from the Aircraft Files folder

%% UPDATES AND SETUP

geom = updatePropulsionInfo(geom); % Needed to get variables for prop models from lookup tables
geom = processGeometryInput(geom); % Do basic calculations to get useful variables
geom = processGeometryWeight(geom); % Use a model to predict WE and other required weight variables

build_atmosphere_lookup(-5000, ft2m(100000), 500); % Refresh atmosphere lookup
models.updateSettings(settings); % an update to make sure

condition = updateCondition(0, 0.8, 0.3, 1);
models.loadInterps(geom, condition); % this is optional

%% RUN BASIC MODEL CALLS

fprintf("cost = %.6f mil\n", models.call("cost", geom) )
fprintf("CDW = %.6f\n", models.call("CDW", geom, condition) )
fprintf("CLa = %.6f\n", models.call("CLa", geom, condition) )
fprintf("CDi = %.6f\n", models.call("CDi", geom, condition) )

prop_out = models.call("PROP", geom, condition);
fprintf("For h = %.0f m + M = %.3f. TA = %.3f N, TSFC = %.3g kg/(Ns), alpha = %.4f\n", condition.h, condition.M, prop_out(1), prop_out(2), prop_out(3))

%% Time for graphing
figure();
M_vec = linspace(0.5, 2, 500);
CDW_vec = models.vector_call("CDW", geom, condition, "condition.M", M_vec );
plot(M_vec, CDW_vec)

figure();
W_vec = linspace(geom.weights.empty.v/2, geom.weights.empty.v*2, 250);
cost_vec = models.vector_call("cost", geom, condition, "geometry.weights.empty", W_vec );
plot(W_vec, cost_vec)

% plot_models(models, geom, 50)