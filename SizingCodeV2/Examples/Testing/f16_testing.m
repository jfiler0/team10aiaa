initialize
matlabSetup
build_f16_template

% INITIAL OBJECTS TO LOAD
build_default_settings
settings = readSettings();
geom = loadAircraft("f16_falcon", settings);
model = model_class(settings, geom);
perf = performance_class(model);

perf.model.cond = levelFlightCondition(perf, [0, 1000, 2000], [0.3, 0.8, 1.5], [1, 1, 1]);
% perf.model.cond = levelFlightCondition(perf, 1000, 0.5, 1);
disp("CDi RESULTS")
CDi = perf.model.CDi

disp("e_osw RESULTS")
e_osw = perf.model.cond.CL.v .^2 ./ (pi * perf.model.geom.wing.AR.v * CDi)

disp("CD0 RESULTS")
perf.model.CD0 % base: 0.0139

displayAircraftGeom(geom)

perf.TA