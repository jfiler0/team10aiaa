matlabSetup
settings = readSettings();
file_name = "HellstingerV3";
geom = readAircraftFile(file_name);
geom = updateGeom(geom, settings, true); % true -> update prop
geom = setLoadout(geom, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"]);
model = model_class(settings, geom);
perf = performance_class(model);

W = 120e3;        % weight [N]
N = 50;           % Mach resolution for ribbon plots

%% sea level
h_SL     = ft2m(50);
M_SL_bar = [0.2, 0.4, 0.6, 0.90, 0.95, 1.15];   

drag_bars(perf, h_SL, M_SL_bar, W)
% drag_ribbon_plot(perf, h_SL, N, W)

%% 30 k ft
h_30k     = ft2m(30e3);
M_30k_bar = [1.15, 1.2, 1.35, 1.55, 1.65]; 

drag_bars(perf, h_30k, M_30k_bar, W)
% drag_ribbon_plot(perf, h_30k, N, W)