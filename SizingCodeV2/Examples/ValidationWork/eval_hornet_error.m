function [res, des] = eval_hornet_error(settings)
% settings will be modified from the base settings

res = []; des = [];

%%  CREATE THE BASE CLASSES
geom = loadAircraft("f18_superhornet", settings);
geom =  setLoadout(geom, ["AIM-9X" "" "" "" "" "" "" "AIM-9X"]);
model = model_class(settings, geom);
perf = performance_class(model);

WE = geom.weights.empty.v;
res = res_cal(res, N2lb(WE), 30564);
des = [des "Empty Weight"];

WF_internal = geom.weights.max_fuel_weight.v;
res = res_cal(res, N2lb(WF_internal), 14850);
des = [des "Internal Fuel Weight"];

v_land = compute_landing_speed(perf, 0.5); % taking mid mission weight
res = res_cal(res, ms2kt(v_land), 120);
des = [des "Landing Speed"];

h0_dash_mach = compute_max_mach_at_h(perf, 0.5, 0); % taking mid mission weight
res = res_cal(res, h0_dash_mach, 1.03);
des = [des "Sea Level Dash"];

[~, max_mach] = compute_max_mach(perf, 0.5);
res = res_cal(res, max_mach, 1.65);
des = [des "Max Mach"];

perf.model.clear_mem(); perf.clear_data(); % just in case

perf.model.cond = generateCondition(geom, 0, 0.5, 1, 0.5, 0.9); 
res = res_cal(res, m2ft(perf.ExcessPower)*60/1000, 12);
des = [des "Military Sealevel ROC"];

perf.model.cond = generateCondition(geom, 0, 0.5, 1, 0.5, 1); 
res = res_cal(res, m2ft(perf.ExcessPower)*60/1000, 44);
des = [des "Afterburnign Sealevel ROC"];

[max_range_est, h_opt, M_opt, v_opt] = estimate_max_range(perf, 1);
fprintf( "Found approximate F18 range: 1654 nm. Estimate of best total range: %.0f nm (h=%.2f kf , M=%.2f, v=%.0f kt)\n", m2nm(max_range_est), m2ft(h_opt)/1000, M_opt, ms2kt(v_opt))

res = res_cal(res, m2nm(max_range_est), 1654);
des = [des "Ferry Max Range"];

res = res_cal(res, m2ft(h_opt)/1000, 42);
des = [des "Ferry Cruise Best Alt"];

res = res_cal(res, ms2kt(v_opt), 484);
des = [des "Ferry Cruise Best Speed"];

%% Full Mission Simulations

Hi_Hi_Hi_loadout = setLoadout(geom, ["AIM-9X" "" "" "" "" "" "" "AIM-9X"]);
Hi_Hi_Hi = { ...
    missionSeg("TAKEOFF", 'FIXED_WF', [0.98, 5]), ... % basic takeoff
    missionSeg("CRUISE_OUT", 'CRUISE', nm2m(597), [kt2ms(484) NaN], [ft2m(40000) NaN] ), ... % using the best range number from charcteristics doc
    missionSeg("COMBAT", 'COMBAT', [2, 3, 1, 8], [NaN, NaN], [ft2m(30000), NaN] ), ... % 2 min at afterburning subs 5 at intermediate thrust. Deploy both Aim9x. Drop to 30000
    missionSeg("CRUISE_BACK", 'CRUISE', nm2m(597), [kt2ms(484) NaN], [ft2m(40000) NaN] ), ... % using the best range number from charcteristics doc
    missionSeg("LOITER", 'LOITER', 20, [NaN, NaN], [ft2m(10000), NaN] ), ... % maintain 10kf for 20 minutes
    missionSeg("APPROACH", 'LOITER', 5, [NaN, NaN], [ft2m(10000), 0] ), ... % descend from 10kf to sealevel in 5 minutes
    missionSeg("LANDING", 'FIXED_WF', [0.98, 5]) }; % basic landing/taxi

res = compute_missions_res(res, Hi_Hi_Hi, Hi_Hi_Hi_loadout, perf, settings);
des = [des "Hi-Hi-Hi Mission"];

end

function res = res_cal(res, calc_val, target_val)
    res = [res, abs( (calc_val - target_val)/target_val )];
end

function res = compute_missions_res(res, mission, geom, perf, settings)

    temp_perf = perf; temp_perf.model.geom = geom; temp_perf.clear_data; temp_perf.model.clear_mem();

    temp_calc = mission_calculator(temp_perf, settings);
    temp_calc.record_hist = false;
    temp_calc.do_print = false;
    temp_calc.build_map(); % assembles v, h, W map for key performance info

    W_final = temp_calc.solve_mission(mission, 0, kt2ms(135), 1); % starts at 135 kt at full weight
    res = res_cal(res, W_final, weightRatio(0, geom));
end