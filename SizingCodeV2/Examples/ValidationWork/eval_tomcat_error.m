function data = eval_tomact_error(settings)
% settings will be modified from the base settings

% data.res (errors) data.des (string description) data.val (computed val) data.tar (target val)

data.res = []; data.des = []; data.val = []; data.tar = [];

%%  CREATE THE BASE CLASSES
geom_unswept = loadAircraft("f14_tomact_unswept", settings);
geom_unswept =  setLoadout(geom_unswept, ["" "" "" "" "" "" "" ""]);
model_unswept = model_class(settings, geom_unswept);
perf_unswept = performance_class(model_unswept);

geom_swept = loadAircraft("f14_tomact_swept", settings);
geom_swept =  setLoadout(geom_swept, ["" "" "" "" "" "" "" ""]);
model_swept = model_class(settings, geom_swept);
perf_swept = performance_class(model_swept);

data = res_cal(data, N2lb(weightRatio(0, geom_swept)), 43470, "Empty Weight");

WF_internal = geom_unswept.weights.max_fuel_weight.v;
data = res_cal(data, N2lb(WF_internal), 16200, "Internal Fuel Weight");

% perf_unswept.clear_data();
% v_land = compute_landing_speed(perf_unswept, 0.5); % taking mid mission weight
% data = res_cal(data, ms2kt(v_land), 109, "Landing Speed");

perf_swept.clear_data();
h0_dash_mach = compute_max_mach_at_h(perf_swept, 0.5, 0); % taking mid mission weight
data = res_cal(data, ms2kt(343*h0_dash_mach), 740, "Sea Level Dash Speed");

perf_swept.clear_data();
[h_opt, M_opt] = compute_max_mach(perf_swept, 0.5);
max_speed_cond = levelFlightCondition(perf_swept, h_opt, M_opt, 0.5);
data = res_cal(data, ms2kt(max_speed_cond.vel.v), 1196, "Max Speed");

perf_swept.clear_data();
[h_opt, ~] = compute_combat_ceiling(perf_swept, 0.5);
data = res_cal(data, m2ft(h_opt), 56600, "Max Combat Celing (Swept)");

end