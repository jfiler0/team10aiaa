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

perf.model.clear_mem(); perf.clear_data();
perf.model.cond = generateCondition(geom, 0, 0.5, 1, 0.5, 0.9); 
data = res_cal(data, m2ft(perf.ExcessPower)*60/1000, 12, "Military Sealevel ROC");

perf.model.clear_mem(); perf.clear_data();
perf.model.cond = generateCondition(geom, 0, 0.5, 1, 0.5, 1); 
data = res_cal(data, m2ft(perf.ExcessPower)*60/1000, 44, "Afterburning Sealevel ROC");

ref_weight = geom.weights.max_fuel_weight.v; % leftover fuel

segObjs = [ missionSegObj('TAKEOFF') , ...
            missionSegObj('CLIMB') , ...
            missionSegObj('CRUISE', distance=nm2m(597), h=ft2m(39600), vel=kt2ms(484)) , ... % fly at best cruise
            missionSegObj('COMBAT', time=60*5, throttle_override=0.9, h=ft2m(39600), vel=kt2ms(484)) , ... % 5 min at intermediate thrust
            missionSegObj('CRUISE', distance=nm2m(597), h=ft2m(44850), vel=kt2ms(484)) , ... % cruise at 10000 feet
            missionSegObj('LOITER', time=20*60, h=ft2m(10000)) , ... % loiter at 10000 ft best velocity
            missionSegObj('LANDING') , ... % first landing attempt
            missionSegObj('LOITER', time=1*60, h=ft2m(1000)) , ... % loiter at 1000 ft best velocity -> going around
            missionSegObj('LANDING') ];

air2air = buildMission("Air2Air" , segObjs , ["AIM-9X" "" "" "" "" "" "" "" "AIM-9x"]);
air2air = set_radius(air2air, nm2m(597));
data = mission_res(data, eval_mission(perf, air2air, false, 1), "Clean Air2Air");

air2air = buildMission("Air2Air" , segObjs , ["AIM-9X" "AIM-120" "" "" "" "" "" "AIM-120" "AIM-9x"]);
air2air = set_radius(air2air, nm2m(574));
data = mission_res(data, eval_mission(perf, air2air, false, 1), "Air2Air w 2 AIM-120");

air2air = buildMission("Air2Air" , segObjs , ["AIM-9X" "AIM-120" "" "" "FPU-12" "" "" "AIM-120" "AIM-9x"]);
air2air = set_radius(air2air, nm2m(676));
data = mission_res(data, eval_mission(perf, air2air, false, 1), "Air2Air w 2 AIM-120 w 1 Tank");

air2air = buildMission("Air2Air" , segObjs , ["AIM-9X" "AIM-120" "" "FPU-12" "FPU-12" "FPU-12" "" "AIM-120" "AIM-9x"]);
air2air = set_radius(air2air, nm2m(759));
data = mission_res(data, eval_mission(perf, air2air, false, 1), "Air2Air w 2 AIM-120 w 3 Tank");

% AAQ-28 = TFLIR
air2air = buildMission("Air2Air" , segObjs , ["AIM-9X" "AIM-120" "AAQ-28" "AIM-120" "AIM-120" "AIM-120" "" "AIM-120" "AIM-9x"]);
air2air = set_radius(air2air, nm2m(478));
data = mission_res(data, eval_mission(perf, air2air, false, 1), "Air2Air w 5 AIM-120 w FLIR");

end