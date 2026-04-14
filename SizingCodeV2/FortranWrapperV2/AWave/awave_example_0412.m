%% awave_example_0412.m
% Builds a D2500 (AWAVE) input struct from the 0412_Optimization aircraft
% JSON and runs a Mach sweep through the transonic/supersonic regime.
% All dimensions in metres, areas in m^2.

clear; clc;

%% ---- Geometry constants from JSON -------------------------------------
fus_len     = 15.240;   % fuselage.length
fus_maxA    = 3.000;    % fuselage.max_area
eng_diam    = 0.906;    % prop.diam  (F110)
ref_area    = 59.925;   % ref_area (both semi-spans)

% Wing spanwise sections: [xLE, y_span, chord, t/c]
% Source: wing.sections[*].le_x, le_y, chord_length.v, tc.v
wing_secs = [ ...
    3.0452,  0.9772, 10.370, 0.060; ...   % section 0 – root
    7.3152,  2.1720,  6.100, 0.040; ...   % section 1
    7.6886,  2.7016,  5.640, 0.038; ...   % section 2
    9.1821,  4.8198,  3.800, 0.030; ...   % section 3
   10.6756,  6.9380,  1.960, 0.022; ...   % section 5 (skips minor kink)
   11.0490,  7.4676,  1.500, 0.020];      % section 6 – tip

%% ---- Build cfg struct -------------------------------------------------
cfg = struct();
cfg.title = '0412_OPTIMIZATION JET FIGHTER - F110x2';
cfg.REFA  = ref_area;

%% Wing
% WAFORG columns: [x_LE (m), y_span (m), z (m), chord (m)]
% z = 0 throughout — dihedral is 0 deg in all wing.sections
cfg.WAFORG = [wing_secs(:,1), wing_secs(:,2), zeros(6,1), wing_secs(:,3)];

% Chordwise stations for thickness ordinates [% chord]
cfg.XAF = [0.0, 50.0, 100.0];

% WAFORD(i,:) = [LE ordinate, peak half-thickness, TE ordinate] [% chord]
% peak half-thickness = (t/c) / 2 * 100
tc = wing_secs(:,4);
cfg.WAFORD = [zeros(6,1), tc/2*100, zeros(6,1)];

%% Fuselage — 3 segments
% Segment 1: pointed nose (x = 0 → 3 m)
%   Area grows parabolically from 0 to fus_maxA at the wing LE (x ≈ 3 m)
xNose = linspace(0, 3.0, 7);
cfg.XFUS{1}   = xNose;
cfg.FUSARD{1} = fus_maxA .* (xNose / 3.0).^2;

% Segment 2: constant section over wing box (x = 3 → 12 m)
%   Wing root TE is at x = 13.415 m, but fuselage starts tapering ~1 m earlier
cfg.XFUS{2}   = [3.0, 12.0];
cfg.FUSARD{2} = [fus_maxA, fus_maxA];

% Segment 3: boat-tail / nozzle fairing (x = 12 → 15.24 m)
%   Nozzle exit: 2x F110, D = 0.906 m → A_exit = 2 * pi * (D/2)^2
A_nozzle      = 2 * pi * (eng_diam/2)^2;   % ≈ 1.29 m^2
xTail         = [12.0, 12.6, 13.2, 13.8, 14.4, fus_len];
cfg.XFUS{3}   = xTail;
cfg.FUSARD{3} = linspace(fus_maxA, A_nozzle, numel(xTail));

%% Run cases: Mach sweep through transonic onset and supersonic
% JSON transonic_range = [0.95, 1.30]; CDw_scaler = 1.5 applied post-run
machs = [0.1, 0.3, 0.5 0.75, 0.85, 0.90, 0.95, 1.05, 1.10, 1.20, 1.30, 1.40, 1.60, 1.80, 2.00, 2.20, 2.40];
for k = 1:numel(machs)
    cfg.cases(k).Mach   = machs(k);
    cfg.cases(k).NX     = 60;
    cfg.cases(k).NTHETA = 20;
    cfg.cases(k).ICYC   = 0;   % analysis only — no body reshaping
end

%% ---- Write, run, display -----------------------------------------------

plot_0412_planform('awave', cfg)

inpFile = write_awave_input(cfg, 'awave_0412_opt.inp');

fprintf('--- Generated input file ---\n');
disp(fileread(inpFile));
fprintf('----------------------------\n\n');

out = runAwave(inpFile);
if isfile(inpFile), delete(inpFile); end

fprintf('=== 0412_Optimization wave drag sweep ===\n');
if isempty(out.CDW)
    fprintf('No CDW parsed. Raw output:\n');
    disp(out.raw);
else
    CDW_scaler = 1;   % settings.CDw_scaler from JSON
    fprintf('  %-8s %-14s %-14s %s\n', ...
            'Mach', 'CDW_raw', 'D/Q [m^2]', 'Cycle');
    for k = 1:numel(out.CDW)
        fprintf('  %-8.3f %-14.6f %-14.4f %d\n', ...
                out.Mach(k), out.CDW(k),  ...
                out.DoverQ(k), out.cycle(k));
    end
    [peakCDW, idx] = max(out.CDW);
    fprintf('\nPeak CDW_raw = %.6f at Mach %.2f  (scaled = %.6f)\n', ...
            peakCDW, out.Mach(idx), peakCDW*CDW_scaler);
end