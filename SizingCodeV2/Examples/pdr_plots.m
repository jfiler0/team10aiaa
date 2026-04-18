matlabSetup
settings = readSettings();

file_name = "f18_superhornet";
geom_f18 = readAircraftFile(file_name);
geom_f18= updateGeom(geom_f18, settings, true); % true -> update prop
model_f18 = model_class(settings, geom_f18);
perf_f18 = performance_class(model_f18);

file_name = "HellstingerV3_OPM";
geom = readAircraftFile(file_name);
geom = updateGeom(geom, settings, true); % true -> update prop
model = model_class(settings, geom);
perf = performance_class(model);

%% PLOT OF MAX MACH VS ALTITUDE. MIL & AB for CLEAN/STRIKE/COMBAT
loadout_clean = ["" "" "" "" "" "" "" ""];
loadout_air2air = ["AIM-9X" "AIM-120" "AIM-120" "" "" "AIM-120" "AIM-120" "AIM-9X"];
loadout_air2gnd = ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"];

N = 150;
M_vec = linspace(0.05, 2, N);
h_vec = linspace(0, ft2m(80000), N);

[M, H] = meshgrid(M_vec, h_vec);


figure(Name="Max Mach");
hold on
plot_mach_contour(perf, loadout_clean, 1, 0.5, M, H, 'r-'); % clean - ab
plot_mach_contour(perf, loadout_air2air, 1, 0.5, M, H, 'g-'); % air2air - ab
plot_mach_contour(perf, loadout_air2gnd, 1, 0.5, M, H, 'b-'); % air2gnd - ab
plot_mach_contour(perf, loadout_clean, 0.9, 0.5, M, H, 'r--'); % clean - mil
plot_mach_contour(perf, loadout_air2air, 0.9, 0.5, M, H, 'g--'); % air2air - mil
plot_mach_contour(perf, loadout_air2gnd, 0.9, 0.5, M, H, 'b--'); % air2gnd - mil

h1 = plot(NaN, NaN, 'r-',  'LineWidth', 1.5);
h2 = plot(NaN, NaN, 'g-',  'LineWidth', 1.5);
h3 = plot(NaN, NaN, 'b-',  'LineWidth', 1.5);

h4 = plot(NaN, NaN, 'k-',  'LineWidth', 1.5);   % solid meaning
h5 = plot(NaN, NaN, 'k--', 'LineWidth', 1.5);   % dashed meaning

legend([h1 h2 h3 h4 h5], ...
    {'Clean', 'Air-to-Air', 'Air-to-Ground', ...
     'Afterburner', 'Military Power'}, ...
    'Location','northwest', 'FontSize',13);

xlabel('Mach Number'); xlim([0 max(M_vec)])
ylabel('Altitude (kft)'); ylim([0 90])
title('Max Mach Contours')
grid on;

function plot_mach_contour(perf, loadout, T, W, M, H, line_spec)
    % T -> throttle
    % W -> weight

    % M -> input mach sweep using mesh grid
    % H -> input mach sweep using mesh grid

    h_vec_long = H(:)';
    M_vec_long = M(:)';
    one_vec = ones(size(h_vec_long));
    cond = generateCondition(perf.model.geom, h_vec_long, M_vec_long, one_vec, W * one_vec, T * one_vec); % h, M, N, W, T

    perf.model.geom = setLoadout(perf.model.geom, loadout);
    perf.model.cond = cond;
    perf.clear_data();
    EP = perf.ExcessPower;
    EP_grid = reshape(EP, size(M));

    % EP = 0 contour
    contour(M, m2ft(H)/1000, EP_grid, [0 0], line_spec, 'LineWidth', 1.5, 'HandleVisibility','off');
end

% %% RANGE VS COMBAT TIME
% N = 3;
% time_vec = linspace(0, 8, N); % minutes
% 
% range_air2air = zeros([length(time_vec), 2]);
% range_air2air_notank = range_air2air;
% range_air2air_clean = range_air2air;
% 
% perf.clear_data();
% 
% for i = 1:length(time_vec)
%     range_air2air(1, i) = get_mission_range(@eval_air2air, time_vec(i), perf, ["AIM-9X" "AIM-120" "AIM-120" "FPU-12" "FPU-12" "FPU-12" "AIM-120" "AIM-120" "AIM-9x"]);
%     range_air2air_notank(1, i) = get_mission_range(@eval_air2air, time_vec(i), perf, ["AIM-9X" "AIM-120" "AIM-120" "" "" "AIM-120" "AIM-120" "AIM-9x"]);
%     range_air2air_clean(1, i) = get_mission_range(@eval_air2air, time_vec(i), perf, ["" "" "" "" "" "" "" ""]);
% 
%     range_air2air(2, i) = get_mission_range(@eval_air2air, time_vec(i), perf_f18, ["AIM-9X" "AIM-120" "AIM-120" "FPU-12" "FPU-12" "FPU-12" "AIM-120" "AIM-120" "AIM-9x"]);
%     range_air2air_notank(2, i) = get_mission_range(@eval_air2air, time_vec(i), perf_f18, ["AIM-9X" "AIM-120" "AIM-120" "" "" "AIM-120" "AIM-120" "AIM-9x"]);
%     range_air2air_clean(2, i) = get_mission_range(@eval_air2air, time_vec(i), perf_f18, ["" "" "" "" "" "" "" ""]);
% end
% 
% figure();
% hold on
% 
% plot(time_vec, range_air2air(1, :), 'k-', DisplayName="Full Combat Loadout")
% plot(time_vec, range_air2air_notank(1, :), 'r-', DisplayName="Combat Loadout - No Tanks")
% plot(time_vec, range_air2air_clean(1, :), 'b-', DisplayName="Clean")
% 
% plot(time_vec, range_air2air(2, :), 'k--', DisplayName="Full Combat Loadout (F18)")
% plot(time_vec, range_air2air_notank(2, :), 'r--', DisplayName="Combat Loadout - No Tanks (F18)")
% plot(time_vec, range_air2air_clean(2, :), 'b--', DisplayName="Clean (F18)")
% 
% plot(2, 700, 'gx', MarkerSize=15, DisplayName="RFP Requirement")
% 
% grid on
% axis tight
% ylim([100 800])
% title("Combat Mission (Air2Air)")
% xlabel("Combat Time [min]")
% ylabel("Combat Radius [nm]")
% legend("Location","southwest", FontSize=13)

%% RANGE VS DASH DISTANCE
perf.clear_data();
N = 3;
dash_radius_nm = linspace(0, 200, N); % nm

range_air2gnd = zeros([length(dash_radius_nm), 2]);
range_air2gnd_notank = range_air2gnd;
range_air2gnd_clean = range_air2gnd;

perf.clear_data();

for i = 1:length(dash_radius_nm)
    range_air2gnd(1, i) = get_mission_range(@eval_air2gnd, dash_radius_nm(i), perf, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"]);
    range_air2gnd_notank(1, i) = get_mission_range(@eval_air2gnd, dash_radius_nm(i), perf, ["AIM-9X" "Mk-83" "Mk-83" "" "" "Mk-83" "Mk-83" "AIM-9x"]);
    range_air2gnd_clean(1, i) = get_mission_range(@eval_air2gnd, dash_radius_nm(i), perf, ["" "" "" "" "" "" "" ""]);

    range_air2gnd(2, i) = get_mission_range(@eval_air2gnd, dash_radius_nm(i), perf_f18, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"]);
    range_air2gnd_notank(2, i) = get_mission_range(@eval_air2gnd, dash_radius_nm(i), perf_f18, ["AIM-9X" "Mk-83" "Mk-83" "" "" "Mk-83" "Mk-83" "AIM-9x"]);
    range_air2gnd_clean(2, i) = get_mission_range(@eval_air2gnd, dash_radius_nm(i), perf_f18, ["" "" "" "" "" "" "" ""]);
end

figure();
hold on

plot(dash_radius_nm, range_air2gnd(1, :), 'k-', DisplayName="Full Strike Loadout")
plot(dash_radius_nm, range_air2gnd_notank(1, :), 'r-', DisplayName="Strike Loadout - No Tanks")
plot(dash_radius_nm, range_air2gnd_clean(1, :), 'b-', DisplayName="Clean")

plot(dash_radius_nm, range_air2gnd(2, :), 'k--', DisplayName="Full Strike Loadout (F18)")
plot(dash_radius_nm, range_air2gnd_notank(2, :), 'r--', DisplayName="Strike Loadout - No Tanks (F18)")
plot(dash_radius_nm, range_air2gnd_clean(2, :), 'b--', DisplayName="Clean (F18)")

plot(50, 700, 'gx', MarkerSize=15, DisplayName="RFP Requirement")
grid on
axis tight
ylim([0 800])
title("Strike Mission (Air2Gnd)")
xlabel("Dash Radius [nm]")
ylabel("Combat Radius [nm]")
legend("Location","southwest", FontSize=13)

function range_nm = get_mission_range(fun, input, perf, loadout)
    try
        range_nm = fzero(@(R) eval_res(perf, fun, R, input, loadout), 100);
    catch exception
        range_nm = NaN;
    end

    function res = eval_res(perf, fun, range_nm, input, loadout)
        perf.clear_data();
        [W_final, empty_weight] = fun(perf, range_nm, input, loadout);
        res = W_final-empty_weight;
    end
end