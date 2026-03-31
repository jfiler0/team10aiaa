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

% geom.wing

% model.CLa

A = geom.wing.AR.v;
LMD = geom.wing.average_qrtr_chd_sweep.v;

perf.model.cond = levelFlightCondition(perf, 0, 0.4, 1);

model.CLa