%% awave_example.m
% Demonstrates calling D2500 (zero-lift wave drag) via runAwave.m
%
% Two approaches are shown:
%   1. Run a pre-written .inp file directly (simplest — use the provided examples)
%   2. Build an input from a MATLAB struct and run it
%
% D2500 always writes results to wavedrag.out in the working directory.
% runAwave.m handles this automatically and parses the key outputs.

%% ---- Approach 1: Run a provided test case directly ----------------------
%
% case1.inp is a delta wing on a simple fuselage with body reshaping.
% Expected result: CDW ≈ 15.0 (from case1.out, ENTIRE AIRCRAFT CDW)

fprintf('=== Approach 1: Run case1.inp directly ===\n');

% Just pass the path to the .inp file — no setup needed.
out1 = runAwave(fullfile('Examples', 'case1.inp'));

fprintf('Mach    CDW        D/Q\n');
for k = 1:numel(out1.CDW)
    fprintf('%.3f   %.6f   %.4f   (cycle %d)\n', ...
        out1.Mach(k), out1.CDW(k), out1.DoverQ(k), out1.cycle(k));
end
fprintf('Final CDW (last cycle) = %.6f\n\n', out1.CDW(end));


%% ---- Approach 2: Run case2 (multi-Mach) --------------------------------
%
% case2.inp is a supersonic transport with 5 Mach conditions:
%   M2.4, M2.0, M1.6, M1.2, M1.0
% Expected: CDW decreasing with Mach, zero at M=1.0

fprintf('=== Approach 2: Run case2.inp (multi-Mach) ===\n');

out2 = runAwave(fullfile('Examples', 'case2.inp'));

fprintf('Mach    CDW\n');
for k = 1:numel(out2.CDW)
    fprintf('%.3f   %.6f\n', out2.Mach(k), out2.CDW(k));
end
fprintf('\n');


%% ---- Approach 3: Build input from struct --------------------------------
%
% Simple delta wing on a simple axisymmetric fuselage.
% Matches the spirit of case1 but built programmatically.

fprintf('=== Approach 3: Build from struct ===\n');

cfg = struct();
cfg.title = 'SIMPLE DELTA WING - MATLAB GENERATED';
cfg.REFA  = 16.0;           % reference area (same as case1)

% Wing geometry
% XAF: chordwise stations as percent-chord
cfg.XAF    = [0.0, 50.0, 100.0];   % 3 stations

% WAFORG: [xLE, y_span, z, chord] per spanwise station
%   Station 1: root  at (100, 10, 0), chord 140
%   Station 2: tip   at (240, 150, 0), chord 0  (delta tip)
cfg.WAFORG = [ ...
    100.0,  10.0, 0.0, 140.0; ...
    240.0, 150.0, 0.0,   0.0  ];

% WAFORD: wing ordinates as percent-chord (z/c * 100) at each (station x XAF)
% Symmetric double-wedge: 2.5% t/c
cfg.WAFORD = [ ...
    0.0, 2.5, 0.0; ...   % root
    0.0, 2.5, 0.0  ];    % tip

% Fuselage (3 segments matching case1)
% Segment 1: nose cone  x = 0 to 50
cfg.XFUS{1}   = [  0.0,  10.0,  20.0,  30.0,  40.0,  50.0];
cfg.FUSARD{1} = [  0.00, 40.7, 128.7, 221.7, 289.5, 314.16];

% Segment 2: constant-section barrel  x = 50 to 250
cfg.XFUS{2}   = [50.0, 250.0];
cfg.FUSARD{2} = [314.16, 314.16];

% Segment 3: tail taper  x = 250 to 300
cfg.XFUS{3}   = [250.0, 260.0, 270.0, 280.0, 290.0, 300.0];
cfg.FUSARD{3} = [314.16, 289.5, 221.7, 128.7,  40.7,   0.0];

% One Mach condition: analysis only (ICYC=0, no reshaping)
cfg.cases(1).Mach   = 1.2;
cfg.cases(1).NX     = 50;     % integration points along body
cfg.cases(1).NTHETA = 16;     % azimuthal cutting planes
cfg.cases(1).ICYC   = 0;      % 0 = analysis only, no body reshaping

% Write the input file
inpFile = write_awave_input(cfg, 'awave_generated.inp');

% Run it
out3 = runAwave(inpFile);

fprintf('Generated case CDW = %.6f  (case1.out reference: ~14.9999)\n\n', out3.CDW(end));

% Clean up generated file
delete(inpFile);