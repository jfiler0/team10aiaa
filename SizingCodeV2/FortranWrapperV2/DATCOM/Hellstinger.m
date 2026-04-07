%% datcom_example.m
% Demonstrates calling USAF Digital DATCOM via runDatcom.m
%
% Three cases are shown:
%   1. Run EX1.INP directly  (body alone, no input writing needed)
%   2. Run EX3.INP directly  (full configuration, body+wing+tails)
%   3. Build a custom aircraft input from a struct using write_datcom_input

%% ---- Case 1: Run EX1.INP directly --------------------------------------
% Body-alone configuration, four flow regimes (subsonic -> hypersonic).
% No struct needed — pass the .INP file straight to runDatcom.

% Resolve input files relative to this script, not pwd
% datcom_example.m is in DATCOM/, .INP files are in DATCOM/Examples/

% Create instance of kevin_cad 
% STARTUP FUNCTIONS
initialize
matlabSetup
build_kevin_cad

% INITIAL OBJECTS TO LOAD
build_default_settings
settings = readSettings();
geom = loadAircraft("kevin_cad", settings);
model = model_class(settings, geom);
    N = 100;
    perf = performance_class(model);
    settings = readSettings();
   
thisDir = fileparts(mfilename('fullpath'));
examplesDir = fullfile(thisDir, 'Examples');

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
% 
% 
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
% 

%% ---- Case 3: Build custom input from struct ----------------------------
% Generic supersonic fighter: circular fuselage + swept wing + tails.
% Demonstrates write_datcom_input — replace numbers with your own geometry.

cfg = struct();
cfg.dim = 'FT';

c = struct();
c.caseid = 'GENERIC SUPERSONIC FIGHTER - BASELINE';

% Flight conditions: 4 Mach numbers, 9 alpha points each
c.fltcon.nmach  = 4;
c.fltcon.mach   = [0.3, 0.9, 1.4, 2.0];
c.fltcon.nalpha = 9;
c.fltcon.alschd = [-4, -2, 0, 2, 4, 8, 12, 16, 20];
c.fltcon.rnnub  = [2.5e6, 3.8e6, 6.0e6, 9.5e6];

% cLa model updates 
perf.model.cond = levelFlightCondition(perf, 0, c.fltcon.mach(1), 1);
cLa_M1 = model.CLa;
perf.model.cond = levelFlightCondition(perf, 0, c.fltcon.mach(2), 1);
cLa_M2 = model.CLa;
perf.model.cond = levelFlightCondition(perf, 0, c.fltcon.mach(3), 1);
cLa_M3 = model.CLa;
perf.model.cond = levelFlightCondition(perf, 0, c.fltcon.mach(4), 1);
cLa_M4 = model.CLa;
perf.model.cond = levelFlightCondition(perf, 0, c.fltcon.mach(1), 1);

% Reference geometry
c.optins.sref  = m2ft(m2ft(geom.ref_area.v));    % ft^2  gross wing area
c.optins.cbarr = m2ft(geom.wing.average_chord.v);     % ft    mean aerodynamic chord
c.optins.blref = m2ft(geom.wing.span.v);     % ft    wing span

% Component positions measured from nose (ft)
c.synths.xcg    = 34;    % CG x-location ---- NEEDS UPDATE ----- 
c.synths.zcg    = m2ft(-0.003*geom.fuselage.length.v);
c.synths.xw     = m2ft(geom.wing.le_x.v);    % wing LE at root
c.synths.zw     = m2ft(geom.wing.sections(1).le_z.v);    % wing below body centreline
c.synths.aliw   = 0;     % wing incidence (deg)
c.synths.xh     = m2ft(geom.elevator.le_x.v);    % horiz tail LE at root
c.synths.zh     = m2ft(geom.elevator.sections(1).le_z.v);
c.synths.alih   = 0.0; % <------ WHAT IS THIS
c.synths.xv     = m2ft(geom.rudder.le_x.v);    % vert tail LE at root
c.synths.vertup = true;    % vert tail above centreline

% Fuselage: 12 circular cross-sections
xb = m2ft([0, 1.385, 2.771, 4.156, 5.542, 6.927, 8.313, 9.698, 11.084, 12.469, 13.855, 15.24]);
rb = m2ft(m2ft([0, 0.441, 0.807, 0.976, 0.977, 0.977, 0.977, 0.977, 0.977, 0.909, 0.906, 0.906]));
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
c.wgplnf.chrdr  = m2ft(geom.wing.root_chord.v);    % root chord (ft)
c.wgplnf.chrdtp = m2ft(geom.wing.tip_chord.v);     % tip chord (ft)
c.wgplnf.sspn   = m2ft(geom.wing.span.v/2);    % total semi-span (ft)
c.wgplnf.sspne  = m2ft((geom.wing.span.v - rb(6))/2);    % exposed semi-span (ft)
c.wgplnf.savsi  = geom.wing.average_qrtr_chd_sweep.v;    % LE sweep (deg)
c.wgplnf.chstat = 0.25;     % sweep measured at LE
c.wgplnf.swafp  = 0.0;
c.wgplnf.twista = 0.0;    % 1 deg washout
c.wgplnf.sspndd = 0.0;
c.wgplnf.dhdadi = 0.0;
c.wgplnf.dhdado = 0.0;
c.wgplnf.type   = 3;       % 1 = straight taper

c.wgschr.tovc   = geom.wing.average_tc.v;    % 5% t/c root
c.wgschr.tovco  = geom.wing.average_tc.v;    % 4% t/c tip
c.wgschr.xovc   = 0.40;    % max thickness at 40% chord
c.wgschr.deltay = 8.0; % need
c.wgschr.cli    = 0.05; % need
c.wgschr.alphai = 0.5; % need 
c.wgschr.clalpa = [cLa_M1, cLa_M2, cLa_M3, cLa_M4];  % per deg, one per Mach. Need
c.wgschr.clmax  = [1.2,  1.0,  0.8,  0.6]; % need 
c.wgschr.cmo    = -0.015;
c.wgschr.leri   = 0.008; % assumed to be the same as f18
c.wgschr.clamo  = 0.105; % assumed to be the same as f18

% Horizontal tail: 55 deg LE sweep
c.htplnf.chrdr  = m2ft(model.geom.elevator.root_chord.v);    c.htplnf.chrdtp = m2ft(model.geom.elevator.tip_chord.v);
c.htplnf.sspn   = m2ft(model.geom.elevator.span.v/2);    c.htplnf.sspne  = m2ft((geom.wing.span.v - rb(11))/2);
c.htplnf.savsi  = model.geom.elevator.average_qrtr_chd_sweep.v;    c.htplnf.chstat = 0.25;
c.htplnf.swafp  = 0.0;     c.htplnf.twista = 0.0;
c.htplnf.sspndd = 0.0;     c.htplnf.dhdadi = 0.0;
c.htplnf.dhdado = 0.0;     c.htplnf.type   = 1;

c.htschr.tovc   = model.geom.elevator.average_tc.v;    c.htschr.xovc   = 0.40;
c.htschr.deltay = 4.0;     c.htschr.clalpa = [0.10, 0.10, 0.09, 0.08];
c.htschr.clmax  = [1.0, 0.9, 0.7, 0.5];
c.htschr.cmo    = 0.0;     c.htschr.leri   = 0.006;
c.htschr.clamo  = 0.105;

% Vertical tail: 50 deg LE sweep
c.vtplnf.chrdr  = m2ft(model.geom.rudder.root_chord.v);    c.vtplnf.chrdtp = m2ft(model.geom.rudder.tip_chord.v);
c.vtplnf.sspn   = m2ft(model.geom.rudder.span.v);     c.vtplnf.sspne  = m2ft(model.geom.rudder.span.v - rb(11));
c.vtplnf.savsi  = model.geom.rudder.average_qrtr_chd_sweep.v;    c.vtplnf.chstat = 0.25;
c.vtplnf.swafp  = 0.0;     c.vtplnf.twista = 0.0;
c.vtplnf.type   = 1;

c.vtschr.tovc   = model.geom.rudder.average_tc.v;    c.vtschr.xovc   = 0.40;
c.vtschr.clalpa = [0.10, 0.10, 0.09, 0.08];
c.vtschr.leri   = 0.007;

cfg.cases(1) = c;

% Write input file then run
inpFile = write_datcom_input(cfg, 'fighter_baseline.inp');
out3    = runDatcom(fullfile(examplesDir, 'fighter_baseline.inp'));

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
    plot(t.data.Alpha, t.data.CM, 'k-o', 'LineWidth', 1.5);
    xlabel('\alpha (deg)'); ylabel('C_M'); title('Pitch Moment'); grid on;

    sgtitle(sprintf('%s  M=%.1f', t.caseTitle, t.Mach));
end

if isfile(inpFile), delete(inpFile); end