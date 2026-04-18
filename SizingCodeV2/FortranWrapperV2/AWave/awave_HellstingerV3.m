%% awave_example_hellstinger.m
% Build an AWAVE input struct from the HellstingerV3 JSON geometry
% using loadAircraft(), then run a Mach sweep.
%
% Assumptions:
% - Geometry fields follow the same structure as your friction script
% - Wing / tail areas in the JSON are semi-planform areas, so mirrored
%   surfaces are multiplied appropriately where needed
% - AWAVE expects dimensions in metres and areas in m^2

clear; clc;

%% ---- Load aircraft geometry from JSON ---------------------------------
build_default_settings
settings = readSettings();
geom = loadAircraft("HellstingerV3", settings);

cfg = struct();
cfg.title = 'Hellstinger_V3';
cfg.REFA  = geom.ref_area.v;   % m^2

%% ---- Basic fuselage values --------------------------------------------
fus_len  = geom.fuselage.length.v;      % m
fus_maxA = geom.fuselage.max_area.v;    % m^2

% Engine diameter:
% If your prop / engine field is stored differently, change this line.
eng_diam = geom.prop.diam.v;            % m

%% ---- Wing definition for AWAVE ----------------------------------------
% AWAVE wing format:
% cfg.WAFORG = [x_LE, y_span, z, chord]
%
% Pull wing sections directly from JSON.
nWing = numel(geom.wing.sections);

WAFORG = zeros(nWing,4);
WAFORD = zeros(nWing,3);

for i = 1:nWing
    sec = geom.wing.sections(i);

    xle   = sec.le_x.v;
    yle   = sec.le_y.v;
    zle   = 0.0;
    chord = sec.chord_length.v;
    tc    = sec.tc.v;

    WAFORG(i,:) = [xle, yle, zle, chord];

    % AWAVE thickness ordinate format:
    % [LE ordinate, max half-thickness ordinate, TE ordinate] in % chord
    WAFORD(i,:) = [0.0, 0.5*tc*100, 0.0];
end

cfg.WAFORG = WAFORG;
cfg.XAF    = [0.0, 50.0, 100.0];
cfg.WAFORD = WAFORD;

%% ---- Fuselage definition ----------------------------------------------
% AWAVE fuselage uses sectional area distribution.
% Build a simple 3-part approximation:
%   1) nose growth
%   2) cylindrical / constant midbody
%   3) tail taper to nozzle area

% Use wing root LE as a reasonable end-of-nose station
x_nose_end = geom.wing.sections(1).le_x.v;

% Use about 80% fuselage length for taper start unless you want a more
% exact station from geometry
x_tail_start = 0.80 * fus_len;

% Dual-engine nozzle exit estimate
A_nozzle = 2 * pi * (eng_diam/2)^2;

% Segment 1: nose
xNose = linspace(0, x_nose_end, 7);
cfg.XFUS{1}   = xNose;
cfg.FUSARD{1} = fus_maxA .* (xNose / x_nose_end).^2;

% Segment 2: constant midbody
cfg.XFUS{2}   = [x_nose_end, x_tail_start];
cfg.FUSARD{2} = [fus_maxA, fus_maxA];

% Segment 3: tail taper
xTail = linspace(x_tail_start, fus_len, 6);
cfg.XFUS{3}   = xTail;
cfg.FUSARD{3} = linspace(fus_maxA, A_nozzle, numel(xTail));

%% ---- Mach sweep cases --------------------------------------------------
machs = [0.10, 0.30, 0.50, 0.75, 0.85, 0.90, 0.95, ...
         1.05, 1.10, 1.20, 1.30, 1.40, 1.60, 1.80, 2.00];

for k = 1:numel(machs)
    cfg.cases(k).Mach   = machs(k);
    cfg.cases(k).NX     = 60;
    cfg.cases(k).NTHETA = 20;
    cfg.cases(k).ICYC   = 0;   % analysis only
end

%% ---- Plot geometry -----------------------------------------------------
plot_0412_planform('awave', cfg);

%% ---- Write AWAVE input, run, and display results ----------------------
inpFile = write_awave_input(cfg, 'awave_hellstinger.inp');

fprintf('--- Generated input file ---\n');
disp(fileread(inpFile));
fprintf('----------------------------\n\n');

out = runAwave(inpFile);

if isfile(inpFile)
    delete(inpFile);
end

fprintf('=== Hellstinger_V3 wave drag sweep ===\n');

if isempty(out.CDW)
    fprintf('No CDW parsed. Raw output:\n');
    disp(out.raw);
else
    CDW_scaler = 1.0;   % set from JSON/settings if you have one
    fprintf('  %-8s %-14s %-14s %s\n', 'Mach', 'CDW_raw', 'D/Q [m^2]', 'Cycle');

    for k = 1:numel(out.CDW)
        fprintf('  %-8.3f %-14.6f %-14.4f %d\n', ...
            out.Mach(k), out.CDW(k), out.DoverQ(k), out.cycle(k));
    end

    [peakCDW, idx] = max(out.CDW);
    fprintf('\nPeak CDW_raw = %.6f at Mach %.2f  (scaled = %.6f)\n', ...
        peakCDW, out.Mach(idx), peakCDW * CDW_scaler);
end