initialize; % note that this resets settings to default. Just needs to be run once at the start of matlab session

%% READ IN DATA FILES
settings = readSettings();
models = read_models_file("simple_model");
models.updateSettings(settings); % an update to make sure - settings may not match saved .mat file
geom = readAircraftFile("f18_superhornet"); % Get a geometry input file from the Aircraft Files folder

%% UPDATES VARIABLES IN GEOM
geom = updatePropulsionInfo(geom); % Needed to get variables for prop models from lookup tables
geom = processGeometryInput(geom); % Do basic calculations to get useful variables
geom = processGeometryWeight(geom); % Use a model to predict WE and other required weight variables

%% RUN BASIC MODEL CALLS
condition = updateCondition(0, 0.8, 0.3, 1);
models.loadInterps(geom, condition); % this is optional - done automaticlly if removed

fprintf("cost = %.6f mil\n", models.call("cost", geom) )
fprintf("CDW = %.6f\n", models.call("CDW", geom, condition) )
fprintf("CLa = %.6f\n", models.call("CLa", geom, condition) )
fprintf("CDi = %.6f\n", models.call("CDi", geom, condition) )

prop_out = models.call("PROP", geom, condition);
fprintf("For h = %.0f m + M = %.3f. TA = %.3f N, TSFC = %.3g kg/(Ns), alpha = %.4f\n", condition.h, condition.M, prop_out(1), prop_out(2), prop_out(3))

%% PLOTTING
figure();
M_vec = linspace(0.5, 2, 500);
CDW_vec = models.vector_call("CDW", geom, condition, "condition.M", M_vec );
plot(M_vec, CDW_vec)

figure();
W_vec = linspace(geom.weights.empty.v/2, geom.weights.empty.v*2, 250);
cost_vec = models.vector_call("cost", geom, condition, "geometry.weights.empty", W_vec );
plot(W_vec, cost_vec)

% plot_models(models, geom, 50)