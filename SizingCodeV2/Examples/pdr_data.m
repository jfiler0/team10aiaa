matlabSetup;
settings = readSettings();

% TODO
%   Check glide angle

file_name = "HellstingerV3";
geom = readAircraftFile(file_name);
geom = updateGeom(geom, settings, true); % true -> update prop
geom = setLoadout(geom, ["" "" "" "" "" "" "" ""]);
model = model_class(settings, geom);
perf = performance_class(model);
cond = levelFlightCondition(perf, 1000, 0.5, 0.5);
model.cond = cond;

file_name = "f18_superhornet";
geom_f18 = readAircraftFile(file_name);
geom_f18= updateGeom(geom_f18, settings, true); % true -> update prop
model_f18 = model_class(settings, geom_f18);
perf_f18 = performance_class(model_f18);

% range_nm_air2air_max = get_mission_range(@eval_air2air, 2, perf, ["AIM-9X" "AIM-120" "AIM-120" "" "" "" "AIM-120" "AIM-120" "AIM-9x"]);
% fprintf("<5> [F/A-24 HELLSTINGER] COMBAT REACH (NO TANK) = %.3f nm\n", range_nm_air2air_max);
% 
% geom = setLoadout(geom, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"]);
% 
% fprintf("STRIKE TAKEOFF WEIGHT - MTOW = %.0f lb\n", N2lb(weightRatio(1, geom) - geom.weights.mtow.v))

% LISTS OUT ALL THE DATA POINTS NEEDED FOR SLIDES
fprintf("<4> [F/A-24 HELLSTINGER] COST = %.5f mil\n", model.COST)

%% MAX MACH - 30kf

perf.clear_data();
perf.model.geom = setLoadout(geom, ["AIM-9X" "AIM-120" "AIM-120" "FPU-12" "FPU-12" "FPU-12" "AIM-120" "AIM-120" "AIM-9x"]);
max_mach_30_mtow = compute_max_mach_at_h(perf, 1, ft2m(30000));

perf.clear_data();
perf.model.geom = setLoadout(geom, ["" "" "" "" "" "" "" ""]);
max_mach_30_empty = compute_max_mach_at_h(perf, 0, ft2m(30000));

max_mach_30 = (max_mach_30_mtow + max_mach_30_empty)/2;

fprintf("<5> [F/A-24 HELLSTINGER] MAX MACH 30kft = %.3f\n", max_mach_30);

%% MISSION REACH

range_nm_air2air_max = get_mission_range(@eval_air2air, 2, perf, ["AIM-9X" "AIM-120" "AIM-120" "FPU-12" "FPU-12" "FPU-12" "AIM-120" "AIM-120" "AIM-9x"]);
fprintf("<5> [F/A-24 HELLSTINGER] COMBAT REACH = %.3f nm\n", range_nm_air2air_max);

range_nm_air2gnd_max = get_mission_range(@eval_air2gnd, 50, perf, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"]);
fprintf("<5> [F/A-24 HELLSTINGER] STRIKE REACH = %.3f nm\n", range_nm_air2gnd_max);
% 
fprintf("<9> [Understanding the Threat] COMBAT REACH = %.3f nm\n", range_nm_air2air_max);
fprintf("<9> [Understanding the Threat] STRIKE REACH = %.3f nm\n", range_nm_air2gnd_max);

range_nm_air2air_max_f18 = get_mission_range(@eval_air2air, 2, perf_f18, ["AIM-9X" "AIM-120" "AIM-120" "FPU-12" "FPU-12" "FPU-12" "AIM-120" "AIM-120" "AIM-9x"]);
fprintf("<9> [Understanding the Threat] F18 COMBAT REACH = %.3f nm\n", range_nm_air2air_max_f18);

range_nm_air2gnd_max_f18 = get_mission_range(@eval_air2gnd, 50, perf_f18, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"]);
fprintf("<9> [Understanding the Threat] F18 STRIKE REACH = %.3f nm\n", range_nm_air2gnd_max_f18);

%% MEASURES OF MERIT

fprintf("<16> [Measures of Merit] COST = %.5f mil\n", model.COST)
% fprintf("<16> [Measures of Merit] CRUISE SFC = %.5f lb/lbf.hr\n", 0) % ???
fprintf("<16> [Measures of Merit] COMBAT RADIUS = %.5f nm\n", range_nm_air2gnd_max)

max_combat_time = get_mission_input_max(@eval_air2air, 700, perf, ["AIM-9X" "AIM-120" "AIM-120" "FPU-12" "FPU-12" "FPU-12" "AIM-120" "AIM-120" "AIM-9x"]);
fprintf("<16> [Measures of Merit] 700nm COMBAT TIME = %.3f min\n", max_combat_time)

max_dash_nm = get_mission_input_max(@eval_air2gnd, 700, perf, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"]);
fprintf("<16> [Measures of Merit] 700nm STRIKE DASH = %.3f nm\n", max_dash_nm)

max_time_hr = esimtate_max_loiter(perf);
fprintf("<16> [Measures of Merit] MAX LOITER TIME = %.3f hr\n", max_time_hr)

perf.clear_data();
perf.model.geom = setLoadout(geom, ["AIM-9X" "AIM-120" "AIM-120" "FPU-12" "FPU-12" "FPU-12" "AIM-120" "AIM-120" "AIM-9x"]);
[combat_ceiling_mtow, ~] = compute_combat_ceiling(perf, 1, ft2m(500)/60); % use 50 fpm as service ceiling
perf.clear_data();
perf.model.geom = setLoadout(geom, ["" "" "" "" "" "" "" ""]);
[combat_ceiling_empty, ~] = compute_combat_ceiling(perf, 0, ft2m(500)/60); % use 50 fpm as service ceiling

combat_ceiling = (combat_ceiling_mtow + combat_ceiling_empty)/2;
fprintf("<16> [Measures of Merit] COMBAT CEILING = %.3f kft\n", m2ft(combat_ceiling)/1000)

perf.clear_data();
perf.model.geom = setLoadout(geom, ["AIM-9X" "AIM-120" "AIM-120" "FPU-12" "FPU-12" "FPU-12" "AIM-120" "AIM-120" "AIM-9x"]);
[h_max_mach_mtow, max_mach_mtow] = compute_max_mach(perf, 1);

perf.clear_data();
perf.model.geom = setLoadout(geom, ["" "" "" "" "" "" "" ""]);
[h_max_mach_empty, max_mach_empty] = compute_max_mach(perf, 0);

max_mach = (max_mach_mtow + max_mach_empty)/2;
h_max_mach = (h_max_mach_mtow + h_max_mach_empty)/2;

fprintf("<16> [Measures of Merit] MAX MACH = %.3f\n", max_mach)

perf.clear_data();
perf.model.geom = setLoadout(geom, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"]);
model.cond = generateCondition(geom, 0, 0.5, 1, 0.5, 1);

fprintf("<16> [Measures of Merit] SEA LEVEL CLIMB RATE = %.3f kft/min\n", m2ft(perf.ExcessPower)*60/1000)

perf.clear_data();
perf.model.geom = setLoadout(geom, ["AIM-9X" "AIM-120" "AIM-120" "FPU-12" "FPU-12" "FPU-12" "AIM-120" "AIM-120" "AIM-9x"]);

perf.clear_data();
[~, turn_rate_20kft] = compute_max_sustained_turn_at_h(perf, 0.5, ft2m(20000));
fprintf("<16> [Measures of Merit] 20kft SUSTAINED TURN = %.3f deg/s\n", turn_rate_20kft)

%% POWERPLANT

rfp_landing_weight = compute_rfp_landing_weight(perf, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "FPU-12" "" "" ""]); % half stores dropped
fprintf("<30> [Powerplant Thrust/TSFC] LANDING WEIGHT = %.3f lb\n", N2lb(rfp_landing_weight))

[v_land_rfp, ~, ~, landing_descent_rate_rfp] = compute_landing_speed(perf, rfp_landing_weight); perf.clear_data(); % landing at rfp req
fprintf("<30> [Powerplant Thrust/TSFC] LANDING SPEED = %.3f kt / APPROACH SPEED = %.3f kt\n", ms2kt(v_land_rfp), ms2kt(v_land_rfp));

perf.model.geom.prop.num_engine.v = 1;
perf.model.geom = updateGeom(perf.model.geom, perf.model.settings);
perf.model.clear_mem(); perf.clear_data();

perf.model.cond = generateCondition(perf.model.geom, perf.model.settings.tropical_day_alt, v_land_rfp*1.05, 1, rfp_landing_weight, 1); % full weight
ab_approach_seroc = perf.ExcessPower;
fprintf("<30> [Powerplant Thrust/TSFC] AB SEROC (TROPICAL) = %.3f ft/min\n", m2ft(ab_approach_seroc)*60)
perf.clear_data();

perf.model.cond = generateCondition(perf.model.geom, perf.model.settings.tropical_day_alt, v_land_rfp*1.05, 1, rfp_landing_weight, 0.9); % full weight
fprintf("<30> [Powerplant Thrust/TSFC] MIL SEROC (TROPICAL) = %.3f ft/min\n", m2ft(perf.ExcessPower)*60)
perf.clear_data(); 

perf.model.geom.prop.num_engine.v = 2;
perf.model.geom = updateGeom(perf.model.geom, perf.model.settings);
perf.model.clear_mem(); perf.clear_data();

perf.model.cond = levelFlightCondition(perf, h_max_mach, max_mach, 0.5);
fprintf("<30> [Powerplant Thrust/TSFC] MAX MACH TSFC = %.3f lb/lbf.hr\n", kgNs_2_lbmlbfhr(perf.TSFC))

%% AIRCRAFT VALIDATION
fprintf("<31> [Performance: Model Validation] ???\n")

%% MISSION RANGES

range_nm_air2air_notank = get_mission_range(@eval_air2air, 2, perf, ["AIM-9X" "AIM-120" "AIM-120" "" "" "" "AIM-120" "AIM-120" "AIM-9x"]);
fprintf("<35> [Performance Overview: Mission Range] COMBAT REACH (3 Tanks) = %.3f nm\n", range_nm_air2air_max);
fprintf("<35> [Performance Overview: Mission Range] COMBAT REACH (No Tanks) = %.3f nm\n", range_nm_air2air_notank);
fprintf("<35> [Performance Overview: Mission Range] F18 COMBAT REACH (still 3 tanks) = %.3f nm\n", range_nm_air2air_max_f18);

range_nm_air2gnd_notank = get_mission_range(@eval_air2gnd, 50, perf, ["AIM-9X" "Mk-83" "Mk-83" "" "" "" "Mk-83" "Mk-83" "AIM-9x"]);
fprintf("<35> [Performance Overview: Mission Range] STRIKE REACH (3 Tanks) = %.3f nm\n", range_nm_air2gnd_max);
fprintf("<35> [Performance Overview: Mission Range] STRIKE REACH (No Tanks) = %.3f nm\n", range_nm_air2gnd_notank);
fprintf("<35> [Performance Overview: Mission Range] F18 STRIKE REACH (still 3 tanks) = %.3f nm\n", range_nm_air2gnd_max_f18);

range_nm_ferry_max = get_mission_range(@eval_ferry, 0, perf, ["" "" "" "FPU-12" "FPU-12" "FPU-12" "" "" ""]);
fprintf("<35> [Performance Overview: Mission Range] FERRY REACH (3 Tanks) = %.3f nm\n", range_nm_ferry_max);

range_nm_ferry_notank = get_mission_range(@eval_ferry, 0, perf, ["" "" "" "" "" "" "" "" ""]);
fprintf("<35> [Performance Overview: Mission Range] FERRY REACH (No Tanks) = %.3f nm\n", range_nm_ferry_notank);

range_nm_ferry_f18 = get_mission_range(@eval_ferry, 0, perf_f18, ["" "" "" "FPU-12" "FPU-12" "FPU-12" "" "" ""]);
fprintf("<35> [Performance Overview: Mission Range] F18 FERRY REACH (still 3 tanks) = %.3f nm\n", range_nm_ferry_f18);

%% MISSION CAPABILITY

fprintf("<36> [Performance Overview: Mission Capability] 700nm STRIKE DASH = %.3f nm\n", max_dash_nm)
fprintf("<36> [Performance Overview: Mission Capability] 700nm COMBAT TIME = %.3f min\n", max_combat_time)
fprintf("<36> [Performance Overview: Mission Capability] 20kft SUSTAINED TURN = %.3f deg/s\n", turn_rate_20kft)

%% MAXIMUMS
fprintf("<37> [Performance Overview: Maximums ] MAX MACH 30kft = %.3f\n", max_mach_30);

perf.clear_data();
perf.model.geom = setLoadout(geom, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"]);
max_mach_sealevel_mtow = compute_max_mach_at_h(perf, 1, 0, 0.9);

perf.clear_data();
perf.model.geom = setLoadout(geom, ["" "" "" "" "" "" "" ""]);
max_mach_sealevel_empty = compute_max_mach_at_h(perf, 0, 0, 0.9);

max_mach_sealevel = (max_mach_sealevel_mtow + max_mach_sealevel_empty)/2;
fprintf("<37> [Performance Overview: Maximums] MAX MACH SEALEVEL (MIL) = %.3f\n", max_mach_sealevel);
fprintf("<37> [Performance Overview: Maximums] MAX MACH = %.3f\n", max_mach);
fprintf("<37> [Performance Overview: Maximums] COMBAT CEILING = %.3f kft\n", m2ft(combat_ceiling)/1000)

%% LANDING
fprintf("<57> [ Glide Slope and Pilot Visibility] LANDING SPEED = %.3f kt\n", ms2kt(v_land_rfp));
fprintf("<57> [ Glide Slope and Pilot Visibility] DESCENT RATE = %.3f ft/s\n", m2ft(landing_descent_rate_rfp));

%% COST INFO
fprintf("<69> [PSC Unit Costs and Life Cycle ] Xanderscript:\n")

cost_struct = xanderscript_modified(geom, true, false);

%% FINAL PITCH

fprintf("<77> [Why] COST = %.3f mil\n", model.COST);
fprintf("<77> [Why] MAX MACH 30kft = %.3f\n", max_mach_30);
fprintf("<77> [Why] MAX MACH SEALEVEL (MIL) = %.3f\n", max_mach_sealevel);
fprintf("<77> [Why] COMBAT REACH = %.3f nm\n", range_nm_air2air_max);

max_ext_store_weight = geom.weights.mtow.v - geom.weights.empty.v - geom.weights.max_fuel_weight.v;

fprintf("<77> [Why] MAX EXTERNAL STORE WEIGHT= %.3f nm\n", N2lb(max_ext_store_weight));
fprintf("<77> [Why] 20kft SUSTAINED TURN = %.3f deg/s\n", turn_rate_20kft)
fprintf("<77> [Why] APPROACH SEROC = %.3f ft/min\n", m2ft(ab_approach_seroc)*60)

% F18

fprintf("<77> [Why] (F18) COST = %.3f mil\n", perf_f18.model.COST);

% perf_f18.clear_data();
% perf_f18.model.geom = setLoadout(geom, ["AIM-9X" "AIM-120" "AIM-120" "FPU-12" "FPU-12" "FPU-12" "AIM-120" "AIM-120" "AIM-9x"]);
% max_mach_30_mtow_f18 = compute_max_mach_at_h(perf_f18, 1, ft2m(30000));
% 
% perf_f18.clear_data();
% perf_f18.model.geom = setLoadout(geom, ["" "" "" "" "" "" "" ""]);
% max_mach_30_empty_f18 = compute_max_mach_at_h(perf_f18, 0, ft2m(30000));
% 
% max_mach_30_f18 = (max_mach_30_mtow_f18 + max_mach_30_empty_f18)/2;
% 
% fprintf("<77> [Why] (F18) MAX MACH 30kft = %.3f\n", max_mach_30_f18);
% 
% perf_f18.clear_data();
% perf_f18.model.geom = setLoadout(geom, ["AIM-9X" "AIM-120" "AIM-120" "FPU-12" "FPU-12" "FPU-12" "AIM-120" "AIM-120" "AIM-9x"]);
% max_mach_h0_mtow_f18 = compute_max_mach_at_h(perf_f18, 1, 0);
% 
% perf_f18.clear_data();
% perf_f18.model.geom = setLoadout(geom, ["" "" "" "" "" "" "" ""]);
% max_mach_h0_empty_f18 = compute_max_mach_at_h(perf_f18, 0, 0);
% 
% max_mach_h0_f18 = (max_mach_h0_mtow_f18 + max_mach_h0_empty_f18)/2;
% 
% fprintf("<77> [Why] (F18) MAX MACH SEALEVEL = %.3f\n", max_mach_h0_f18);

range_nm_air2air_max_f18 = get_mission_range(@eval_air2air, 2, perf_f18, ["AIM-9X" "AIM-120" "AIM-120" "FPU-12" "FPU-12" "FPU-12" "AIM-120" "AIM-120" "AIM-9x"]);

fprintf("<77> [Why] (F18) COMBAT REACH = %.3f nm\n", range_nm_air2air_max_f18);

max_ext_store_weight = geom_f18.weights.mtow.v - geom_f18.weights.empty.v - geom_f18.weights.max_fuel_weight.v;

fprintf("<77> [Why] (F18) MAX EXTERNAL STORE WEIGHT= %.3f nm\n", N2lb(max_ext_store_weight));

perf_f18.clear_data();
[~, turn_rate_20kft_f18] = compute_max_sustained_turn_at_h(perf_f18, 0.5, ft2m(20000));

fprintf("<77> [Why] (F18) 20kft SUSTAINED TURN = %.3f deg/s\n", turn_rate_20kft_f18)

perf_f18.model.geom.prop.num_engine.v = 1;
perf_f18.model.geom = updateGeom(perf_f18.model.geom, perf_f18.model.settings);
perf_f18.model.clear_mem(); perf_f18.clear_data();

rfp_landing_weight_f18 = compute_rfp_landing_weight(perf_f18, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "FPU-12" "" "" ""]); % half stores dropped
[v_land_rfp_f18, ~, ~, ~] = compute_landing_speed(perf_f18, rfp_landing_weight_f18); perf_f18.clear_data(); % landing at rfp req

perf_f18.model.cond = generateCondition(perf_f18.model.geom, perf_f18.model.settings.tropical_day_alt, v_land_rfp_f18*1.05, 1, rfp_landing_weight_f18, 1); % full weight
ab_approach_seroc_f18 = perf_f18.ExcessPower;

perf_f18.model.geom.prop.num_engine.v = 2;
perf_f18.model.geom = updateGeom(perf_f18.model.geom, perf_f18.model.settings);
perf_f18.model.clear_mem(); perf_f18.clear_data();

fprintf("<77> [Why] (F18) APPROACH SEROC = %.3f ft/min\n", m2ft(ab_approach_seroc_f18)*60)

%% LANDING

[v_land, glide_angle, throttle, descent_rate] = compute_landing_speed(perf, geom.weights.mtow.v); perf.clear_data(); % landing at mtow
fprintf("LANDING | MTOW (%.0f lb) | vel = %.3f kt , glide_angle = %.3f deg , throttle setting = %.1f perc, descent rate = %.2f ft/s\n", N2lb(geom.weights.mtow.v), ms2kt(v_land), glide_angle, 100*throttle, m2ft(descent_rate))
v_cmea_rfp = compute_cmea(perf, geom.weights.mtow.v);
fprintf("       CMEA = %.2f kt\n", ms2kt(v_cmea_rfp));

[v_land, glide_angle, throttle, descent_rate] = compute_landing_speed(perf, 0); perf.clear_data(); % landing at empty weight
fprintf("LANDING | EMPTY WEIGHT (%.0f lb) | vel = %.3f kt , glide_angle = %.3f deg , throttle setting = %.1f perc, descent rate = %.2f ft/s\n", N2lb(weightRatio(0, perf.model.geom)), ms2kt(v_land), glide_angle, 100*throttle, m2ft(descent_rate))
fprintf("       CMEA = %.2f kt\n", ms2kt(compute_cmea(perf, 1)) );


fprintf("Max internal fuel weight: %.3f lb\n", N2lb(geom.weights.max_fuel_weight.v))

fprintf("Total Cost: %.3f mil\n", model.COST);



%% MISSIONS

geom = setLoadout(geom, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"]);

fprintf("STRIKE TAKEOFF WEIGHT = %.0f lb\n", N2lb(weightRatio(1, geom)))

[W_final, empty_weight] = eval_air2gnd(perf, 700, 50, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"]);
fprintf("Fuel remaing for RFP required 700nm, 50nm dash strike mission: %.0f lb\n", W_final-empty_weight)

[W_final, empty_weight] = eval_air2air(perf, 700, 2, ["AIM-9X" "AIM-120" "AIM-120" "FPU-12" "FPU-12" "FPU-12" "AIM-120" "AIM-120" "AIM-9x"]);
fprintf("Fuel remaing for RFP required 700nm, 2min combat mission: %.0f lb\n", W_final-empty_weight)


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

function input = get_mission_input_max(fun, range_nm, perf, loadout)
    try
        input = fzero(@(input) eval_res(perf, fun, range_nm, input, loadout), 1);
    catch exception
        input = NaN;
    end

    function res = eval_res(perf, fun, range_nm, input, loadout)
        [W_final, empty_weight] = fun(perf, range_nm, input, loadout);
        res = W_final-empty_weight;
    end
end



%% MAX TURNS

perf.clear_data();
[M_opt, turn_rate] = compute_max_sustained_turn_at_h(perf, 0.5, 0);
fprintf("Max sustained turn rate at sealevel (max), mid-mission weight: %.3f deg/s (M = %.3f)\n", turn_rate, M_opt)


%% RATE OF CLIMB

perf.clear_data();
geom.prop.num_engine.v = 1;
perf.model.geom = setLoadout(geom, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"]);
geom = updateGeom(geom, settings);
model.geom = geom;
model.cond = generateCondition(geom, 0, v_land_rfp, 1, 0.5, 1);
fprintf("SEROC - LANDING = %.2ft kft/min\n", m2ft(perf.ExcessPower)*60/1000)
perf.clear_data();
model.cond = generateCondition(geom, 0, v_cmea_rfp, 1, 0.5, 1);
fprintf("SEROC - CMEA = %.2ft kft/min\n", m2ft(perf.ExcessPower)*60/1000)
geom.prop.num_engine.v = 2; % back to normal
geom = updateGeom(geom, settings);
model.geom = geom;
perf.model.geom = setLoadout(geom, ["" "" "" "" "" "" "" ""]);
perf.clear_data();

%% Folding
fprintf("Folded span = %.2f ft\n", m2ft(geom.wing.fold_span.v));
fprintf("Spot Factor = %.2f ft (folded wing area = %.2f ft2)\n", model.SpotFactor, m2ft(m2ft(geom.wing.fold_area.v)));

%% LOITER
perf.model.geom = setLoadout(geom, ["AIM-9X" "AIM-120" "AIM-120" "FPU-12" "FPU-12" "FPU-12" "AIM-120" "AIM-120" "AIM-9x"]);
perf.clear_data();