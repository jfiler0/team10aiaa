%% datcom_example.m
% Full Mach sweep: JKayVLM for M < 0.6, DATCOM for M >= 0.6.
% Built from the original kevin_cad version with these fixes applied:
%   1. rb uses single m2ft (radius is a length, not an area)
%   2. rb_m kept in metres so sspne subtraction is unit-consistent
%   3. xb starts at 0.001 m (not 0) to avoid BODYRT x=0 singularity
%   4. Both write_datcom_input and runDatcom use the same resolved path
%   5. synths.zw / synths.zh use getval() for struct-or-double le_z fields
%   6. Duplicate tables removed with unique() after parseDatcomOutput

%% ---- Startup -----------------------------------------------------------
initialize
matlabSetup
build_kevin_cad

build_default_settings
settings = readSettings();
geom     = loadAircraft("kevin_cad", settings);
model    = model_class(settings, geom);
N        = 100;
perf     = performance_class(model);
settings = readSettings();

thisDir     = fileparts(mfilename('fullpath'));
examplesDir = fullfile(thisDir, 'Examples');

%% ========================================================================
%%  Part 1 — JKayVLM  (M < 0.6)
%% ========================================================================
VLM_LIMIT = 0.60;
alphaVec  = [-4, -2, 0, 2, 4, 8, 12, 16, 20];

machVLM = [0.30, 0.40, 0.50];
reVLM   = [0.9e6, 1.3e6, 1.6e6];

vlmCfg.machVec  = machVLM;
vlmCfg.alphaVec = alphaVec;
vlmCfg.xcg      = 34 * 0.3048;          % m from nose — UPDATE to your CG
vlmCfg.zcg      = -0.003 * geom.fuselage.length.v;
vlmCfg.Re       = reVLM;
vlmCfg.icase    = 3;

outVLM = runVLM(geom, vlmCfg, 'cdCorr', true, 'keepFiles', true);

fprintf('\n=== JKayVLM (M < %.2f) ===\n', VLM_LIMIT);
for k = 1:numel(outVLM.tables)
    t = outVLM.tables(k);
    fprintf('\n  [%d] M=%.2f | %s\n', k, t.Mach, t.caseTitle);
    if ~isempty(t.data) && ~all(isnan(t.data.CL)), disp(t.data); end
end

%% ========================================================================
%%  Part 2 — DATCOM  (M >= 0.6)
%% ========================================================================

cfg     = struct();
cfg.dim = 'FT';
c       = struct();
c.caseid = 'GENERIC SUPERSONIC FIGHTER - BASELINE';

% ---- Flight conditions --------------------------------------------------
machVec = [0.60, 0.90, 1.05, 1.40, 2.00];
reVec   = [2.0e6, 2.5e6, 3.0e6, 3.8e6, 4.2e6, 4.8e6, 5.5e6, 6.5e6, 7.5e6, 8.5e6, 9.5e6];
nMach   = numel(machVec);

c.fltcon.nmach  = nMach;
c.fltcon.mach   = machVec;
c.fltcon.nalpha = numel(alphaVec);
c.fltcon.alschd = alphaVec;
c.fltcon.rnnub  = reVec;

% ---- CLa and CLmax from model -------------------------------------------
cLa       = zeros(1, nMach);
for iM = 1:nMach
    perf.model.cond = levelFlightCondition(perf, 0, machVec(iM), 1);
    cLa(iM) = model.CLa;
end
perf.model.cond = levelFlightCondition(perf, 0, machVec(1), 1);

clmaxWing = linspace(1.40, 0.55, nMach);
clmaxHT   = linspace(1.10, 0.45, nMach);

% ---- Reference geometry -------------------------------------------------
c.optins.sref  = m2ft(m2ft(geom.ref_area.v));    % area: double m2ft correct
c.optins.cbarr = m2ft(geom.wing.average_chord.v);
c.optins.blref = m2ft(geom.wing.span.v);

% ---- Component positions ------------------------------------------------
c.synths.xcg    = 34;    % ft from nose — UPDATE to your actual CG
c.synths.zcg    = m2ft(-0.003 * geom.fuselage.length.v);
c.synths.xw     = m2ft(geom.wing.le_x.v);
c.synths.zw     = m2ft(getval(geom.wing.sections(1).le_z));
c.synths.aliw   = 0;
c.synths.xh     = m2ft(geom.elevator.le_x.v);
c.synths.zh     = m2ft(getval(geom.elevator.sections(1).le_z));
c.synths.alih   = 0.0;
c.synths.xv     = m2ft(geom.rudder.le_x.v);
c.synths.vertup = true;

% ---- Fuselage body ------------------------------------------------------
% Build a parametric body from actual fuselage dimensions.
% BLN = nose length = x-position of first measured station from nose tip
% BLA = afterbody length = total length minus x-position of last station
% No station at x=0 — nose is handled analytically via BNOSE=2.
%
% Station fractions are normalised so first station is well clear of nose.
L_m   = getval(geom.fuselage.length);   % total length (m)
D_m   = getval(geom.fuselage.diameter); % max diameter (m)
r_max_m = D_m / 2;

% 8 stations from 15% to 90% of fuselage length
xFrac = [0.15, 0.25, 0.35, 0.45, 0.55, 0.65, 0.75, 0.90];
% Radius profile: taper up to max, hold, taper to tail
rFrac = [0.65, 0.90, 1.00, 1.00, 1.00, 0.97, 0.93, 0.75];

xb_m = xFrac * L_m;
rb_m = rFrac * r_max_m;

xb = m2ft(xb_m);
rb = m2ft(rb_m);   % single m2ft — radius is a length

bln_ft = xb(1);              % nose = tip to first station
bla_ft = m2ft(L_m) - xb(end); % afterbody = last station to tail

c.body.nx    = numel(xb);
c.body.bnose = 2;
c.body.btail = 1;
c.body.bln   = bln_ft;
c.body.bla   = bla_ft;
c.body.x     = xb;
c.body.r     = rb;
c.body.s     = pi * rb.^2;
c.body.p     = 2 * pi * rb;

% ---- Wing ---------------------------------------------------------------
c.wgplnf.chrdr  = m2ft(geom.wing.root_chord.v);
c.wgplnf.chrdtp = m2ft(geom.wing.tip_chord.v);
c.wgplnf.sspn   = m2ft(geom.wing.span.v / 2);
% sspne: subtract body radius at wing-root station (rb_m in metres, span in metres)
rb_at_wing_m = interp1(xb_m, rb_m, L_m * 0.45, 'linear', rb_m(1)); % approx wing root station
c.wgplnf.sspne  = m2ft((geom.wing.span.v - rb_at_wing_m) / 2);
c.wgplnf.savsi  = geom.wing.average_qrtr_chd_sweep.v;
c.wgplnf.chstat = 0.25;
c.wgplnf.swafp  = 0.0;  c.wgplnf.twista = 0.0;
c.wgplnf.sspndd = 0.0;  c.wgplnf.dhdadi = 0.0;  c.wgplnf.dhdado = 0.0;
c.wgplnf.type   = 3;

c.wgschr.tovc   = geom.wing.average_tc.v;
c.wgschr.tovco  = geom.wing.average_tc.v;
c.wgschr.xovc   = 0.40;
c.wgschr.deltay = 8.0;  c.wgschr.cli = 0.05;  c.wgschr.alphai = 0.5;
c.wgschr.clalpa = cLa;  c.wgschr.clmax = clmaxWing;
c.wgschr.cmo    = -0.015;  c.wgschr.leri = 0.008;  c.wgschr.clamo = 0.105;

% ---- Horizontal tail ----------------------------------------------------
c.htplnf.chrdr  = m2ft(model.geom.elevator.root_chord.v);
c.htplnf.chrdtp = m2ft(model.geom.elevator.tip_chord.v);
c.htplnf.sspn   = m2ft(model.geom.elevator.span.v / 2);
rb_at_ht_m = interp1(xb_m, rb_m, L_m * 0.80, 'linear', rb_m(end)); % approx HT root station
c.htplnf.sspne  = m2ft((model.geom.elevator.span.v - rb_at_ht_m) / 2);
c.htplnf.savsi  = model.geom.elevator.average_qrtr_chd_sweep.v;
c.htplnf.chstat = 0.25;
c.htplnf.swafp  = 0.0;  c.htplnf.twista = 0.0;
c.htplnf.sspndd = 0.0;  c.htplnf.dhdadi = 0.0;  c.htplnf.dhdado = 0.0;
c.htplnf.type   = 1;

c.htschr.tovc   = model.geom.elevator.average_tc.v;
c.htschr.xovc   = 0.40;  c.htschr.deltay = 4.0;
c.htschr.clalpa = repmat(0.095, 1, nMach);
c.htschr.clmax  = clmaxHT;
c.htschr.cmo    = 0.0;  c.htschr.leri = 0.006;  c.htschr.clamo = 0.105;

% ---- Vertical tail ------------------------------------------------------
c.vtplnf.chrdr  = m2ft(model.geom.rudder.root_chord.v);
c.vtplnf.chrdtp = m2ft(model.geom.rudder.tip_chord.v);
c.vtplnf.sspn   = m2ft(model.geom.rudder.span.v);
c.vtplnf.sspne  = m2ft(model.geom.rudder.span.v - rb_at_ht_m);
c.vtplnf.savsi  = model.geom.rudder.average_qrtr_chd_sweep.v;
c.vtplnf.chstat = 0.25;
c.vtplnf.swafp  = 0.0;  c.vtplnf.twista = 0.0;
c.vtplnf.type   = 1;

c.vtschr.tovc   = model.geom.rudder.average_tc.v;
c.vtschr.xovc   = 0.40;
c.vtschr.clalpa = repmat(0.090, 1, nMach);
c.vtschr.leri   = 0.007;

cfg.cases(1) = c;

% ---- Write and run ------------------------------------------------------
% Write to pwd, copy to Examples/ so runDatcom always sees the fresh file.
inpFileLocal = write_datcom_input(cfg, 'fighter_baseline.inp');
inpFile      = fullfile(examplesDir, 'fighter_baseline.inp');
copyfile(inpFileLocal, inpFile, 'f');

outDATCOM = runDatcom(inpFile, 'keepOut', true);

fprintf('DATCOM: status=%d  tables=%d\n', outDATCOM.status, numel(outDATCOM.tables));

% Deduplicate (parseDatcomOutput picks up both main + auxiliary sections)
if numel(outDATCOM.tables) > 0
    [~, uIdx]        = unique([outDATCOM.tables.Mach], 'stable');
    outDATCOM.tables = outDATCOM.tables(uIdx);
end

fprintf('\n=== DATCOM (M >= %.2f) ===\n', VLM_LIMIT);
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
%%  Merge + plots
%% ========================================================================

allTables = [outVLM.tables, outDATCOM.tables];
[~, idx]  = sort([allTables.Mach]);
allTables = allTables(idx);
[~, uIdx] = unique([allTables.Mach], 'stable');
allTables = allTables(uIdx);

fprintf('\n=== MERGED sweep (%d Mach points) ===\n', numel(allTables));
for k = 1:numel(allTables)
    t = allTables(k);
    src = 'VLM   '; if t.Mach >= VLM_LIMIT, src = 'DATCOM'; end
    fprintf('  [%d] M=%.2f  %-6s  data=%d\n', k, t.Mach, src, ...
        ~isempty(t.data) && ~all(isnan(t.data.CL)));
end

% ---- CL, CD, CM vs alpha ------------------------------------------------
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
for sp = 1:3; subplot(1,3,sp); legend('Location','best','Interpreter','none','FontSize',7); end
sgtitle('VLM (dashed ^) + DATCOM (solid o)','Interpreter','none');

% ---- CLa continuity at M=0.6 join --------------------------------------
machPts = [allTables.Mach];
CLaAll  = NaN(1, numel(allTables));
for k = 1:numel(allTables)
    t = allTables(k);
    if isempty(t.data) || all(isnan(t.data.CLA)), continue; end
    [~,i0] = min(abs(t.data.Alpha));
    CLaAll(k) = t.data.CLA(i0);
end
isVLMpts = machPts < VLM_LIMIT;
figure('Name','CLa continuity');
msk = isVLMpts & ~isnan(CLaAll);
if any(msk), plot(machPts(msk),CLaAll(msk),'b--^','LineWidth',2,'DisplayName','VLM'); hold on; end
msk = ~isVLMpts & ~isnan(CLaAll);
if any(msk), plot(machPts(msk),CLaAll(msk),'b-o','LineWidth',1.5,'DisplayName','DATCOM'); hold on; end
xline(VLM_LIMIT,'k--','LineWidth',1.5); grid on;
xlabel('Mach','Interpreter','none'); ylabel('CLa (per deg)','Interpreter','none');
title('Lift-curve slope continuity at VLM/DATCOM join','Interpreter','none');
legend('Interpreter','none');

%% ---- Cleanup -----------------------------------------------------------
if isfile(inpFileLocal), delete(inpFileLocal); end


% =========================================================================
function v = getval(x)
%GETVAL  Return numeric value from plain double or .v struct field.
if isstruct(x), v = x.v; else, v = double(x); end
end

function s = ternary(cond, a, b)
if cond, s = a; else, s = b; end
end