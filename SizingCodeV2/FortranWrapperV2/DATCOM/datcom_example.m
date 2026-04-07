%% datcom_example.m
% Demonstrates calling USAF Digital DATCOM via runDatcom.m
%
% Three cases are shown:
%   1. Run EX1.INP directly  (body alone, no input writing needed)
%   2. Run EX3.INP directly  (full configuration, body+wing+tails)
%   3. Build a custom aircraft input from a struct using write_datcom_input

% %% ---- Case 1: Run EX1.INP directly --------------------------------------
% % Body-alone configuration, four flow regimes (subsonic -> hypersonic).
% % No struct needed — pass the .INP file straight to runDatcom.
% 
% % Resolve input files relative to this script, not pwd
% % datcom_example.m is in DATCOM/, .INP files are in DATCOM/Examples/
% thisDir = fileparts(mfilename('fullpath'));
% examplesDir = fullfile(thisDir, 'Examples');
% 
% out1 = runDatcom(fullfile(examplesDir, 'EX1.INP'));
% 
% fprintf('=== Case 1: EX1 (body alone) ===\n');
% for k = 1:numel(out1.tables)
%     t = out1.tables(k);
%     fprintf('  [%d] M=%.2f | %s\n', k, t.Mach, t.caseTitle);
%     if ~isempty(t.data) && ~all(isnan(t.data.CL))
%         disp(t.data)
%     end
% end


% %% ---- Case 2: Run EX3.INP directly --------------------------------------
% % Full configuration buildup: body + wing + horizontal tail + vertical tail.
% 
% out2 = runDatcom(fullfile(examplesDir, 'EX3.INP'));
% 
% fprintf('\n=== Case 2: EX3 (body + wing + tails) ===\n');
% for k = 1:numel(out2.tables)
%     t = out2.tables(k);
%     fprintf('  [%d] M=%.2f | %s\n', k, t.Mach, t.caseTitle);
%     if ~isempty(t.data) && ~all(isnan(t.data.CL))
%         disp(t.data)
%     end
% end


%% ---- Case 3: Build custom input from struct ----------------------------
% Generic supersonic fighter: circular fuselage + swept wing + tails.
% Demonstrates write_datcom_input — replace numbers with your own geometry.

cfg = struct();
cfg.dim = 'FT';

c = struct();
c.caseid = 'GENERIC SUPERSONIC FIGHTER - BASELINE';

% Flight conditions: 4 Mach numbers, 9 alpha points each
c.fltcon.nmach  = 4;
c.fltcon.mach   = [0.6, 0.9, 1.4, 2.0];
c.fltcon.nalpha = 9;
c.fltcon.alschd = [-4, -2, 0, 2, 4, 8, 12, 16, 20];
c.fltcon.rnnub  = [2.5e6, 3.8e6, 6.0e6, 9.5e6];

% Reference geometry
c.optins.sref  = 608.0;    % ft^2  gross wing area
c.optins.cbarr = 16.0;     % ft    mean aerodynamic chord
c.optins.blref = 42.0;     % ft    wing span

% Component positions measured from nose (ft)
c.synths.xcg    = 26.0;    % CG x-location
c.synths.zcg    = 0.0;
c.synths.xw     = 18.0;    % wing LE at root
c.synths.zw     = -1.5;    % wing below body centreline
c.synths.aliw   = 1.0;     % wing incidence (deg)
c.synths.xh     = 48.0;    % horiz tail LE at root
c.synths.zh     = 0.0;
c.synths.alih   = 0.0;
c.synths.xv     = 46.0;    % vert tail LE at root
c.synths.vertup = true;    % vert tail above centreline

% Fuselage: 12 circular cross-sections
xb = [0,  4,  8, 12, 16, 22, 30, 40, 46, 52, 56, 60];
rb = [0, 1.2, 2.0, 2.4, 2.6, 2.8, 2.8, 2.8, 2.5, 1.8, 0.9, 0];
c.body.nx    = 12;
c.body.bnose = 2;           % 2 = conical nose
c.body.btail = 1;           % 1 = ogive tail
c.body.bln   = 10.0;        % nose length (ft)
c.body.bla   = 8.0;         % afterbody length (ft)
c.body.x = xb;
c.body.r = rb;
c.body.s = pi * rb.^2;      % cross-section area (ft^2)
c.body.p = 2 * pi * rb;     % perimeter (ft)

% Wing: straight taper, 45 deg LE sweep
c.wgplnf.chrdr  = 22.0;    % root chord (ft)
c.wgplnf.chrdtp = 4.0;     % tip chord (ft)
c.wgplnf.sspn   = 21.0;    % total semi-span (ft)
c.wgplnf.sspne  = 18.2;    % exposed semi-span (ft)
c.wgplnf.savsi  = 45.0;    % LE sweep (deg)
c.wgplnf.chstat = 0.0;     % sweep measured at LE
c.wgplnf.swafp  = 0.0;
c.wgplnf.twista = -1.0;    % 1 deg washout
c.wgplnf.sspndd = 0.0;
c.wgplnf.dhdadi = 0.0;
c.wgplnf.dhdado = 0.0;
c.wgplnf.type   = 1;       % 1 = straight taper

c.wgschr.tovc   = 0.05;    % 5% t/c root
c.wgschr.tovco  = 0.04;    % 4% t/c tip
c.wgschr.xovc   = 0.40;    % max thickness at 40% chord
c.wgschr.deltay = 8.0;
c.wgschr.cli    = 0.05;
c.wgschr.alphai = 0.5;
c.wgschr.clalpa = [0.10, 0.10, 0.09, 0.08];  % per deg, one per Mach
c.wgschr.clmax  = [1.2,  1.0,  0.8,  0.6];
c.wgschr.cmo    = -0.015;
c.wgschr.leri   = 0.008;
c.wgschr.clamo  = 0.105;

% Horizontal tail: 55 deg LE sweep
c.htplnf.chrdr  = 10.0;    c.htplnf.chrdtp = 2.0;
c.htplnf.sspn   = 10.0;    c.htplnf.sspne  = 8.5;
c.htplnf.savsi  = 55.0;    c.htplnf.chstat = 0.0;
c.htplnf.swafp  = 0.0;     c.htplnf.twista = 0.0;
c.htplnf.sspndd = 0.0;     c.htplnf.dhdadi = 0.0;
c.htplnf.dhdado = 0.0;     c.htplnf.type   = 1;

c.htschr.tovc   = 0.04;    c.htschr.xovc   = 0.40;
c.htschr.deltay = 4.0;     c.htschr.clalpa = [0.10, 0.10, 0.09, 0.08];
c.htschr.clmax  = [1.0, 0.9, 0.7, 0.5];
c.htschr.cmo    = 0.0;     c.htschr.leri   = 0.006;
c.htschr.clamo  = 0.105;

% Vertical tail: 50 deg LE sweep
c.vtplnf.chrdr  = 14.0;    c.vtplnf.chrdtp = 4.0;
c.vtplnf.sspn   = 9.0;     c.vtplnf.sspne  = 8.0;
c.vtplnf.savsi  = 50.0;    c.vtplnf.chstat = 0.0;
c.vtplnf.swafp  = 0.0;     c.vtplnf.twista = 0.0;
c.vtplnf.type   = 1;

c.vtschr.tovc   = 0.05;    c.vtschr.xovc   = 0.40;
c.vtschr.clalpa = [0.10, 0.10, 0.09, 0.08];
c.vtschr.leri   = 0.007;

cfg.cases(1) = c;

% Write input file then run
inpFile = write_datcom_input(cfg, 'fighter_baseline.inp');
out3    = runDatcom(inpFile);

fprintf('\n=== Case 3: Custom fighter (struct input) ===\n');
for k = 1:numel(out3.tables)
    t = out3.tables(k);
    fprintf('\n  [%d] M=%.2f | %s\n', k, t.Mach, t.caseTitle);
    if ~isempty(t.data) && ~all(isnan(t.data.CL))
        disp(t.data)
    end
end

% Plot CL, CD, CM vs alpha at first Mach
t = out3.tables(1);
if ~isempty(t.data) && ~all(isnan(t.data.CL))
    figure('Name', sprintf('DATCOM Fighter M=%.1f', t.Mach));
    subplot(1,3,1);
    plot(t.data.Alpha, t.data.CL, 'b-o', 'LineWidth', 1.5);
    xlabel('\alpha (deg)'); ylabel('C_L'); title('Lift'); grid on;

    subplot(1,3,2);
    plot(t.data.Alpha, t.data.CD, 'r-o', 'LineWidth', 1.5);
    xlabel('\alpha (deg)'); ylabel('C_D'); title('Drag'); grid on;

    subplot(1,3,3);
    plot(t.data.Alpha, t.data.CM, 'w-o', 'LineWidth', 1.5);
    xlabel('\alpha (deg)'); ylabel('C_M'); title('Pitch Moment'); grid on;

    sgtitle(sprintf('%s  M=%.1f', t.caseTitle, t.Mach));
end

if isfile(inpFile), delete(inpFile); end


%% ---- Case 4: Verification test against known ex1.out values -----------
% Builds EX1 Case 1 (body-alone, M=0.6) from a struct and verifies the
% parsed output matches the reference values from ex1.out exactly.
% All 11 alpha points from -6 to 24 deg should pass within tol=0.002.

fprintf('\n=== Case 4: Verification test (EX1 body-alone vs known reference) ===\n');

tol = 0.002;

cfg4     = struct();
cfg4.dim = 'FT';

c4 = struct();
c4.caseid = 'APPROXIMATE AXISYMMETRIC BODY SOLUTION, EXAMPLE PROBLEM 1, CASE 1';

c4.fltcon.nmach  = 1;
c4.fltcon.mach   = 0.60;
c4.fltcon.nalpha = 11;
c4.fltcon.alschd = [-6, -4, -2, 0, 2, 4, 8, 12, 16, 20, 24];
c4.fltcon.rnnub  = 4.28e6;

c4.optins.sref  = 8.85;
c4.optins.cbarr = 2.48;
c4.optins.blref = 4.28;

c4.synths.xcg = 4.14;
c4.synths.zcg = -0.20;

c4.body.nx    = 10;
c4.body.bnose = 1;
c4.body.bln   = 2.59;
c4.body.bla   = 3.67;
c4.body.x = [0.0, 0.258, 0.589, 1.260, 2.260, 2.590, 2.930, 3.590, 4.570, 6.260];
c4.body.r = [0.0, 0.186, 0.286, 0.424, 0.533, 0.533, 0.533, 0.533, 0.533, 0.533];
c4.body.s = [0.0, 0.080, 0.160, 0.323, 0.751, 0.883, 0.939, 1.032, 1.032, 1.032];
c4.body.p = [0.0, 1.00,  1.42,  2.01,  3.08,  3.34,  3.44,  3.61,  3.61,  3.61];

cfg4.cases(1) = c4;

inpFile4 = write_datcom_input(cfg4, 'test_ex1_verify.inp');
out4     = runDatcom(inpFile4);
if isfile(inpFile4), delete(inpFile4); end

% Find the M=0.6 block with the most rows
target4 = [];
bestRows = 0;
for k = 1:numel(out4.tables)
    t = out4.tables(k);
    if abs(t.Mach - 0.6) < 0.01 && height(t.data) > bestRows ...
            && ~all(isnan(t.data.CL))
        bestRows = height(t.data);
        target4  = t;
    end
end

% Reference values from ex1.out lines 415-425 (Case 1, M=0.6, Re=4.28e6)
%       alpha   CD      CL       CM
ref4 = [-6.0,  0.023, -0.021, -0.0205;
        -4.0,  0.022, -0.014, -0.0137;
        -2.0,  0.021, -0.007, -0.0068;
         0.0,  0.021,  0.000,  0.0000;
         2.0,  0.021,  0.007,  0.0068;
         4.0,  0.022,  0.014,  0.0137;
         8.0,  0.025,  0.027,  0.0273;
        12.0,  0.029,  0.041,  0.0410;
        16.0,  0.036,  0.055,  0.0546;
        20.0,  0.044,  0.069,  0.0683;
        24.0,  0.054,  0.082,  0.0820];

if isempty(target4)
    fprintf('  FAIL: No M=0.6 block found.\n');
else
    fprintf('  Block: %d rows found at M=%.2f\n', bestRows, target4.Mach);
    fprintf('  %-6s  %-7s %-7s %-5s   %-7s %-7s %-5s   %-8s %-8s %-5s\n', ...
        'alpha','CD_got','CD_ref','CD?','CL_got','CL_ref','CL?','CM_got','CM_ref','CM?');

    pass4  = true;
    nfound = 0;
    strs   = {'FAIL','OK'};
    ok     = @(x) strs{double(x)+1};
    d4     = target4.data;

    for i = 1:size(ref4,1)
        a_ref = ref4(i,1); CD_ref = ref4(i,2);
        CL_ref = ref4(i,3); CM_ref = ref4(i,4);
        idx = find(abs(d4.Alpha - a_ref) < 0.1, 1);
        if isempty(idx)
            fprintf('  %-6.1f  NOT FOUND\n', a_ref);
            pass4 = false; continue
        end
        nfound = nfound + 1;
        CD = d4.CD(idx); CL = d4.CL(idx); CM = d4.CM(idx);
        CD_ok = ~isnan(CD) && abs(CD-CD_ref) <= tol;
        CL_ok = ~isnan(CL) && abs(CL-CL_ref) <= tol;
        CM_ok = ~isnan(CM) && abs(CM-CM_ref) <= tol;
        if ~CD_ok || ~CL_ok || ~CM_ok, pass4 = false; end
        fprintf('  %-6.1f  %-7.3f %-7.3f %-5s   %-7.3f %-7.3f %-5s   %-8.4f %-8.4f %-5s\n', ...
            a_ref, CD, CD_ref, ok(CD_ok), CL, CL_ref, ok(CL_ok), CM, CM_ref, ok(CM_ok));
    end

    fprintf('\n  Found %d/%d reference points.\n', nfound, size(ref4,1));
    if pass4 && nfound == size(ref4,1)
        fprintf('  PASS — all values match ex1.out within tolerance %.3f\n', tol);
    elseif pass4
        fprintf('  PARTIAL PASS — matched points OK, %d missing\n', size(ref4,1)-nfound);
    else
        fprintf('  FAIL — one or more values outside tolerance %.3f\n', tol);
    end
end