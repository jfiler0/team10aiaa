function data = eval_hornet_error(settings)
% settings will be modified from the base settings

% data.res (errors) data.des (string description) data.val (computed val) data.tar (target val)

data.res = []; data.des = []; data.val = []; data.tar = [];

%%  CREATE THE BASE CLASSES
geom = loadAircraft("f18_superhornet", settings);
geom =  setLoadout(geom, ["AIM-9X" "" "" "" "" "" "" "AIM-9X"]);
model = model_class(settings, geom);
perf = performance_class(model);

data = res_cal(data, N2lb(geom.weights.empty.v), 31855, "Empty Weight");

WF_internal = geom.weights.max_fuel_weight.v;
data = res_cal(data, N2lb(WF_internal), 14850, "Internal Fuel Weight");

v_land = compute_landing_speed(perf, 0.5); % taking mid mission weight
data = res_cal(data, ms2kt(v_land), 120, "Landing Speed");

perf.model.clear_mem(); perf.clear_data();

h0_dash_mach = compute_max_mach_at_h(perf, 0.5, 0); % taking mid mission weight
data = res_cal(data, h0_dash_mach, 1.03, "Sea Level Dash");

perf.model.clear_mem(); perf.clear_data();
[~, max_mach] = compute_max_mach(perf, 0.5);
data = res_cal(data, max_mach, 1.65, "Max Mach");

% perf.clear_data();
% [h_opt, ~] = compute_combat_ceiling(perf, 0.5);
% data = res_cal(data, m2ft(h_opt), 46600, "Max Combat Celing");

% perf.model.clear_mem(); perf.clear_data();
% perf.model.cond = generateCondition(geom, 0, 0.5, 1, 0.5, 0.9); 
% data = res_cal(data, m2ft(perf.ExcessPower)*60/1000, 12, "Military Sealevel ROC");
% 
% perf.model.clear_mem(); perf.clear_data();
% perf.model.cond = generateCondition(geom, 0, 0.5, 1, 0.5, 1); 
% data = res_cal(data, m2ft(perf.ExcessPower)*60/1000, 44, "Afterburning Sealevel ROC");

range_nm_strike = get_mission_range(@eval_air2gnd, 50, perf, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"]);
range_nm_combat = get_mission_range(@eval_air2air, 2, perf, ["AIM-9X" "AIM-120" "AIM-120" "FPU-12" "" "FPU-12" "AIM-120" "AIM-120" "AIM-9x"]);
range_nm_ferry = get_mission_range(@eval_ferry, 0, perf, ["AIM-9X" "" "" "FPU-12" "FPU-12" "FPU-12" "" "" "AIM-9x"]);

data = res_cal(data, range_nm_strike, 480, "Strike Range, 50nm");
data = res_cal(data, range_nm_combat, 610, "Combat Range, 2min");
data = res_cal(data, range_nm_ferry, 800, "Ferry Max Range (3 tanks)");

perf.model.clear_mem(); perf.clear_data();
perf.model.geom = setLoadout(perf.model.geom, ["AIM-9X" "" "" "FPU-12" "FPU-12" "FPU-12" "" "AIM-9X"]);
[max_range_est, h_opt, ~, v_opt] = estimate_max_range(perf, 1);
% data = res_cal(data, m2nm(max_range_est), 1654, "Ferry Max Range");
% data = res_cal(data, m2ft(h_opt)/1000, 42, "Ferry Cruise Best Alt");
data = res_cal(data, ms2kt(v_opt), 484, "Ferry Cruise Best Speed");

%% Full Mission Simulations
% data = compute_missions_res(data, readMissionStruct("Hornet_Hi_Hi_Hi"), perf, settings, "Hi-Hi-Hi Mission End Weight");
% data = compute_missions_res(data, readMissionStruct("Hornet_Hi_Hi_Hi_AIM120"), perf, settings, "Hi-Hi-Hi Mission End Weight (2 Aim-120s)");
% data = compute_missions_res(data, readMissionStruct("Hornet_Hi_Hi_Hi_1TANK"), perf, settings, "Hi-Hi-Hi Mission End Weight (1 tank)");
% data = compute_missions_res(data, readMissionStruct("Hornet_Hi_Hi_Hi_3TANK"), perf, settings, "Hi-Hi-Hi Mission End Weight (3 tank)");
% data = compute_missions_res(data, readMissionStruct("Hornet_Intercept"), perf, settings, "Intercept Mission End Weight");
% data = compute_missions_res(data, readMissionStruct("Hornet_Intercept_3TANK"), perf, settings, "Intercept Mission End Weight (3 Tank)");


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

function range_nm = get_mission_range(fun, input, perf, loadout)
    try
        range_nm = fzero(@(R) eval_res(perf, fun, R, input, loadout), 100);
    catch exception
        range_nm = NaN;
    end

    function res = eval_res(perf, fun, range_nm, input, loadout)
        [W_final, empty_weight] = fun(perf, range_nm, input, loadout);
        res = W_final-empty_weight;
    end
end