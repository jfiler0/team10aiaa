initialize
matlabSetup

build_f18_template

settings = readSettings();

geom = loadAircraft("f18_superhornet", settings);
geom = updateGeom(geom, settings, true);

geom =  setLoadout(geom, ["AIM-9X" "" "" "" "" "" "" "AIM-9X"]);
geom_strike =  setLoadout(geom, ["AIM-9X" "MK-83" "MK-83" "FPU-12" "FPU-12" "MK-83" "MK-83" "AIM-9X"]);
% geom =  setLoadout(geom, ["AIM-9X" "" "FPU-12" "" "" "FPU-12" "" "AIM-9X"]);

model = model_class(settings, geom);
perf = performance_class(model);

fprintf("F18 listed empty weight: 31855 lb. Code value: %.0f lb / %.0f lb (clean/basic)\n", N2lb(geom.weights.empty.v), N2lb(weightRatio(0, geom))) %
fprintf("F18 listed mtow weight: 66000 lb. Code value: %.0f\n", N2lb(geom.weights.mtow.v))
fprintf("F18 listed internal fuel weight: 14850 lb. Code value: %.0f\n", N2lb(geom.weights.max_fuel_weight.v))
fprintf("F18 combat empty weight (stores but no fuel)/mtow ~39,351lb / 60,729lb. Code: %.0f (empty) / %.0f (mtow)\n", N2lb(weightRatio(0, geom_strike)), N2lb(weightRatio(1, geom_strike)))

perf.clear_data();
[v_land_mtow, glide_angle] = compute_landing_speed(perf, 1);
v_land_empty = compute_landing_speed(perf, 0);

fprintf("Typical F18 landing speed as around 120kt. Our code predicts %.1f - %.1f kt (empty-mtow)\n", ms2kt(v_land_empty), ms2kt(v_land_mtow))
fprintf("For the hornet, the approach glide angle should be 3.5 deg. We get %.4g deg\n", glide_angle);

sea_level_dash_mach_mtow = compute_max_mach_at_h(perf, 1, 0); perf.clear_data();
sea_level_dash_mach_empty = compute_max_mach_at_h(perf, 0, 0); perf.clear_data();

fprintf("Typical F18 sea level dash: 1.03. Our code predicts %.3f - %.3f(empty-mtow)\n", sea_level_dash_mach_empty, sea_level_dash_mach_mtow)

perf.model.geom = setLoadout(perf.model.geom, ["AIM-9X" "" "" "" "" "" "" "AIM-9X"]);
[~, max_mach_mtow] = compute_max_mach(perf, 1); perf.clear_data();
[~, max_mach_empty] = compute_max_mach(perf, 0); perf.clear_data();

fprintf("Typical F18 max mach: 1.65. Our code predicts %.3f - %.3f(empty-mtow)\n", max_mach_empty, max_mach_mtow)

W = 0; % not actually getting max performance
perf.model.clear_mem(); perf.clear_data(); perf.model.cond = generateCondition(geom, 0, 0.5, 1, W, 0.9); 
fprintf("Max Rate of Climb Sealevel (mil) (M0.5) (empty): 12fpm. Code: %.2f\n", m2ft(perf.ExcessPower)*60/1000);

perf.model.clear_mem(); perf.clear_data(); perf.model.cond = generateCondition(geom, 0, 0.5, 1, W, 1);
fprintf("Max Rate of Climb Sealevel (AB) (M0.5) (empty): 44fpm. Code: %.2f\n", m2ft(perf.ExcessPower)*60/1000);

fun = @(R) eval_air2air(perf, R, 2) - geom.weights.empty.v;

R_max_air2air = fzero(fun, 400);

fprintf("F18 fighter escort range ~600nm. Calculated: %.1f\n", R_max_air2air)

% fprintf( "Found approximate F18 range (ferry): 1654 nm. Simulation of best total range: %.0f nm\n", m2nm(total_distance))

perf.model.clear_mem(); perf.clear_data();

[max_range_est, h_opt, M_opt, v_opt] = estimate_max_range(perf, 1);
fprintf( "Found approximate F18 range: 1654 nm. Estimate of best total range: %.0f nm (h=%.2f kf , M=%.2f, v=%.0f kt)\n", m2nm(max_range_est), m2ft(h_opt)/1000, M_opt, ms2kt(v_opt))
fprintf("Spot Factor = %.2f (folded wing area = %.2f ft2)\n", model.SpotFactor, m2ft(m2ft(geom.wing.fold_area.v)));% mission_calculator.plot_hist