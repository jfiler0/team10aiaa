matlabSetup;
build_hellstinger
settings = readSettings();

settings.WF_ratio = 0.6;

file_name = "HellstingerV3";
geom = loadAircraft(file_name, settings);
geom = updateGeom(geom, settings, false);
geom = setLoadout(geom, ["AIM-9X" "" "" "" "" "" "" "AIM-9X"]);

model = model_class(settings, geom);
perf = performance_class(model);

cond = levelFlightCondition(perf, 0, 0.5, 1); % M0.5, sea level, MTOW
    % setting a starting condition just so it is happy
    model.cond = cond;

displayAircraftGeom(geom)

[W_final, empty_weight] = eval_air2gnd(perf, 800, 50);
W_final - empty_weight
[W_final, empty_weight] = eval_air2air(perf, 800, 2);
W_final - empty_weight

perf.model.COST

geom.wing.area

geom.weights.empty

% 2.6576, 2.2055