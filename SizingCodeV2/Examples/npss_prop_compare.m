% STARTUP FUNCTIONS
initialize
matlabSetup
build_kevin_cad

% INITIAL OBJECTS TO LOAD
build_default_settings
settings = readSettings();
% geom = loadAircraft("kevin_cad", settings);
geom = loadAircraft("HellstingerV3_OPM", settings);

model = model_class(settings, geom);
perf = performance_class(model);

N = 50;
h_vec = linspace(0, ft2m(40000), 50);
M_vec = linspace(0.45, 0.9, 50);

[H, M] = meshgrid(h_vec, M_vec);

H_long = H(:); M_long = M(:);

perf.model.cond = levelFlightCondition(perf, H_long, M_long, 1);

TSFC_hook = perf.TSFC;

settings.PROP_model = settings.codes.PROP_NPSS; % PROP_BASIC PROP_NPSS PROP_HOOK PROP_HYBRID
perf.model.settings = settings;

TSFC_NPSS = perf.TSFC;

error = (TSFC_hook - TSFC_NPSS)./TSFC_NPSS;

% Reshape error back to meshgrid dimensions
error_grid = reshape(error, size(H));
% Convert altitude back to feet for readable axis
H_ft = m2ft(H);
% Define the three points
points = [
    0,            0.85,   "Sealevel Dash";
    ft2m(40000),  0.8369, "Cruise Condition";
    ft2m(10000),  0.47,   "Loiter Condition";
];
pt_h   = m2ft(cellfun(@str2double, {points{:,1}}));
pt_m   = cellfun(@str2double, {points{:,2}});
pt_names = points(:,3);
% Contour label formatting helper
fmt = @(v) sprintf('%.1f', v);
% Contour plot
figure;
[C, h_cont] = contourf(H_ft, M, error_grid * 100, 20);
colorbar;
h_cont.LineColor = 'k';
h_cont.LineWidth = 0.8;

% Apply formatted labels — method depends on MATLAB version
if isMATLABReleaseOlderThan('R2022b')
    % Option B: capture clabel handles, read UserData (raw float), reformat
    t_labels = clabel(C, h_cont, 'LabelSpacing', 400, 'FontSize', 8);
    drawnow;
    for i = 1:numel(t_labels)
        val = t_labels(i).UserData;   % raw numeric value, no parsing needed
        if isnumeric(val) && isscalar(val) && ~isnan(val)
            t_labels(i).String = fmt(val);
        end
    end
else
    % Option A: LabelFormat property, available R2022b+
    h_cont.LabelFormat = '%.1f';
    clabel(C, h_cont, 'LabelSpacing', 400, 'FontSize', 8);
end

hold on;
% Interpolation nudge to avoid boundary NaN
nudge    = 1e-6;
h_vec_ft = m2ft(h_vec);
M_lim    = [M_vec(1)+nudge,    M_vec(end)-nudge];
H_lim    = [h_vec_ft(1)+nudge, h_vec_ft(end)-nudge];
% Plot the three points with distinct symbols
symbols = {'p', '^', 's'};
colors  = {'r', 'm', 'g'};
h_pts   = gobjects(3,1);
for i = 1:3
    qi_h = min(max(pt_h(i), H_lim(1)), H_lim(2));
    qi_m = min(max(pt_m(i), M_lim(1)), M_lim(2));
    err_at_pt = interp2(H_ft, M, error_grid * 100, qi_h, qi_m);
    leg_label = sprintf('%s: $%s$\\%%', pt_names(i), fmt(err_at_pt));
    h_pts(i) = plot(qi_h, qi_m, ...
        symbols{i}, ...
        'MarkerFaceColor', colors{i}, ...
        'MarkerEdgeColor', 'k', ...
        'MarkerSize', 15, ...
        'DisplayName', leg_label);
end
legend(h_pts, 'Location', 'northeast');
xlabel('Altitude (ft)');
ylabel('Mach Number');
title('TSFC Relative Error: Raymer/Hook vs NPSS (\%)');