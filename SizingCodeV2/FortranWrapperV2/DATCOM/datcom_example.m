%% datcom_example.m
% Full Mach sweep: JKayVLM for M < 0.6, DATCOM for M >= 0.6.
%
% DATCOM is run as a lifting-surface-only configuration (no BODY namelist).
% This avoids body cross-section geometry issues and produces clean results
% for wing + horizontal tail + vertical tail.  Body contribution can be
% added later once fuselage cross-section data is available from kevin_cad.

<<<<<<< HEAD
%% ---- Startup -----------------------------------------------------------
initialize
matlabSetup
build_kevin_cad
=======
%% ---- Case 1: Run EX1.INP directly --------------------------------------
% Body-alone configuration, four flow regimes (subsonic -> hypersonic).
% No struct needed — pass the .INP file straight to runDatcom.

% Resolve input files relative to this script, not pwd
% datcom_example.m is in DATCOM/, .INP files are in DATCOM/Examples/
thisDir = fileparts(mfilename('fullpath'));
examplesDir = fullfile(thisDir, 'Examples');

out1 = runDatcom(fullfile(examplesDir, 'EX1.INP'));

fprintf('=== Case 1: EX1 (body alone) ===\n');
for k = 1:numel(out1.tables)
    t = out1.tables(k);
    fprintf('  [%d] M=%.2f | %s\n', k, t.Mach, t.caseTitle);
    if ~isempty(t.data) && ~all(isnan(t.data.CL))
        disp(t.data)
    end
end
>>>>>>> f47c74a7d3144a6e76e57a5e2a1d4051a455b480

build_default_settings
settings = readSettings();
geom     = loadAircraft("kevin_cad", settings);
model    = model_class(settings, geom);
N        = 100;
perf     = performance_class(model);
settings = readSettings();

<<<<<<< HEAD
thisDir     = fileparts(mfilename('fullpath'));
examplesDir = fullfile(thisDir, 'Examples');
=======
%% ---- Case 2: Run EX3.INP directly --------------------------------------
% Full configuration buildup: body + wing + horizontal tail + vertical tail.

out2 = runDatcom(fullfile(examplesDir, 'EX3.INP'));

fprintf('\n=== Case 2: EX3 (body + wing + tails) ===\n');
for k = 1:numel(out2.tables)
    t = out2.tables(k);
    fprintf('  [%d] M=%.2f | %s\n', k, t.Mach, t.caseTitle);
    if ~isempty(t.data) && ~all(isnan(t.data.CL))
        disp(t.data)
    end
end
>>>>>>> f47c74a7d3144a6e76e57a5e2a1d4051a455b480

%% ---- Shared settings ---------------------------------------------------
VLM_LIMIT = 0.60;
alphaVec  = [-4, -2, 0, 2, 4, 8, 12, 16, 20];   % deg, same for VLM and DATCOM

xcg_m = 34 * 0.3048;                              % CG x (m from nose) — UPDATE
zcg_m = -0.003 * geom.fuselage.length.v;

%% ========================================================================
%% Part 1: JKayVLM  (M < 0.6)
%% ========================================================================

machVLM = [0.30, 0.40, 0.50];
reVLM   = [0.9e6, 1.3e6, 1.6e6];

vlmCfg.machVec  = machVLM;
vlmCfg.alphaVec = alphaVec;
vlmCfg.xcg      = xcg_m;
vlmCfg.zcg      = zcg_m;
vlmCfg.Re       = reVLM;
vlmCfg.icase    = 3;

outVLM = runVLM(geom, vlmCfg, 'cdCorr', true, 'keepFiles', true);

fprintf('\n=== JKayVLM (M < %.2f) ===\n', VLM_LIMIT);
for k = 1:numel(outVLM.tables)
    t = outVLM.tables(k);
    fprintf('\n  [%d] M=%.2f | %s\n', k, t.Mach, t.caseTitle);
    if ~isempty(t.data) && ~all(isnan(t.data.CL))
        disp(t.data)
    end
end

%% ========================================================================
%% Part 2: DATCOM  (M >= 0.6)
%% ========================================================================

machDATCOM = [0.60, 0.80, 0.90, 1.20, 1.40, 1.60, 2.00];
reDATCOM   = [2.0e6, 3.0e6, 3.8e6, 5.5e6, 6.5e6, 7.5e6, 9.5e6];
nMach      = numel(machDATCOM);

<<<<<<< HEAD
assert(nMach <= 20, 'DATCOM NMACH limit is 20.');
=======
    subplot(1,3,3);
    plot(t.data.Alpha, t.data.CM, 'k-o', 'LineWidth', 1.5);
    xlabel('\alpha (deg)'); ylabel('C_M'); title('Pitch Moment'); grid on;
>>>>>>> f47c74a7d3144a6e76e57a5e2a1d4051a455b480

% CLa from model at each Mach
cLa = zeros(1, nMach);
for iM = 1:nMach
    perf.model.cond = levelFlightCondition(perf, 0, machDATCOM(iM), 1);
    cLa(iM)         = model.CLa;
end
perf.model.cond = levelFlightCondition(perf, 0, machDATCOM(1), 1);

clmaxWing = linspace(1.35, 0.55, nMach);
clmaxHT   = linspace(1.10, 0.45, nMach);

% ---- Build DATCOM cfg ---------------------------------------------------
cfg     = struct();
cfg.dim = 'FT';
c       = struct();
c.caseid = 'GENERIC SUPERSONIC FIGHTER - BASELINE';

c.fltcon.nmach  = nMach;
c.fltcon.mach   = machDATCOM;
c.fltcon.nalpha = numel(alphaVec);
c.fltcon.alschd = alphaVec;
c.fltcon.rnnub  = reDATCOM;

% Reference geometry
c.optins.sref  = m2ft(m2ft(geom.ref_area.v));   % area: double m2ft is correct
c.optins.cbarr = m2ft(geom.wing.average_chord.v);
c.optins.blref = m2ft(geom.wing.span.v);

% Component positions (ft from nose)
c.synths.xcg    = m2ft(xcg_m);
c.synths.zcg    = m2ft(zcg_m);
c.synths.xw     = m2ft(geom.wing.le_x.v);
c.synths.zw     = m2ft(getval(geom.wing.sections(1).le_z));
c.synths.aliw   = 0;
c.synths.xh     = m2ft(geom.elevator.le_x.v);
c.synths.zh     = m2ft(getval(geom.elevator.sections(1).le_z));
c.synths.alih   = 0.0;
c.synths.xv     = m2ft(geom.rudder.le_x.v);
c.synths.vertup = true;

% Body geometry from actual fuselage data.
% geom.fuselage has: length, diameter, max_area, area, E_WD
L_m   = getval(geom.fuselage.length);    % total fuselage length (m)
D_m   = getval(geom.fuselage.diameter);  % max fuselage diameter (m)
r_max = D_m / 2;                          % max radius (m)

L_ft    = m2ft(L_m);
r_max_ft = m2ft(r_max);

% Build a 6-station body profile (% of L from nose, fraction of r_max):
%   Nose junction, forward taper, max section (x2), aft taper, tail junction
% No x=0 station — nose handled analytically via BNOSE + BLN.
bln_ft = L_ft * 0.12;   % conical nose = 12% of length
bla_ft = L_ft * 0.12;   % ogive afterbody = 12% of length

xFrac = [0.12, 0.25, 0.40, 0.60, 0.75, 0.88];   % fraction of L_ft
rFrac = [0.70, 0.95, 1.00, 1.00, 0.95, 0.80];   % fraction of r_max_ft

xb_ft = xFrac * L_ft;
rb_ft = rFrac * r_max_ft;

c.body.nx    = numel(xb_ft);
c.body.bnose = 2;        % conical nose
c.body.btail = 1;        % ogive afterbody
c.body.bln   = bln_ft;
c.body.bla   = bla_ft;
c.body.x     = xb_ft;
c.body.r     = rb_ft;
c.body.s     = pi * rb_ft.^2;
c.body.p     = 2 * pi * rb_ft;

% Exposed semi-spans: subtract body radius at each surface root station
rb_at_wing = interp1(xb_ft, rb_ft, m2ft(geom.wing.le_x.v),      'linear', rb_ft(1));
rb_at_ht   = interp1(xb_ft, rb_ft, m2ft(geom.elevator.le_x.v),  'linear', rb_ft(end));
rb_at_vt   = interp1(xb_ft, rb_ft, m2ft(geom.rudder.le_x.v),    'linear', rb_ft(end));

% Wing planform + section
c.wgplnf.chrdr  = m2ft(geom.wing.root_chord.v);
c.wgplnf.chrdtp = m2ft(geom.wing.tip_chord.v);
c.wgplnf.sspn   = m2ft(geom.wing.span.v/2);
c.wgplnf.sspne  = m2ft(geom.wing.span.v/2) - rb_at_wing;
c.wgplnf.savsi  = geom.wing.average_qrtr_chd_sweep.v;
c.wgplnf.chstat = 0.25;
c.wgplnf.swafp  = 0.0; c.wgplnf.twista = 0.0;
c.wgplnf.sspndd = 0.0; c.wgplnf.dhdadi = 0.0; c.wgplnf.dhdado = 0.0;
c.wgplnf.type   = 3;
c.wgschr.tovc   = geom.wing.average_tc.v;
c.wgschr.tovco  = geom.wing.average_tc.v;
c.wgschr.xovc   = 0.40;
c.wgschr.deltay = 8.0; c.wgschr.cli = 0.05; c.wgschr.alphai = 0.5;
c.wgschr.clalpa = cLa; c.wgschr.clmax = clmaxWing;
c.wgschr.cmo    = -0.015; c.wgschr.leri = 0.008; c.wgschr.clamo = 0.105;

% Horizontal tail
c.htplnf.chrdr  = m2ft(model.geom.elevator.root_chord.v);
c.htplnf.chrdtp = m2ft(model.geom.elevator.tip_chord.v);
c.htplnf.sspn   = m2ft(model.geom.elevator.span.v/2);
c.htplnf.sspne  = m2ft(model.geom.elevator.span.v/2) - rb_at_ht;
c.htplnf.savsi  = model.geom.elevator.average_qrtr_chd_sweep.v;
c.htplnf.chstat = 0.25;
c.htplnf.swafp  = 0.0; c.htplnf.twista = 0.0;
c.htplnf.sspndd = 0.0; c.htplnf.dhdadi = 0.0; c.htplnf.dhdado = 0.0;
c.htplnf.type   = 1;
c.htschr.tovc   = model.geom.elevator.average_tc.v;
c.htschr.xovc   = 0.40; c.htschr.deltay = 4.0;
c.htschr.clalpa = repmat(0.095, 1, nMach); c.htschr.clmax = clmaxHT;
c.htschr.cmo    = 0.0; c.htschr.leri = 0.006; c.htschr.clamo = 0.105;

% Vertical tail
c.vtplnf.chrdr  = m2ft(model.geom.rudder.root_chord.v);
c.vtplnf.chrdtp = m2ft(model.geom.rudder.tip_chord.v);
c.vtplnf.sspn   = m2ft(model.geom.rudder.span.v);
c.vtplnf.sspne  = m2ft(model.geom.rudder.span.v) - rb_at_vt;
c.vtplnf.savsi  = model.geom.rudder.average_qrtr_chd_sweep.v;
c.vtplnf.chstat = 0.25;
c.vtplnf.swafp  = 0.0; c.vtplnf.twista = 0.0;
c.vtplnf.type   = 1;
c.vtschr.tovc   = model.geom.rudder.average_tc.v;
c.vtschr.xovc   = 0.40;
c.vtschr.clalpa = repmat(0.090, 1, nMach);
c.vtschr.leri   = 0.007;

cfg.cases(1) = c;

% ---- Write input and run ------------------------------------------------
inpFileLocal = write_datcom_input(cfg, 'fighter_baseline.inp');
inpFile      = fullfile(examplesDir, 'fighter_baseline.inp');
copyfile(inpFileLocal, inpFile, 'f');

outDATCOM = runDatcom(inpFile, 'keepOut', true);

fprintf('DATCOM: status=%d  tables=%d\n', outDATCOM.status, numel(outDATCOM.tables));

% Deduplicate (auxiliary output section duplicates each Mach table)
if numel(outDATCOM.tables) > 0
    [~, uIdx]        = unique([outDATCOM.tables.Mach], 'stable');
    outDATCOM.tables = outDATCOM.tables(uIdx);
end

<<<<<<< HEAD
fprintf('\n=== DATCOM (M >= %.2f, wing+tail only) ===\n', VLM_LIMIT);
for k = 1:numel(outDATCOM.tables)
    t = outDATCOM.tables(k);
    fprintf('\n  [%d] M=%.2f\n', k, t.Mach);
    if ~isempty(t.data) && ~all(isnan(t.data.CL))
        disp(t.data)
    else
        fprintf('    (no valid CL data at this Mach)\n');
    end
end

%% ========================================================================
%% Merge and plot
%% ========================================================================

allTables = [outVLM.tables, outDATCOM.tables];
[~, idx]  = sort([allTables.Mach]);
allTables = allTables(idx);
[~, uIdx] = unique([allTables.Mach], 'stable');
allTables  = allTables(uIdx);

fprintf('\n=== MERGED sweep (%d Mach points) ===\n', numel(allTables));
for k = 1:numel(allTables)
    t   = allTables(k);
    src = 'VLM   '; if t.Mach >= VLM_LIMIT, src = 'DATCOM'; end
    fprintf('  [%d] M=%.2f  %-6s  data=%d\n', k, t.Mach, src, ...
            ~isempty(t.data) && ~all(isnan(t.data.CL)));
end

%% ---- Plot: CL, CD, CM vs alpha -----------------------------------------

figure('Name','Full Mach Sweep VLM + DATCOM','Position',[50 50 1200 400]);
nT   = numel(allTables);
cmap = parula(nT);

for sp = 1:3
    subplot(1,3,sp); hold on; grid on;
    xlabel('Alpha (deg)','Interpreter','none');
    switch sp
        case 1; ylabel('CL','Interpreter','none'); title('Lift','Interpreter','none');
        case 2; ylabel('CD','Interpreter','none'); title('Drag','Interpreter','none');
        case 3; ylabel('CM','Interpreter','none'); title('Pitch Moment','Interpreter','none');
    end
end

for k = 1:nT
    t = allTables(k);
    if isempty(t.data) || all(isnan(t.data.CL)), continue; end
    isVLM  = t.Mach < VLM_LIMIT;
    lstyle = '-o'; if isVLM, lstyle = '--^'; end
    col    = cmap(k,:);
    lbl    = sprintf('M=%.2f (%s)', t.Mach, ternary(isVLM,'VLM','DAT'));
    subplot(1,3,1); plot(t.data.Alpha,t.data.CL,lstyle,'Color',col,'LineWidth',1.5,'DisplayName',lbl);
    subplot(1,3,2); plot(t.data.Alpha,t.data.CD,lstyle,'Color',col,'LineWidth',1.5,'DisplayName',lbl);
    subplot(1,3,3); plot(t.data.Alpha,t.data.CM,lstyle,'Color',col,'LineWidth',1.5,'DisplayName',lbl);
end
for sp = 1:3
    subplot(1,3,sp); legend('Location','best','Interpreter','none','FontSize',7);
end
sgtitle('VLM (dashed ^) + DATCOM wing+tail (solid o)','Interpreter','none');

%% ---- Plot: CLa continuity at join --------------------------------------

machPts  = [allTables.Mach];
CLaAll   = NaN(1, numel(allTables));
for k = 1:numel(allTables)
    t = allTables(k);
    if isempty(t.data) || all(isnan(t.data.CLA)), continue; end
    [~,i0] = min(abs(t.data.Alpha));
    CLaAll(k) = t.data.CLA(i0);
end

isVLMpts = machPts < VLM_LIMIT;
figure('Name','CLa continuity at M=0.6 join');
msk = isVLMpts & ~isnan(CLaAll);
if any(msk), plot(machPts(msk),CLaAll(msk),'b--^','LineWidth',2,'DisplayName','VLM'); hold on; end
msk = ~isVLMpts & ~isnan(CLaAll);
if any(msk), plot(machPts(msk),CLaAll(msk),'b-o','LineWidth',1.5,'DisplayName','DATCOM'); hold on; end
xline(VLM_LIMIT,'k--','LineWidth',1.5);
xlabel('Mach','Interpreter','none'); ylabel('CLa (per deg)','Interpreter','none');
title('Lift-curve slope continuity','Interpreter','none');
legend('Interpreter','none'); grid on;

%% ---- Cleanup -----------------------------------------------------------
if isfile(inpFileLocal), delete(inpFileLocal); end


% =========================================================================
function v = getval(x)
if isstruct(x), v = x.v; else, v = double(x); end
end

function s = ternary(cond, a, b)
if cond, s = a; else, s = b; end
end
=======
if isfile(inpFile), delete(inpFile); end
>>>>>>> f47c74a7d3144a6e76e57a5e2a1d4051a455b480
