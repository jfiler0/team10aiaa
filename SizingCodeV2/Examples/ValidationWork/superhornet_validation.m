initialize
matlabSetup

build_f18_template

settings = readSettings();

geom = loadAircraft("f18_superhornet", settings);

model = model_class(settings, geom);
perf = performance_class(model);

fprintf("F18 listed empty weight: ~32000f lb. Code value: %.0f\n", N2lb(geom.weights.empty.v))
fprintf("F18 listed mtow weight: ~50000f lb. Code value: %.0f\n", N2lb(geom.weights.mtow.v))

v_land_mtow = compute_landing_speed(perf, 1);
v_land_empty = compute_landing_speed(perf, 0);

fprintf("Typical F18 landing speed as around 120kt. Our code predicts %.1f - %.1f kt (empty-mtow)\n", ms2kt(v_land_empty), ms2kt(v_land_mtow))

sea_level_dash_mach_mtow = compute_max_mach_at_h(perf, 1, 0);
sea_level_dash_mach_empty = compute_max_mach_at_h(perf, 0, 0);

fprintf("Typical F18 sea level dash: ~. Our code predicts %.3f - %.3f(empty-mtow)\n", sea_level_dash_mach_empty, sea_level_dash_mach_mtow)

[~, max_mach_mtow] = compute_max_mach(perf, 1);
[~, max_mach_empty] = compute_max_mach(perf, 0);

fprintf("Typical F18 max mach: ~. Our code predicts %.3f - %.3f(empty-mtow)\n", max_mach_empty, max_mach_mtow)