% matlabSetup;
name = "F414";
interpObj = load_engine_lookup(name, false);

funcDir     = fileparts(mfilename('fullpath'));
devFilePath = fullfile(funcDir, "Prop_Interps", name + '_dev.mat');
storage     = load(devFilePath);
devObj      = storage.devObj;
d           = devObj.npss;

% ------------------------------------------------------------------ %
%  Shared colour limits — computed before any plotting                 %
% ------------------------------------------------------------------ %
throttle_vec  = linspace(0, 1, 20);
[MG, AG, TG]  = ndgrid(devObj.gridded.mach, devObj.gridded.alt, throttle_vec);
interp_thrust = interpObj.TA(MG, AG, TG);
interp_tsfc   = interpObj.TSFC(MG, AG, TG);

thrust_lim = [ min([d.thrust(:);   d.thrust_smooth(:);   interp_thrust(:)]), ...
               max([d.thrust(:);   d.thrust_smooth(:);   interp_thrust(:)]) ];
tsfc_lim   = [ min([d.tsfc(:);     d.tsfc_smooth(:);     interp_tsfc(:)]), ...
               max([d.tsfc(:);     d.tsfc_smooth(:);     interp_tsfc(:)]) ];

% ------------------------------------------------------------------ %
%  Figure                                                              %
% ------------------------------------------------------------------ %
figure('Name', name + " Engine Data Review", 'Position', [100 100 1400 800]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

% 1. Raw thrust
nexttile;
scatter3(d.mach, d.alt, d.pla, 30, d.thrust, 'filled', 'MarkerFaceAlpha', 0.7);
title('Raw Thrust (N)'); xlabel('Mach'); ylabel('Alt (m)'); zlabel('PLA');
colorbar; clim(thrust_lim); grid on; view(35, 25);

% 2. Smoothed thrust
nexttile;
scatter3(d.mach, d.alt, d.pla, 30, d.thrust_smooth, 'filled', 'MarkerFaceAlpha', 0.7);
title('Smoothed Thrust (N)'); xlabel('Mach'); ylabel('Alt (m)'); zlabel('PLA');
colorbar; clim(thrust_lim); grid on; view(35, 25);

% 3. Interpolated thrust
nexttile;
scatter3(MG(:), AG(:), TG(:), 10, interp_thrust(:), 'filled', 'MarkerFaceAlpha', 0.5);
title('Interpolated Thrust (N)'); xlabel('Mach'); ylabel('Alt (m)'); zlabel('Throttle (0-1)');
colorbar; clim(thrust_lim); grid on; view(35, 25);

% 4. Raw TSFC
nexttile;
scatter3(d.mach, d.alt, d.pla, 30, d.tsfc, 'filled', 'MarkerFaceAlpha', 0.7);
title('Raw TSFC (kg/N/s)'); xlabel('Mach'); ylabel('Alt (m)'); zlabel('PLA');
colorbar; clim(tsfc_lim); grid on; view(35, 25);

% 5. Smoothed TSFC
nexttile;
scatter3(d.mach, d.alt, d.pla, 30, d.tsfc_smooth, 'filled', 'MarkerFaceAlpha', 0.7);
title('Smoothed TSFC (kg/N/s)'); xlabel('Mach'); ylabel('Alt (m)'); zlabel('PLA');
colorbar; clim(tsfc_lim); grid on; view(35, 25);

% 6. Interpolated TSFC
nexttile;
scatter3(MG(:), AG(:), TG(:), 10, interp_tsfc(:), 'filled', 'MarkerFaceAlpha', 0.5);
title('Interpolated TSFC (kg/N/s)'); xlabel('Mach'); ylabel('Alt (m)'); zlabel('Throttle (0-1)');
colorbar; clim(tsfc_lim); grid on; view(35, 25);

sgtitle(name + " — Raw vs Smoothed vs Interpolated", 'FontSize', 14, 'FontWeight', 'bold');

% ------------------------------------------------------------------ %
%  2D slice figure — thrust and TSFC at throttle = 0.9 and 1.0       %
% ------------------------------------------------------------------ %
n_mach2 = 40;
n_alt2  = 40;
mach_vec2 = linspace(min(devObj.gridded.mach), max(devObj.gridded.mach), n_mach2);
% alt_vec2  = linspace(min(devObj.gridded.alt),  max(devObj.gridded.alt),  n_alt2);
alt_vec2  = linspace(-8000,  max(devObj.gridded.alt),  n_alt2);
[MG2, AG2] = ndgrid(mach_vec2, alt_vec2);

thrust_09 = interpObj.TA(MG2, AG2, 0.9 * ones(size(MG2)));
thrust_10 = interpObj.TA(MG2, AG2, 1.0 * ones(size(MG2)));
tsfc_09   = interpObj.TSFC(MG2, AG2, 0.9 * ones(size(MG2)));
tsfc_10   = interpObj.TSFC(MG2, AG2, 1.0 * ones(size(MG2)));

% Shared limits per quantity
thrust_lim2 = [min([thrust_09(:); thrust_10(:)]), max([thrust_09(:); thrust_10(:)])];
tsfc_lim2   = [min([tsfc_09(:);   tsfc_10(:)]),   max([tsfc_09(:);   tsfc_10(:)])];

figure('Name', name + " 2D Slices", 'Position', [100 100 1200 700]);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

% 1. Thrust @ throttle = 0.9
nexttile;
contourf(mach_vec2, alt_vec2, thrust_09', 25, 'LineWidth', 0.3);
colormap(gca, 'turbo'); colorbar; clim(thrust_lim2);
title('Thrust — Throttle = 0.9 (Mil Power)');
xlabel('Mach'); ylabel('Alt (m)'); grid on;

% 2. Thrust @ throttle = 1.0
nexttile;
contourf(mach_vec2, alt_vec2, thrust_10', 25, 'LineWidth', 0.3);
colormap(gca, 'turbo'); colorbar; clim(thrust_lim2);
title('Thrust — Throttle = 1.0 (Max AB)');
xlabel('Mach'); ylabel('Alt (m)'); grid on;

% 3. TSFC @ throttle = 0.9
nexttile;
contourf(mach_vec2, alt_vec2, tsfc_09', 25, 'LineWidth', 0.3);
colormap(gca, 'turbo'); colorbar; clim(tsfc_lim2);
title('TSFC — Throttle = 0.9 (Mil Power)');
xlabel('Mach'); ylabel('Alt (m)'); grid on;

% 4. TSFC @ throttle = 1.0
nexttile;
contourf(mach_vec2, alt_vec2, tsfc_10', 25, 'LineWidth', 0.3);
colormap(gca, 'turbo'); colorbar; clim(tsfc_lim2);
title('TSFC — Throttle = 1.0 (Max AB)');
xlabel('Mach'); ylabel('Alt (m)'); grid on;

sgtitle(name + " — Mil Power vs Max AB Slices", 'FontSize', 14, 'FontWeight', 'bold');