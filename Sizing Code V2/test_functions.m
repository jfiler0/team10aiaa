%% Calls all functions are checks they work
clear; clc; close all; 

geom = readAircraftFile("f18_superhornet"); % Get a geometry input file from the Aircraft Files folder
geom = processGeometryInput(geom); % Do basic calculations to get useful variables
geom = processGeometryWeight(geom); % Use a model to predict WE and other required weight variables

models = models(geom, NaN, @CD0_basic); % Assign the models to use for each key function (later build interpolations)

models.fetch_CD0(NaN) % example call to CD0