%% Calls all functions are checks they work
clear; clc; close all; 

geom = readAircraftFile("f18_superhornet"); % Get a geometry input file from the Aircraft Files folder
geom = processGeometryInput(geom); % Do basic calculations to get useful variables
geom = processGeometryWeight(geom); % Use a model to predict WE and other required weight variables

% CD0_model = model_def( "CD0", @CD0_basic, [model_input("geometry.weights.empty")] );
% COST_model = model_def( "cost", @unitcost_wrapper, [model_input("geometry.weights.empty", 50, [1E2 1E6]), model_input("geometry.input.kloc", 25, [100 20000])] );
% % COST_model = model_def( "cost", @unitcost_wrapper, [model_input("geometry.weights.empty"), model_input("geometry.input.kloc")] );
% % CD0_model = model_def( "CD0", @CD0_basic, [model_input("geometry.weights.mtow", 10, [1E2 1E6]) model_input("geometry.wing.span")] );
% 
% models = models(NaN, [CD0_model COST_model]);
% models = models.loadInterps(geom, NaN);
% 
% build_models_file(models, "primary_models")
% 
% clear models

models = read_models_file("primary_models");

models.call("cost", geom)
models.call("CD0", geom)

disp("END")