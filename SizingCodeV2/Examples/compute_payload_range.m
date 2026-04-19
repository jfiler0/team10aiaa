matlabSetup
clear loadouts results
settings  = readSettings();
file_name = "HellstingerV3";
geom_base = readAircraftFile(file_name);

% --- Weight budget from JSON ---
W_MTOW = geom_base.weights.mtow.v;
W_fix  = geom_base.weights.w_fixed.v;
A_ray  = geom_base.weights.raymer.A.v;
C_ray  = geom_base.weights.raymer.C.v;
N2lbf  = 1/4.4482216153;
We_W0  = A_ray * (W_MTOW*N2lbf)^C_ray;
W_OEW  = We_W0 * W_MTOW + W_fix;
W_fuel_max = W_MTOW - W_OEW;

% --- Loadouts ---
loadouts(1) = struct('name','Clean',        'config', ["" "" "" "" "" "" "" ""]);
loadouts(2) = struct('name','Air-to-Air',   'config', ["AIM-9X" "AIM-120" "AIM-120" "" "" "AIM-120" "AIM-120" "AIM-9X"]);
loadouts(3) = struct('name','Air-to-Ground','config', ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9X"]);

% --- Mission params ---
h_cruise=ft2m(30e3); M_cruise=0.85;
h_loiter=ft2m(15e3); M_loiter=0.5;
reserveFrac = 0.05;

% --- Compute for each loadout ---
results = struct('name',{},'PT',{});
for i = 1:numel(loadouts)
    geom  = readAircraftFile(file_name);
    geom  = updateGeom(geom, settings, true);
    geom  = setLoadout(geom, loadouts(i).config);
    model = model_class(settings, geom);
    perf  = performance_class(model);

    fprintf('Computing: %s\n', loadouts(i).name);
    results(i).name = loadouts(i).name;
    results(i).PT   = payload_range_diagram(perf, W_OEW, W_fuel_max, W_MTOW, ...
                                          h_cruise, M_cruise, ...
                                          h_loiter, M_loiter, reserveFrac);
end

% --- Overlay plots ---
all_colors = lines(7);
all_colors(3,:) = [];                      % drop yellow
colors = all_colors(1:numel(results), :);
markers = {'o','s','^','d','v'};

% Payload - Range
figure('Name','Payload-Range (all loadouts)');
hold on; grid on; box on;
for i = 1:numel(results)
    plot(32.2 * kg2slug(results(i).PT.payload_kg), 0.539957*results(i).PT.range_km, ...
         ['-' markers{i}], 'LineWidth', 2, 'Color', colors(i,:), ...
         'MarkerFaceColor', colors(i,:), 'DisplayName', results(i).name);
end
xlabel('Payload [lb]'); ylabel('Range [nm]');
title(sprintf('Payload-Range Trade (MTOW fixed, h = %.0f ft, M = %.2f)', ...
      m2ft(h_cruise), M_cruise));
theme(gcf, 'light')
legend('Location','best');

% Payload - Loiter
figure('Name','Payload-Loiter (all loadouts)');
hold on; grid on; box on;
for i = 1:numel(results)
    plot(32.2 * kg2slug(results(i).PT.payload_kg), results(i).PT.loiter_hr, ...
         ['-' markers{i}], 'LineWidth', 2, 'Color', colors(i,:), ...
         'MarkerFaceColor', colors(i,:), 'DisplayName', results(i).name);
end
xlabel('Payload [lb]'); ylabel('Loiter time [hr]');
title(sprintf('Payload-Loiter Trade (h = %.0f ft, M = %.2f)', ...
      m2ft(h_loiter), M_loiter));
theme(gcf, 'light')
legend('Location','best');

% Fuel burn
figure('Name','Fuel Burn (all loadouts)');
hold on; grid on; box on;
for i = 1:numel(results)
    plot(results(i).PT.payload_kg, results(i).PT.fuel_used_kg, ...
         ['-' markers{i}], 'LineWidth', 2, 'Color', colors(i,:), ...
         'MarkerFaceColor', colors(i,:), 'DisplayName', results(i).name);
end
xlabel('Payload [kg]'); ylabel('Fuel burned (ex-reserve) [kg]');
title('Fuel Available for Mission vs Payload (MTOW-limited)');
theme(gcf, 'light')
legend('Location','best');

% --- Payload-Range Harpoon (all loadouts) ---
figure('Name','Payload-Range Harpoon');
hold on; grid on; box on;

% Stores mass lookup [kg]
store_mass = containers.Map( ...
    {'AIM-9X','AIM-120','Mk-83','FPU-12',''}, ...
    { 85,     152,      450,    150,    0  });

for i = 1:numel(loadouts)
    m = 0;
    for s = loadouts(i).config
        if isKey(store_mass, char(s)), m = m + store_mass(char(s)); end
    end
    loadouts(i).pld_kg = m;
end

% Drop zero-payload loadouts (they ARE the ferry point, just duplicates)
keep = find([loadouts.pld_kg] > 0);
[~, ord] = sort([loadouts(keep).pld_kg], 'descend');
order = keep(ord);

% Build corner points
harp_pld_lb  = [];
harp_rng_nmi = [];
harp_labels  = {};

for k = 1:numel(order)
    i = order(k);
    rng_km = interp1(results(i).PT.payload_kg, results(i).PT.range_km, ...
                     loadouts(i).pld_kg, 'linear', 'extrap');
    harp_pld_lb(end+1)  = loadouts(i).pld_kg * 2.2046;
    harp_rng_nmi(end+1) = rng_km * 0.539957;
    harp_labels{end+1}  = loadouts(i).name;
end

% Ferry corner (zero payload, max range)
harp_pld_lb(end+1)  = 0;
harp_rng_nmi(end+1) = results(1).PT.range_km(1) * 0.539957;
harp_labels{end+1}  = 'Ferry';

% --- Plot with leading horizontal plateau from y-axis to first point ---
pld_max   = harp_pld_lb(1);
rng_first = harp_rng_nmi(1);

% Horizontal plateau: (0, pld_max) -> (rng_first, pld_max)
plot([0, rng_first], [pld_max, pld_max], '-', 'LineWidth', 2.5, ...
     'Color', [0.00 0.45 0.74]);

% Descending harpoon: connect the corner points
plot(harp_rng_nmi, harp_pld_lb, '-o', 'LineWidth', 2.5, ...
     'Color', [0.00 0.45 0.74], 'MarkerFaceColor', [0.00 0.45 0.74], ...
     'MarkerSize', 8);

% Labels at each corner
for k = 1:numel(harp_labels)
    text(harp_rng_nmi(k), harp_pld_lb(k), ['  ' harp_labels{k}], ...
         'VerticalAlignment','bottom', 'HorizontalAlignment','left', ...
         'FontSize', 14, 'FontWeight','bold');
end

xlabel('Range [nmi]');
ylabel('Payload [lb]');
title('Hellstinger Payload-Range Envelope');
xlim([0, max(harp_rng_nmi)*1.15]);
ylim([0, pld_max*1.25]);
theme(gcf, 'light');