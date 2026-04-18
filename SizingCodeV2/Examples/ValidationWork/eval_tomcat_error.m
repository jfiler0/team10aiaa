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

% perf_unswept.clear_data();
% [h_opt, ~] = compute_combat_ceiling(perf_unswept, 0.5);
% data = res_cal(data, m2ft(h_opt), 45100, "Max Combat Celing (Unswept)");

% perf_unswept.clear_data();
% perf_unswept.model.cond = generateCondition(geom_unswept, 0, 0.5, 1, 0.5, 0.9); 
% data = res_cal(data, m2ft(perf_unswept.ExcessPower)*60/1000, 15.05, "Military Sealevel ROC (Unswept)");
% 
% perf_swept.clear_data();
% perf_swept.model.cond = generateCondition(geom_swept, 0, 0.5, 1, 0.5, 1); 
% data = res_cal(data, m2ft(perf_swept.ExcessPower)*60/1000, 44.5, "Afterburning Sealevel ROC (Swept)");

%% Full Mission Simulations
% data = compute_missions_res(data, readMissionStruct("Tomcat_Hi_Hi_Hi"), perf_unswept, settings, "Hi-Hi-Hi Mission End Weight");


end

function data = res_cal(data, calc_val, target_val, des)
    data.res = [data.res, (calc_val - target_val)/abs(target_val) ];
    data.des = [data.des, des];
    data.val = [data.val, calc_val];
    data.tar = [data.tar, target_val];
end

function data = compute_missions_res(data, mission, perf, settings, des)
    % copying performance is a bit safer
    temp_perf = perf; % the loadout being set transfer back out cause yay memory based variables
    temp_perf.clear_data; temp_perf.model.clear_mem();

    temp_calc = mission_calculator(temp_perf, settings); % loadout is applied internally
    temp_calc.record_hist = false; % true for plotting
    temp_calc.do_print = false;
    temp_calc.build_map(); % assembles v, h, W map for key performance info

    W_final = temp_calc.solve_mission(mission, 0, kt2ms(135), 1); % starts at 135 kt at full weight
    data = res_cal(data, W_final, weightRatio(0, temp_perf.model.geom), des);

    % temp_calc.plot_hist
end