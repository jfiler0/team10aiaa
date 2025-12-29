%% Calls all functions are checks they work
clear; clc; close all; 

geom = readAircraftFile("f18_superhornet"); % Get a geometry input file from the Aircraft Files folder
geom = processGeometryInput(geom); % Do basic calculations to get useful variables
geom = processGeometryWeight(geom); % Use a model to predict WE and other required weight variables

CD0_model = model_def( "CD0", @CD0_basic, false, [model_input("geometry.weights.empty")] );
COST_model = model_def( "cost", @unitcost_wrapper, true, [model_input("geometry.weights.empty", 50, [1E2 1E6]), model_input("geometry.input.kloc", 1)] );
CDW_model = model_def( "CDW", @CDW_basic, false, [model_input("conditions.mach")] );
% COST_model = model_def( "cost", @unitcost_wrapper, [model_input("geometry.weights.empty"), model_input("geometry.input.kloc")] );
% CD0_model = model_def( "CD0", @CD0_basic, [model_input("geometry.weights.mtow", 10, [1E2 1E6]) model_input("geometry.wing.span")] );

models = models(NaN, [CD0_model COST_model CDW_model]);
models.loadInterps(geom, NaN);

build_models_file(models, "primary_models")

clear models

models = read_models_file("primary_models");


models.call("cost", geom)

condition = struct();
condition.mach = 1.5;

M_vec = linspace(0.5, 2, 500);
CDW_vec = models.vector_call("CDW", geom, condition, "condition.mach", M_vec );
plot(M_vec, CDW_vec)