function data = eval_falcon_error(settings)
% settings will be modified from the base settings

% data.res (errors) data.des (string description) data.val (computed val) data.tar (target val)

data.res = []; data.des = []; data.val = []; data.tar = [];

%%  CREATE THE BASE CLASSES
geom = loadAircraft("f16_falcon", settings);
geom =  setLoadout(geom, ["" "" "" "" "" "" "" ""]); % fully clean (unlike hornet)
model = model_class(settings, geom);
perf = performance_class(model);

data = res_cal(data, N2lb(weightRatio(0, geom)), 16326, "Empty Weight");

WF_internal = geom.weights.max_fuel_weight.v;
data = res_cal(data, N2lb(WF_internal), 6972, "Internal Fuel Weight");

v_land = compute_landing_speed(perf, 0.5); % taking mid mission weight
data = res_cal(data, ms2kt(v_land), 127, "Landing Speed");

perf.model.clear_mem(); perf.clear_data();

h0_dash_mach = compute_max_mach_at_h(perf, 0.5, 0); % taking mid mission weight
data = res_cal(data, h0_dash_mach, 1.2, "Sea Level Dash");

perf.model.clear_mem(); perf.clear_data();
[~, max_mach] = compute_max_mach(perf, 0.5);
data = res_cal(data, max_mach, 2.05, "Max Mach");

% perf.clear_data();
% [h_opt, ~] = compute_combat_ceiling(perf, 0.5);
% data = res_cal(data, m2ft(h_opt), 54837, "Max Combat Celing");

perf.model.clear_mem(); perf.clear_data();
perf.model.cond = generateCondition(geom, 0, 0.5, 1, 0.5, 0.9); 
data = res_cal(data, m2ft(perf.ExcessPower)*60/1000, 11, "Military Sealevel ROC");

perf.model.clear_mem(); perf.clear_data();
perf.model.cond = generateCondition(geom, 0, 0.5, 1, 0.5, 1); 
data = res_cal(data, m2ft(perf.ExcessPower)*60/1000, 55, "Afterburning Sealevel ROC");

perf.model.clear_mem(); perf.clear_data();
perf.model.geom = setLoadout(perf.model.geom, ["" "" "" "370GAL" "300GAL" "370GAL" "" ""]);

ref_weight = geom.weights.max_fuel_weight.v; % leftover fuel

segObjs = [ missionSegObj('TAKEOFF') , ...
            missionSegObj('CLIMB') , ...
            missionSegObj('CRUISE', distance=nm2m(2071/2), h=ft2m(33514), vel=kt2ms(458.4)) , ... % fly at best cruise
            missionSegObj('CRUISE', distance=nm2m(2071/2), h=ft2m(42761), vel=kt2ms(458.4)) , ... % cruise at 10000 feet
            missionSegObj('LANDING') , ... % first landing attempt
            missionSegObj('LOITER', time=1*60, h=ft2m(1000)) , ... % loiter at 1000 ft best velocity -> going around
            missionSegObj('LANDING') ];

ferry = buildMission("Ferry" , segObjs , ["" "" "" "370GAL" "300GAL" "370GAL" "" "" ""]);
data = mission_res(data, eval_mission(perf, ferry, false, 1), "Ferry");


end