matlabSetup;

file_name = "0412_Optimization";
geom = readAircraftFile(file_name);
settings = readSettings();

geom = updateGeom(geom, settings, false);
geom = setLoadout(geom, ["AIM-9X" "" "" "" "" "" "" "AIM-9X"]);
model = model_class(settings, geom);
perf = performance_class(model);

cond = levelFlightCondition(perf, 0, 0.5, 1); % M0.5, sea level, MTOW
    % setting a starting condition just so it is happy
    model.cond = cond;

% displayAircraftGeom(geom)

mission_calc = mission_calculator(perf, settings);
mission_calc.record_hist = true;
mission_calc.do_print = false;
mission_calc.build_map(); % assembles v, h, W map for key performance info

mission = readMissionStruct("Air2Air_700nm");
W_final_Air2Air = mission_calc.solve_mission(mission, 0, kt2ms(135), 1); % solve air2air mission

W_final_Air2Air - weightRatio(0, geom);
mission_calc.plot_hist