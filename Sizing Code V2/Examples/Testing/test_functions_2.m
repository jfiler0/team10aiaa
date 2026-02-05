% NEXT: Need conditions to update properly in a useful way

% NAME: test_functions_2
% PURPOSE:
%   Replaces test_functions with the new aircraft class. Demonsrates how to load in all the classes and run basic calls

% MAKE SURE TO RUN initialize.m
initialize
matlabSetup

%% READ IN DATA FILES
settings = readSettings();
    % reads the associated json file to create a constructor of settings that goes into models/across the program
models = read_models_file("simple_model");
    % models are predefined as a .mat file to be loaded. See "Model_Builders" for more info
models.updateSettings(settings); 
    % The models.mat file already has a settings property. But it may not be up to date. So this resets it.
geom = readAircraftFile("f18_superhornet"); 
    % Load a geometry input json file from the Aircraft Files folder

%% UPDATES VARIABLES IN GEOM
geom = updatePropulsionInfo(geom); 
    % Gets the needed propulsion parameters needed for the Prop model. May require further modification 
    % if a more advanced prop model is used. Currently references the engine lookup using an engine defenition in the geometry file
geom = processGeometryDerived(geom); 
    % Primary update function which calculates derived variables and assigns them for the first time
    % Quite a bit of reduancy in this function which could be improved
geom = processGeometryWeight(geom); 
    % Use the simple Raymer model to predict WE and other required weight variables
geom = processGeometryConnections(geom);
    % Currently empty - placeholder for future improvement to speed up derived variable recalculation

%% RUN BASIC MODEL CALLS
cond = updateCondition(0, 0.8, 0.3, 1); % *** How I am handling conditions is next big thing to fix

aircraft = aircraft_class(models, geom, cond, settings);
    % Passes in our current models, geometry, condition, and settings construtors
    % All edits to those variables are now done through aircraft.
    % aircraft also handles models calls. This is way it can easy handle redundant calls and history

% aircraft.setGeomVar("wing.span", 8);
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
% fprintf("For h = %.0f m + M = %.3f. TA = %.3f N, TSFC = %.3g kg/(Ns), alpha = %.4f\n", aircraft.cond.h, aircraft.cond.M, prop_out(1), prop_out(2), prop_out(3))
% 
% % PLOTTING
% plot_models(aircraft, 80)
%     % Runs the main models with vector calls instead and plots them

%% TESTING PERFORMANCE

perf = performance_class(aircraft);

perf.TSFC()

perf.alpha