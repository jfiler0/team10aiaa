matlabSetup
settings = readSettings();

% TODO
%   Check glide angle

file_name = "HellstingerV3";
geom = readAircraftFile(file_name);
geom = updateGeom(geom, settings, true); % true -> update prop
geom = setLoadout(geom, ["" "" "" "" "" "" "" ""]);
model = model_class(settings, geom);
perf = performance_class(model);

displayAircraftGeom(geom)

%% LANDING

[v_land, glide_angle, throttle] = compute_landing_speed(perf, geom.weights.mtow.v); perf.clear_data(); % landing at mtow
fprintf("LANDING | MTOW (%.0f lb) | vel = %.3f kt , glide_angle = %.3f deg , throttle setting = %.3f perc\n", N2lb(geom.weights.mtow.v), ms2kt(v_land), glide_angle, throttle)

rfp_landing_weight = compute_rfp_landing_weight(perf, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "" "" ""]); % half stores dropped
[v_land, glide_angle, throttle] = compute_landing_speed(perf, rfp_landing_weight); perf.clear_data(); % landing at rfp req
fprintf("LANDING | RFP REQ WEIGHT (%.0f lb) | vel = %.3f kt < 145, glide_angle = %.3f deg , throttle setting = %.3f perc\n", N2lb(rfp_landing_weight), ms2kt(v_land), glide_angle, throttle)

[v_land, glide_angle, throttle] = compute_landing_speed(perf, 0); perf.clear_data(); % landing at empty weight
fprintf("LANDING | EMPTY WEIGHT (%.0f lb) | vel = %.3f kt , glide_angle = %.3f deg , throttle setting = %.3f perc\n", N2lb(weightRatio(0, perf.model.geom)), ms2kt(v_land), glide_angle, throttle)

fprintf("Estimate of external storage max weight: %.3f lb\n", N2lb(geom.weights.mtow.v - geom.weights.empty.v - geom.weights.max_fuel_weight.v))

fprintf("Max internal fuel weight: %.3f lb\n", N2lb(geom.weights.max_fuel_weight.v))

fprintf("Total Cost: %.3f mil\n", model.COST);

%% MISSIONS

geom = setLoadout(geom, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"]);

fprintf("STRIKE TAKEOFF WEIGHT = %.0f lb\n", N2lb(weightRatio(1, geom)))

[W_final, empty_weight] = eval_air2gnd(perf, 700, 50, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"]);
fprintf("Fuel remaing for RFP required 700nm, 50nm dash strike mission: %.0f lb\n", W_final-empty_weight)

[W_final, empty_weight] = eval_air2air(perf, 700, 2, ["AIM-9X" "AIM-120" "AIM-120" "FPU-12" "FPU-12" "AIM-120" "AIM-120" "AIM-9x"]);
fprintf("Fuel remaing for RFP required 700nm, 2min combat mission: %.0f lb\n", W_final-empty_weight)

range_nm = get_mission_range(@eval_air2gnd, 50, perf, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"]);
fprintf("Max range for 50nm dash strike mission: %.1f nm > 700\n", range_nm)

range_nm = get_mission_range(@eval_air2air, 2, perf, ["AIM-9X" "AIM-120" "AIM-120" "FPU-12" "FPU-12" "AIM-120" "AIM-120" "AIM-9x"]);
fprintf("Max range for 2min combat mission: %.1f nm > 700\n", range_nm)

range_nm = get_mission_range(@eval_ferry, 0, perf, ["AIM-9X" "" "" "FPU-12" "FPU-12" "" "" "AIM-9x"]);
fprintf("Max range for 2 tank ferry with no loiter: %.1f nm\n", range_nm)

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

%% MAX MACH - SEA LEVEL

perf.clear_data();
perf.model.geom = setLoadout(geom, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"]);
max_mach = compute_max_mach_at_h(perf, 1, 0);

fprintf("Sealevel dash mach at full fuel weight + all strike stores: %.2f\n", max_mach)

perf.clear_data();
perf.model.geom = setLoadout(geom, ["" "" "" "" "" "" "" ""]);
max_mach = compute_max_mach_at_h(perf, 0, 0);

fprintf("Sealevel dash mach at empty weight + no stores: %.2f\n", max_mach)

%% MAX MACH - 30kf

perf.clear_data();
perf.model.geom = setLoadout(geom, ["AIM-9X" "AIM-120" "AIM-120" "FPU-12" "FPU-12" "AIM-120" "AIM-120" "AIM-9x"]);
max_mach = compute_max_mach_at_h(perf, 1, ft2m(30000));

fprintf("30kft max mach at full fuel weight + all combat stores: %.2f\n", max_mach)

perf.clear_data();
perf.model.geom = setLoadout(geom, ["" "" "" "" "" "" "" ""]);
max_mach = compute_max_mach_at_h(perf, 0, ft2m(30000));

fprintf("30kft max mach at empty weight + no stores: %.2f\n", max_mach)

%% MAX MACH - TOTAL

perf.clear_data();
perf.model.geom = setLoadout(geom, ["AIM-9X" "AIM-120" "AIM-120" "FPU-12" "FPU-12" "AIM-120" "AIM-120" "AIM-9x"]);
[~, max_mach] = compute_max_mach(perf, 1);

fprintf("Max mach at full fuel weight + all combat stores: %.2f\n", max_mach)

perf.clear_data();
perf.model.geom = setLoadout(geom, ["" "" "" "" "" "" "" ""]);
[~, max_mach] = compute_max_mach(perf, 0);

fprintf("Max mach at empty weight + no stores: %.2f\n", max_mach)

%% MAX COMBAT ALT

perf.clear_data();
perf.model.geom = setLoadout(geom, ["AIM-9X" "AIM-120" "AIM-120" "FPU-12" "FPU-12" "AIM-120" "AIM-120" "AIM-9x"]);
[h_max, ~] = compute_combat_ceiling(perf, 1);

fprintf("Max combat alt (500ft/min) at full fuel weight + all combat stores: %.2f kft\n", m2ft(h_max)/1000)

perf.clear_data();
perf.model.geom = setLoadout(geom, ["" "" "" "" "" "" "" ""]);
[h_max, ~] = compute_combat_ceiling(perf, 0);

fprintf("Max combat alt (500ft/min) at empty weight + no stores: %.2f kft\n", m2ft(h_max)/1000)

%% RATE OF CLIMB

perf.clear_data();
geom.prop.num_engine.v = 1;
geom = updateGeom(geom, settings);
model.geom = geom;
model.cond = generateCondition(geom, 0, 0.5, 1, 0.5, 1);
fprintf("SEROC = %.2ft kft/min", m2ft(perf.ExcessPower)*60/1000)