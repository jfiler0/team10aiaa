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

data = res_cal(data, N2lb(weightRatio(0, geom)), 19576, "Empty Weight");

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

% segObjs = [ missionSegObj('TAKEOFF') , ...
%             missionSegObj('CLIMB') , ...
%             missionSegObj('CRUISE', distance=nm2m(2312/2), h=ft2m(35320), vel=kt2ms(454)) , ... % fly at best cruise
%             missionSegObj('CRUISE', distance=nm2m(2312/2), h=ft2m(42850), vel=kt2ms(454)) , ... % cruise at 10000 feet
%             missionSegObj('LANDING') , ... % first landing attempt
%             missionSegObj('LOITER', time=1*60, h=ft2m(1000)) , ... % loiter at 1000 ft best velocity -> going around
%             missionSegObj('LANDING') ];
% 
% ferry = buildMission("Ferry" , segObjs , ["" "" "" "300GAL" "" "300GAL" "" "" ""]);
% data = mission_res(data, eval_mission(perf, ferry, false, 1), "Ferry");

end