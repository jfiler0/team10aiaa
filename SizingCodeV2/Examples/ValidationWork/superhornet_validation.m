initialize
matlabSetup

build_f18_template

settings = readSettings();

geom = loadAircraft("f18_superhornet", settings);
geom =  setLoadout(geom, ["AIM-9X" "" "" "" "" "" "" "AIM-9X"]);
geom_strike =  setLoadout(geom, ["AIM-9X" "MK-83" "MK-83" "FPU-12" "FPU-12" "MK-83" "MK-83" "AIM-9X"]);
% geom =  setLoadout(geom, ["AIM-9X" "" "FPU-12" "" "" "FPU-12" "" "AIM-9X"]);

model = model_class(settings, geom);
perf = performance_class(model);

fprintf("F18 listed empty weight: 30564 lb. Code value: %.0f\n", N2lb(geom.weights.empty.v))
fprintf("F18 listed mtow weight: 66000 lb. Code value: %.0f\n", N2lb(geom.weights.mtow.v))
fprintf("F18 listed internal fuel weight: 14850 lb. Code value: %.0f\n", N2lb(geom.weights.max_fuel_weight.v))
fprintf("F18 combat empty weight (stores but no fuel)/mtow ~39,351lb / 60,729lb. Code: %.0f (empty) / %.0f (mtow)\n", N2lb(weightRatio(0, geom_strike)), N2lb(weightRatio(1, geom_strike)))


[v_land_mtow, glide_angle] = compute_landing_speed(perf, 1);
v_land_empty = compute_landing_speed(perf, 0);

fprintf("Typical F18 landing speed as around 120kt. Our code predicts %.1f - %.1f kt (empty-mtow)\n", ms2kt(v_land_empty), ms2kt(v_land_mtow))
fprintf("For the hornet, the approach glide angle should be 3.5 deg. We get %.4g deg\n", glide_angle);

sea_level_dash_mach_mtow = compute_max_mach_at_h(perf, 1, 0);
sea_level_dash_mach_empty = compute_max_mach_at_h(perf, 0, 0);

fprintf("Typical F18 sea level dash: 1.03. Our code predicts %.3f - %.3f(empty-mtow)\n", sea_level_dash_mach_empty, sea_level_dash_mach_mtow)

[~, max_mach_mtow] = compute_max_mach(perf, 1);
[~, max_mach_empty] = compute_max_mach(perf, 0);

fprintf("Typical F18 max mach: 1.65. Our code predicts %.3f - %.3f(empty-mtow)\n", max_mach_empty, max_mach_mtow)

[max_range_est, h_opt, M_opt] = estimate_max_range(perf, 1);
fprintf( "Found approximate F18 range: ~ nm. Estimate of best total range: %.0f nm (h=%.2f kf , M=%.2f)\n", m2nm(max_range_est), h_opt/1000, M_opt )

W = 0; % not actually getting max performance
perf.model.clear_mem(); perf.clear_data(); perf.model.cond = generateCondition(geom, 0, 0.5, 1, W, 0.9); 
fprintf("Max Rate of Climb Sealevel (mil) (M0.5) (empty): 12fpm. Code: %.2f\n", m2ft(perf.ExcessPower)*60/1000);

perf.model.clear_mem(); perf.clear_data(); perf.model.cond = generateCondition(geom, 0, 0.5, 1, W, 1);
fprintf("Max Rate of Climb Sealevel (AB) (M0.5) (empty): 44fpm. Code: %.2f\n", m2ft(perf.ExcessPower)*60/1000);

% levelflight_performance_plots(perf,50)

% plot_performance(geom, perf, 50)
max_performance_plots(perf, 50)
% displayAircraftGeom(geom)

% % PRELOAD THE MISSION CALCULATOR
% mission_calculator = mission_calculator(perf, settings);
% mission_calculator.record_hist = false;
% mission_calculator.do_print = false;
% mission_calculator.build_map(); % assembles v, h, W map for key performance info
% mission = readMissionStruct("Air2Air_700nm");
% 
% % Sample range scalers from 0.5 to 2
% scaler_vec = linspace(0.75, 1.5, 50);
% residual_vec = zeros(size(scaler_vec));
% 
% for i = 1:length(scaler_vec)
%     residual_vec(i) = fun(mission, mission_calculator, scaler_vec(i), geom);
% end
% 
% % Find where residual crosses zero (changes sign)
% sign_change = find(diff(sign(residual_vec)) ~= 0, 1, 'first');
% 
% if isempty(sign_change)
%     warning('No zero crossing found. Using closest value.');
%     [~, idx] = min(abs(residual_vec));
%     range_scaler = scaler_vec(idx);
% else
%     % Interpolate to get more accurate zero crossing
%     x1 = scaler_vec(sign_change);
%     x2 = scaler_vec(sign_change + 1);
%     y1 = residual_vec(sign_change);
%     y2 = residual_vec(sign_change + 1);
%     range_scaler = x1 - y1 * (x2 - x1) / (y2 - y1);
% end
% 
% % Plot the residual
% figure('Name', 'Range Scaler Optimization');
% plot(scaler_vec, residual_vec, 'b-', 'LineWidth', 2);
% hold on;
% plot(range_scaler, 0, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
% yline(0, 'k--', 'LineWidth', 1);
% grid on;
% xlabel('Range Scaler');
% ylabel('Residual (W_{final} - W_{empty}) [N]');
% title('Mission Range Optimization');
% legend('Residual', 'Optimal Point', 'Target', 'Location', 'best');
% hold off;
% 
% function res = fun(mission, mission_calculator, range_scaler, geom)
%     mission = scale_mission_range(mission, range_scaler);
%     W_final = mission_calculator.solve_mission(mission, 0, 150, 1);
%     res = W_final - geom.weights.empty.v;
% end
% 
% % range_scaler = 0.82;
% 
% mission = scale_mission_range(mission, range_scaler);
% mission_calculator.record_hist = true;
% [W_end, total_distance] = mission_calculator.solve_mission(mission, 0, 150, 1);
% 
% fprintf("Final Scaler = %.3g | total radius = %.3g nm | W_end - W_E", range_scaler, m2nm(total_distance)/2, W_end - geom.weights.empty.v)
% 
% mission_calculator.plot_hist