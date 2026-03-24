%% awave_example.m
% Demonstrates calling D2500 (zero-lift wave drag) via runAwave.m

%% ---- Case 1: Run case1.inp directly ------------------------------------
fprintf('=== Case 1: case1.inp (delta wing + fuselage, body reshaping) ===\n');

out1 = runAwave(fullfile('Examples', 'case1.inp'));

if isempty(out1.CDW)
    fprintf('  No CDW parsed. Raw output snippet:\n');
    disp(out1.raw);
else
    fprintf('  %-8s %-14s %-14s %s\n', 'Mach', 'CDW', 'D/Q', 'Cycle');
    for k = 1:numel(out1.CDW)
        fprintf('  %-8.3f %-14.6f %-14.4f %d\n', ...
            out1.Mach(k), out1.CDW(k), out1.DoverQ(k), out1.cycle(k));
    end
    fprintf('  Final CDW (cycle %d) = %.6f\n\n', out1.cycle(end), out1.CDW(end));
end


%% ---- Case 2: case2.inp — multi-Mach sweep ------------------------------
fprintf('=== Case 2: case2.inp (supersonic transport, M2.4 to M1.0) ===\n');

out2 = runAwave(fullfile('Examples', 'case2.inp'));

if isempty(out2.CDW)
    fprintf('  No CDW parsed. Raw output snippet:\n');
    disp(out2.raw);
else
    fprintf('  %-8s %s\n', 'Mach', 'CDW');
    for k = 1:numel(out2.CDW)
        fprintf('  %-8.3f %.6f\n', out2.Mach(k), out2.CDW(k));
    end
    fprintf('\n');
end


%% ---- Case 3: Build from struct -----------------------------------------
fprintf('=== Case 3: Build delta-wing input from struct ===\n');

cfg = struct();
cfg.title = 'SIMPLE DELTA WING - MATLAB GENERATED';
cfg.REFA  = 16.0;

% Wing: 3 chordwise stations
cfg.XAF    = [0.0, 50.0, 100.0];
cfg.WAFORG = [100.0,  10.0, 0.0, 140.0; ...   % root: xLE y z chord
              240.0, 150.0, 0.0,   0.0];       % tip
cfg.WAFORD = [0.0, 2.5, 0.0; ...               % root ordinates (% chord)
              0.0, 2.5, 0.0];                  % tip  ordinates

% Fuselage: 3 segments (same as case1)
cfg.XFUS{1}   = [  0.0,  10.0,  20.0,  30.0,  40.0,  50.0];
cfg.FUSARD{1} = [  0.00, 40.70, 128.70, 221.70, 289.50, 314.16];

cfg.XFUS{2}   = [50.0, 250.0];
cfg.FUSARD{2} = [314.16, 314.16];

cfg.XFUS{3}   = [250.0, 260.0, 270.0, 280.0, 290.0, 300.0];
cfg.FUSARD{3} = [314.16, 289.50, 221.70, 128.70, 40.70, 0.0];

% Single Mach case — no body reshaping
cfg.cases(1).Mach   = 1.2;
cfg.cases(1).NX     = 50;
cfg.cases(1).NTHETA = 16;
cfg.cases(1).ICYC   = 0;   % analysis only, no reshaping cycles

inpFile = write_awave_input(cfg, 'awave_generated.inp');

% Show the generated file so we can verify it looks right
fprintf('--- Generated input file ---\n');
disp(fileread(inpFile));
fprintf('----------------------------\n\n');

out3 = runAwave(inpFile);

if isfile(inpFile), delete(inpFile); end

if isempty(out3.CDW)
    fprintf('  No CDW parsed. Raw output:\n');
    disp(out3.raw);
else
    fprintf('  CDW = %.6f  (case1.out reference: ~15.0)\n\n', out3.CDW(end));
end