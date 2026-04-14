function data = eval_corsair_error(settings)
% settings will be modified from the base settings

% data.res (errors) data.des (string description) data.val (computed val) data.tar (target val)

data.res = []; data.des = []; data.val = []; data.tar = [];

settings.PROP_model = settings.codes.PROP_HOOK; % since we don't have a npss model for this engine

%%  CREATE THE BASE CLASSES
geom = loadAircraft("a7e_corsair", settings);
geom =  setLoadout(geom, ["" "" "" "" "" "" "" ""]); % fully clean (unlike hornet)
model = model_class(settings, geom);
perf = performance_class(model);

WE = weightRatio(0, geom);
data = res_cal(data, N2lb(WE), 19576, "Empty Weight");

WF_internal = geom.weights.max_fuel_weight.v;
data = res_cal(data, N2lb(WF_internal), 10036, "Internal Fuel Weight");

v_land = compute_landing_speed(perf, 0.5); % taking mid mission weight
data = res_cal(data, ms2kt(v_land), 110, "Landing Speed");

perf.clear_data();
h0_dash_mach = compute_max_mach_at_h(perf, 0.5, 0); % taking mid mission weight
max_speed_cond = levelFlightCondition(perf, 0, h0_dash_mach, 0.5);
data = res_cal(data, ms2kt(max_speed_cond.vel.v), 602, "Sea Level Max Speed");

perf.clear_data();
[h_opt, ~] = compute_combat_ceiling(perf, 0.5);
data = res_cal(data, m2ft(h_opt), 44490, "Max Combat Celing");

perf.model.clear_mem(); perf.clear_data();
perf.model.cond = generateCondition(geom, 0, 0.5, 1, 0.5, 0.9); 
data = res_cal(data, m2ft(perf.ExcessPower)*60/1000, 9.38, "Military Sealevel ROC");

%% Full Mission Simulations
data = compute_missions_res(data, readMissionStruct("Corsair_Hi_Hi_Hi"), perf, settings, "Hi-Hi-Hi Mission End Weight");

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