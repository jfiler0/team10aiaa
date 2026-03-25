%% datcom_example.m
% Demonstrates calling USAF Digital DATCOM via write_datcom_input + runDatcom.
%
% Two aircraft are shown:
%   1. Reproduce Example Problem 3 (body+wing+tails) from a struct
%      so you can verify results match the provided ex3.out
%   2. A generic supersonic fighter showing all common fields


%% =========================================================================
%  EXAMPLE 1 — Reproduce EX3 from a struct
% ==========================================================================

cfg1 = struct();
cfg1.dim   = 'FT';
cfg1.build = true;    % BUILD card: incremental config buildup output

c = struct();
c.caseid = 'CONFIGURATION BUILDUP, EXAMPLE PROBLEM 3, CASE 1';

% Flight conditions
c.fltcon.nmach  = 2;
c.fltcon.mach   = [0.6, 0.8];
c.fltcon.nalpha = 9;
c.fltcon.alschd = [-2, 0, 2, 4, 8, 12, 16, 20, 24];
c.fltcon.rnnub  = [2.28e6, 3.04e6];

% Reference geometry
c.optins.sref  = 2.25;    % ft^2
c.optins.cbarr = 0.822;   % ft (MAC)
c.optins.blref = 3.00;    % ft (span)

% Component positions (from nose, ft)
c.synths.xcg   = 2.60;
c.synths.zcg   = 0.0;
c.synths.xw    = 1.70;    % wing apex x
c.synths.zw    = 0.0;
c.synths.aliw  = 0.0;
c.synths.xh    = 3.93;    % horiz tail apex x
c.synths.zh    = 0.0;
c.synths.alih  = 0.0;
c.synths.xv    = 3.34;    % vert tail apex x
c.synths.vertup = true;

% Fuselage
c.body.nx    = 10;
c.body.bnose = 2;
c.body.btail = 1;
c.body.bln   = 1.46;
c.body.bla   = 1.97;
c.body.x = [0.0, 0.175, 0.322, 0.530, 0.850, 1.46, 2.5, 3.43, 3.97, 4.57];
c.body.s = [0.0, 0.00547, 0.022, 0.0491, 0.0872, 0.136, 0.136, 0.136, 0.0993, 0.0598];
c.body.p = [0.0, 0.262, 0.523, 0.785, 1.04, 1.305, 1.305, 1.305, 1.12, 0.866];
c.body.r = [0.0, 0.0417, 0.0833, 0.125, 0.1665, 0.208, 0.208, 0.208, 0.178, 0.138];

% Wing
c.wgplnf.chrdr  = 1.16;  c.wgplnf.chrdtp = 0.346;
c.wgplnf.sspn   = 1.50;  c.wgplnf.sspne  = 1.29;
c.wgplnf.savsi  = 45.0;  c.wgplnf.chstat = 0.25;
c.wgplnf.swafp  = 0.0;   c.wgplnf.twista = 0.0;
c.wgplnf.sspndd = 0.0;   c.wgplnf.dhdadi = 0.0;
c.wgplnf.dhdado = 0.0;   c.wgplnf.type   = 1;

c.wgschr.tovc   = 0.06;  c.wgschr.deltay = 1.3;
c.wgschr.xovc   = 0.40;  c.wgschr.cli    = 0.0;
c.wgschr.alphai = 0.0;   c.wgschr.clalpa = 0.131;
c.wgschr.clmax  = 0.82;  c.wgschr.cmo    = 0.0;
c.wgschr.leri   = 0.0025; c.wgschr.clamo = 0.105;

% Vertical tail
c.vtplnf.chrdr  = 1.02;  c.vtplnf.chrdtp = 0.42;
c.vtplnf.sspn   = 0.849; c.vtplnf.sspne  = 0.63;
c.vtplnf.savsi  = 28.1;  c.vtplnf.chstat = 0.25;
c.vtplnf.swafp  = 0.0;   c.vtplnf.twista = 0.0;
c.vtplnf.type   = 0;

c.vtschr.tovc   = 0.09;  c.vtschr.xovc   = 0.40;
c.vtschr.clalpa = 0.141; c.vtschr.leri   = 0.0075;

% Horizontal tail
c.htplnf.chrdr  = 0.42;  c.htplnf.chrdtp = 0.253;
c.htplnf.sspn   = 0.67;  c.htplnf.sspne  = 0.52;
c.htplnf.savsi  = 45.0;  c.htplnf.chstat = 0.25;
c.htplnf.swafp  = 0.0;   c.htplnf.twista = 0.0;
c.htplnf.sspndd = 0.0;   c.htplnf.dhdadi = 0.0;
c.htplnf.dhdado = 0.0;   c.htplnf.type   = 1;

c.htschr.tovc   = 0.06;  c.htschr.deltay = 1.3;
c.htschr.xovc   = 0.40;  c.htschr.cli    = 0.0;
c.htschr.alphai = 0.0;   c.htschr.clalpa = 0.131;
c.htschr.clmax  = 0.82;  c.htschr.cmo    = 0.0;
c.htschr.leri   = 0.0025; c.htschr.clamo = 0.105;

cfg1.cases(1) = c;

inpFile1 = write_datcom_input(cfg1, 'ex3_reproduced.inp');
fprintf('--- Generated input file ---\n'); disp(fileread(inpFile1)); fprintf('---\n\n');

out1 = runDatcom(inpFile1);
fprintf('=== EX3 Reproduced ===\n');
for k = 1:numel(out1.tables)
    t = out1.tables(k);
    fprintf('  [%d] %s | M=%.2f\n', k, t.caseTitle, t.Mach);
    if ~isempty(t.data), disp(t.data); end
end
if isfile(inpFile1), delete(inpFile1); end


%% =========================================================================
%  EXAMPLE 2 — Generic supersonic fighter
%  Replace numbers with your own aircraft geometry.
% ==========================================================================

cfg2 = struct();
cfg2.dim = 'FT';

c2 = struct();
c2.caseid = 'GENERIC SUPERSONIC FIGHTER - BASELINE';

% Flight conditions: 4 Mach numbers x 9 alpha
c2.fltcon.nmach  = 4;
c2.fltcon.mach   = [0.6, 0.9, 1.4, 2.0];
c2.fltcon.nalpha = 9;
c2.fltcon.alschd = [-4, -2, 0, 2, 4, 8, 12, 16, 20];
c2.fltcon.rnnub  = [2.5e6, 3.8e6, 6.0e6, 9.5e6];

% Reference geometry
c2.optins.sref  = 608.0;   % ft^2  gross wing area
c2.optins.cbarr = 16.0;    % ft    mean aerodynamic chord
c2.optins.blref = 42.0;    % ft    wing span

% Component positions (measured from nose, ft)
c2.synths.xcg   = 26.0;    % CG
c2.synths.zcg   = 0.0;
c2.synths.xw    = 18.0;    % wing LE at root
c2.synths.zw    = -1.5;    % wing below body centreline
c2.synths.aliw  = 1.0;     % wing incidence angle (deg)
c2.synths.xh    = 48.0;    % horiz tail LE at root
c2.synths.zh    = 0.0;
c2.synths.alih  = 0.0;
c2.synths.xv    = 46.0;    % vert tail LE at root
c2.synths.vertup = true;

% Fuselage: 12 axial stations, circular cross-section
xb = [0,  4,  8, 12, 16, 22, 30, 40, 46, 52, 56, 60];
rb = [0, 1.2, 2.0, 2.4, 2.6, 2.8, 2.8, 2.8, 2.5, 1.8, 0.9, 0];
c2.body.nx    = 12;
c2.body.bnose = 2;          % conical nose
c2.body.btail = 1;          % ogive tail
c2.body.bln   = 10.0;       % nose length (ft)
c2.body.bla   = 8.0;        % afterbody length (ft)
c2.body.x = xb;
c2.body.r = rb;
c2.body.s = pi * rb.^2;
c2.body.p = 2 * pi * rb;

% Wing: straight taper, 45 deg LE sweep
c2.wgplnf.chrdr  = 22.0;   % root chord (ft)
c2.wgplnf.chrdtp = 4.0;    % tip chord (ft)
c2.wgplnf.sspn   = 21.0;   % total semi-span (ft)
c2.wgplnf.sspne  = 18.2;   % exposed semi-span (ft)
c2.wgplnf.savsi  = 45.0;   % LE sweep (deg)
c2.wgplnf.chstat = 0.0;    % sweep pivot at LE
c2.wgplnf.swafp  = 0.0;
c2.wgplnf.twista = -1.0;   % 1 deg washout
c2.wgplnf.sspndd = 0.0;
c2.wgplnf.dhdadi = 0.0;
c2.wgplnf.dhdado = 0.0;
c2.wgplnf.type   = 1;

c2.wgschr.tovc   = 0.05;   % 5% t/c root
c2.wgschr.tovco  = 0.04;   % 4% t/c tip
c2.wgschr.xovc   = 0.40;
c2.wgschr.deltay = 8.0;
c2.wgschr.cli    = 0.05;
c2.wgschr.alphai = 0.5;
c2.wgschr.clalpa = [0.10, 0.10, 0.09, 0.08];  % per deg at each Mach
c2.wgschr.clmax  = [1.2,  1.0,  0.8,  0.6];
c2.wgschr.cmo    = -0.015;
c2.wgschr.leri   = 0.008;
c2.wgschr.clamo  = 0.105;

% Horizontal tail: 55 deg LE sweep
c2.htplnf.chrdr  = 10.0;   c2.htplnf.chrdtp = 2.0;
c2.htplnf.sspn   = 10.0;   c2.htplnf.sspne  = 8.5;
c2.htplnf.savsi  = 55.0;   c2.htplnf.chstat = 0.0;
c2.htplnf.swafp  = 0.0;    c2.htplnf.twista = 0.0;
c2.htplnf.sspndd = 0.0;    c2.htplnf.dhdadi = 0.0;
c2.htplnf.dhdado = 0.0;    c2.htplnf.type   = 1;

c2.htschr.tovc   = 0.04;   c2.htschr.xovc   = 0.40;
c2.htschr.deltay = 4.0;    c2.htschr.clalpa = [0.10, 0.10, 0.09, 0.08];
c2.htschr.clmax  = [1.0, 0.9, 0.7, 0.5];
c2.htschr.cmo    = 0.0;    c2.htschr.leri   = 0.006;
c2.htschr.clamo  = 0.105;

% Vertical tail: 50 deg LE sweep
c2.vtplnf.chrdr  = 14.0;   c2.vtplnf.chrdtp = 4.0;
c2.vtplnf.sspn   = 9.0;    c2.vtplnf.sspne  = 8.0;
c2.vtplnf.savsi  = 50.0;   c2.vtplnf.chstat = 0.0;
c2.vtplnf.swafp  = 0.0;    c2.vtplnf.twista = 0.0;
c2.vtplnf.type   = 1;

c2.vtschr.tovc   = 0.05;   c2.vtschr.xovc   = 0.40;
c2.vtschr.clalpa = [0.10, 0.10, 0.09, 0.08];
c2.vtschr.leri   = 0.007;

cfg2.cases(1) = c2;

inpFile2 = write_datcom_input(cfg2, 'fighter_baseline.inp');
out2 = runDatcom(inpFile2);

fprintf('\n=== Generic Fighter Results ===\n');
for k = 1:numel(out2.tables)
    t = out2.tables(k);
    fprintf('\n  [%d] M=%.2f | %s\n', k, t.Mach, t.caseTitle);
    if ~isempty(t.data) && ~all(isnan(t.data.CL))
        disp(t.data)
    end
end

% Plot first Mach block
t = out2.tables(1);
if ~isempty(t.data) && ~all(isnan(t.data.CL))
    figure('Name', 'DATCOM Fighter Aero');
    subplot(1,3,1); plot(t.data.Alpha, t.data.CL, 'b-o', 'LineWidth', 1.5);
    xlabel('\alpha (deg)'); ylabel('C_L'); title('Lift'); grid on;
    subplot(1,3,2); plot(t.data.Alpha, t.data.CD, 'r-o', 'LineWidth', 1.5);
    xlabel('\alpha (deg)'); ylabel('C_D'); title('Drag'); grid on;
    subplot(1,3,3); plot(t.data.Alpha, t.data.CM, 'w-o', 'LineWidth', 1.5);
    xlabel('\alpha (deg)'); ylabel('C_M'); title('Pitch Moment'); grid on;
    sgtitle(sprintf('%s  M=%.1f', t.caseTitle, t.Mach));
end

if isfile(inpFile2), delete(inpFile2); end