matlabSetup
settings = readSettings();

file_name = "HellstingerV3";
geom = readAircraftFile(file_name);
geom = updateGeom(geom, settings, true); % true -> update prop
model = model_class(settings, geom);
perf = performance_class(model);

%% PLOT OF MAX MACH VS ALTITUDE. MIL & AB for CLEAN/STRIKE/COMBAT
loadout_clean = ["" "" "" "" "" "" "" ""];
loadout_air2air = ["AIM-9X" "AIM-120" "AIM-120" "" "" "AIM-120" "AIM-120" "AIM-9X"];
loadout_air2gnd = ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"];

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
    'Location','eastoutside', 'FontSize',12);

xlabel('Mach Number'); xlim([0 max(M_vec)])
ylabel('Altitude (kft)');
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

close all;

%% RANGE VS COMBAT TIME
N = 50;
time_vec = linspace(0, 15, N) * 60; % minutes to seconds

range_air2air = zeros(size(time_vec));
range_air2gnd = zeros(size(time_vec));


get_mission_range(@eval_air2air, 2, perf)

[W_final, empty_weight] = eval_air2air(perf, 700, 0);
W_final - empty_weight

% for i = 1:length(time_vec)
%     range_air2air(i) = get_mission_range(@eval_air2air, time_vec(i), perf);
%     range_air2gnd(i) = get_mission_range(@eval_air2gnd, time_vec(i), perf);
% end
% 
% range_air2air

function range_nm = get_mission_range(fun, time_min, perf)
    range_nm = fzero(@(R) eval_res(fun, time_min, R, perf), 100);

    function res = eval_res(fun, time_min, range, perf)
        [W_final, empty_weight] = fun(perf, range, time_min);
        res = W_final-empty_weight;
    end
end