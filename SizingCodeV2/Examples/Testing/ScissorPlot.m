% STARTUP FUNCTIONS
initialize
matlabSetup
build_kevin_cad

% INITIAL OBJECTS TO LOAD
build_default_settings
settings = readSettings();
geom = loadAircraft("kevin_cad", settings);

model = model_class(settings, geom);
perf = performance_class(model);

sm = linspace(-0.3,0.3,100);

% Stability Requirement
% SHSW_stability = 