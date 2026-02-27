% NAME: test_functions_2
% PURPOSE:
%   Replaces test_functions with the new aircraft class. Demonsrates how to load in all the classes and run basic calls

% MAKE SURE TO RUN initialize.m

initialize
matlabSetup
build_kevin_cad

settings = readSettings();

% geom = loadAircraft("f18_superhornet", settings);

geom = loadAircraft("kevin_cad", settings);

geom = setLoadout(geom, ["AIM-9X" "" "" "AIM-120" "AIM-120" "" "" "AIM-9x"]);

% 3599 iterations with no adaptive

cond = generateCondition(geom, 0, 0.5, 1, 1, 0.3);
model = model_class(settings, geom, cond);
perf = performance_class(model);
% max_performance_plots(perf, 50)
% levelflight_performance_plots(perf, 50)

mission_calculator = mission_calculator(perf);
mission_calculator.record_hist = true;
mission_calculator.do_print = true;

mission = readMissionStruct("Ferry_Mission_Test");
% mission = readMissionStruct("Simple_Loiter_Mission");
% mission = readMissionStruct("Simple_Range_Mission");

tic
mission_calculator.solve_mission(mission);
toc

mission_calculator.plot_hist

% % displayAircraftGeom(geom);

%% STORAGE

% N = 50;
% model.cond = levelFlightCondition(perf, linspace(0, 1000, N), linspace(0.5, 1.5, N), linspace(0.5, 1, N));
% 
% perf.ExcessThrust

% % Actually calling the big 4 analyisis functions:
% fprintf("cost = %.6f mil\n", model.COST )
% fprintf("CDW = %.6f\n", model.CDw )
% fprintf("CLa = %.6f\n", model.CLa )
% fprintf("CDi = %.6f\n", model.CDi )
% 
% % The propulsion function is a bit more complicated beacuse it outputs a vector [Thrust Available, TSFC, alpha] instead of a scaler
% prop_out = model.PROP;
% fprintf("For h = %.0f m + M = %.3f. TA = %.3f kN, TSFC = %.3g kg/(Ns), alpha = %.4f\n", cond.h.v, cond.M.v, prop_out(1, :)/1000, prop_out(2, :), prop_out(3, :))

% PLOTTING
%     Runs the main models with vector calls instead and plots them

% plot_models(geom, model, 200)
% plot_performance(geom, perf, 200);

% geom = editGeom(geom, "wing.AR", 2);

%% Weight Calculation

% Builds a struct of weight components
% weight_comps = getRaymerWeightStruct(geom);

% For AVL
% generatePlane(geom);

% perf.ClimbAngle

% cost_struct = xanderscript_modified(geom, true, false);

% model.COST
% 
% model.CDi
% 
% perf.ExcessThrust

% Remove vtail and LERX requirements to be more general to other planes
% Want the geometry display figure to show stores as cylinders
% Need a better CD0 model - more as flat plate with mach number corrections

% Whats next?
%   General function for making a map to speed up using interpolation
%   Actually running missions - with the sub missions
%       Finding/tracking the optimal TSFC


% mission testing

% starting
% % Run and record history
% hi = 10000;
% vi = 600;
% Wi = geom.weights.mtow.v;
% Ri = 0;
% 
% t_vec = linspace(1, 10000, 800);
% dt = t_vec(2) - t_vec(1);
% 
% N = length(t_vec);
% hist = zeros(N, 4);
% for i = 1:N
%     [hi, vi, Wi, Ri] = cruise_step(perf, hi, vi, Wi, Ri, dt);
%     hist(i, :) = [hi, vi, Wi, Ri];
% end
% 
% figure('Name', 'Cruise Trajectory Diagnostics');
% 
% subplot(2,2,1);
% plot(t_vec, hist(:,1));
% xlabel('Time [s]'); ylabel('Altitude [m]');
% title('Altitude vs Time');
% grid on;
% 
% subplot(2,2,2);
% plot(t_vec, hist(:,2));
% xlabel('Time [s]'); ylabel('Velocity [m/s]');
% title('Velocity vs Time');
% grid on;
% 
% subplot(2,2,3);
% plot(t_vec, hist(:,3));
% xlabel('Time [s]'); ylabel('Weight [N]');
% title('Weight vs Time');
% grid on;
% 
% subplot(2,2,4);
% plot(hist(:,4)/1000, hist(:,1));
% xlabel('Range [km]'); ylabel('Altitude [m]');
% title('Altitude vs Range');
% grid on;
% 
% % cruise_step(perf, 0, 150, geom.weights.mtow.v, 0, 1)
% 
% function [hi, vi, Wi, Ri] = cruise_step(perf, h0, v0, W0, R0, dt)
% 
%     angle_max = 10; % max/min 10 deg climb angle
% 
%     dh = 10; % 1 m
%     dv = 5; % 1 m/s
% 
%     perf.model.clear_mem(); perf.clear_data();
%     % Central DIfference
%     dRbar_dh = ( Rbar_Term(perf, h0+dh, v0, W0) - Rbar_Term(perf, h0-dh, v0, W0) ) / (2*dh);
%     dRbar_dv = ( Rbar_Term(perf, h0, v0+dv, W0) - Rbar_Term(perf, h0, v0-dv, W0) ) / (2*dv);
% 
%     dh_damp = 5E-7; % When less than this it stops using max climb
%     dv_damp = 5E-6; % When less than this it stops going to max/min throttle
% 
%     target_climb_angle = - angle_max * min(1, abs(dRbar_dh)/dh_damp ) * sign(dRbar_dh); % negative on the front since minimization
%     PE_target = v0 * sind(target_climb_angle);
% 
%     % Throttle to maintain target climb rate
%     cond = P_Specified_Condition(perf, PE_target, h0, v0, W0);
%     climbing_throttle = cond.throttle.v; % or this could be descening and less than level_throttle
% 
%     if dRbar_dv > 0
%         % we need slow down (we want to go in the negative direction)
%         throttle = climbing_throttle * max( 1 - abs(dRbar_dv)/dv_damp, 0 );
%     else
%         % need to go faster
%         throttle = climbing_throttle + (1 - climbing_throttle) * min( 1, abs(dRbar_dv)/dv_damp );
%     end
% 
%     cond = generateCondition(perf.model.geom, h0, v0, 1, W0, throttle);
% 
%     perf.model.cond = cond;
% 
%     climb_angle = perf.ClimbAngle( perf.ExcessPower - PE_target ); % find the climb angle to leave our axial accelleration
% 
%     % [hi, vi, Wi, Ri]
%     hi = h0 + cond.vel.v * sind(climb_angle) * dt;
%     vi = v0 + perf.AxialAccelleration(PE_target) * perf.model.settings.g_const * dt;
%     Wi = W0 - perf.model.settings.g_const * perf.mdotf * dt;
%     Ri = R0 + v0 * dt;
% 
%     % fprintf("dRbar_dh = %.4g , dRbar_dv = %.4g , climb_angle = %.4g , throttle = %.4g\n", dRbar_dh, dRbar_dv, climb_angle, throttle)
% end
% 
% function Rbar = Rbar_Term(perf, h, v, W)
%     % Rbar must be minimized to get the best cruise condition
%     perf.model.cond = levelFlightCondition(perf, h, v, W);
%     Rbar = perf.Rbar;
%     perf.model.clear_mem(); perf.clear_data();
% end

% % --- Surface plots around final cruise point ---
% h_final = hi;
% v_final = vi;
% W_final = Wi;
% 
% Nh = 30;
% Nv = 30;
% dh_range = 50;
% dv_range = 10;
% 
% h_sweep = linspace(h_final - dh_range, h_final + dh_range, Nh);
% v_sweep = linspace(v_final - dv_range, v_final + dv_range, Nv);
% [H_surf, V_surf] = meshgrid(h_sweep, v_sweep);
% 
% h_long = H_surf(:)';
% v_long = V_surf(:)';
% W_long = W_final * ones(size(h_long));
% 
% % Compute Rbar at every point
% Rbar_long   = arrayfun(@(h,v) Rbar_Term(perf, h, v, W_final), h_long, v_long);
% 
% % Compute level flight conditions for throttle and TSFC
% for k = 1:length(h_long)
%     cond_k = levelFlightCondition(perf, h_long(k), v_long(k), W_final);
%     perf.model.cond = cond_k;
%     throttle_long(k) = cond_k.throttle.v;
%     TSFC_long(k)     = perf.TSFC;
%     mdotf_long(k)    = perf.mdotf;
% end
% 
% % Central difference gradients across the grid
% dh = h_sweep(2) - h_sweep(1);
% dv = v_sweep(2) - v_sweep(1);
% Rbar_surf    = reshape(Rbar_long,    size(H_surf));
% throttle_surf = reshape(throttle_long, size(H_surf));
% TSFC_surf    = reshape(TSFC_long,    size(H_surf));
% mdotf_surf   = reshape(mdotf_long,   size(H_surf));
% 
% [dRbar_dv_surf, dRbar_dh_surf] = gradient(Rbar_surf, dv, dh);
% 
% % Plot
% figure('Name', 'Cruise Point Continuity Diagnostics');
% 
% subplot(2,3,1);
% surf(H_surf, V_surf, Rbar_surf, 'EdgeColor', 'none'); view(2); shading interp;
% colorbar; xlabel('h [m]'); ylabel('v [m/s]'); title('Rbar');
% hold on; plot3(h_final, v_final, max(Rbar_surf(:)), 'kx', 'MarkerSize', 12, 'LineWidth', 2);
% 
% subplot(2,3,2);
% surf(H_surf, V_surf, dRbar_dh_surf, 'EdgeColor', 'none'); view(2); shading interp;
% colorbar; xlabel('h [m]'); ylabel('v [m/s]'); title('dRbar/dh');
% hold on; plot3(h_final, v_final, max(dRbar_dh_surf(:)), 'kx', 'MarkerSize', 12, 'LineWidth', 2);
% 
% subplot(2,3,3);
% surf(H_surf, V_surf, dRbar_dv_surf, 'EdgeColor', 'none'); view(2); shading interp;
% colorbar; xlabel('h [m]'); ylabel('v [m/s]'); title('dRbar/dv');
% hold on; plot3(h_final, v_final, max(dRbar_dv_surf(:)), 'kx', 'MarkerSize', 12, 'LineWidth', 2);
% 
% subplot(2,3,4);
% surf(H_surf, V_surf, throttle_surf, 'EdgeColor', 'none'); view(2); shading interp;
% colorbar; xlabel('h [m]'); ylabel('v [m/s]'); title('Level Flight Throttle');
% hold on; plot3(h_final, v_final, max(throttle_surf(:)), 'kx', 'MarkerSize', 12, 'LineWidth', 2);
% 
% subplot(2,3,5);
% surf(H_surf, V_surf, TSFC_surf, 'EdgeColor', 'none'); view(2); shading interp;
% colorbar; xlabel('h [m]'); ylabel('v [m/s]'); title('TSFC');
% hold on; plot3(h_final, v_final, max(TSFC_surf(:)), 'kx', 'MarkerSize', 12, 'LineWidth', 2);
% 
% subplot(2,3,6);
% surf(H_surf, V_surf, mdotf_surf, 'EdgeColor', 'none'); view(2); shading interp;
% colorbar; xlabel('h [m]'); ylabel('v [m/s]'); title('mdotf');
% hold on; plot3(h_final, v_final, max(mdotf_surf(:)), 'kx', 'MarkerSize', 12, 'LineWidth', 2);
% 
% sgtitle(sprintf('Cruise point: h=%.1f m, v=%.1f m/s', h_final, v_final));