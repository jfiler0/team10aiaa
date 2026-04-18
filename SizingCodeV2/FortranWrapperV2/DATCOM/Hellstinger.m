clear all
close all
%% datcom_example.m  (Hellstinger)
% Full Mach sweep: JKayVLM for M < 0.6, DATCOM for M >= 0.6.
% Classical scissor plot included — GOT RID OF UNTITLED 2 !!!!!!!!!

%% ---- Startup -----------------------------------------------------------
initialize
matlabSetup% build_kevin_cad

% build_default_settings
% settings = readSettings();
% geom     = loadAircraft("Copy_of_kevin_cad", settings);
build_hellstinger

build_default_settings
settings = readSettings();
geom     = loadAircraft("HellstingerV3", settings);
model    = model_class(settings, geom);
N        = 100;
perf     = performance_class(model);
settings = readSettings();

thisDir     = fileparts(mfilename('fullpath'));
examplesDir = fullfile(thisDir, 'Examples');
perf.model.cond = levelFlightCondition(perf, 0, 0.3, model.geom.weights.mtow.v);

displayAircraftGeom(geom)

%% ========================================================================
%%  Part 1 — JKayVLM  (M < 0.6)
%% ========================================================================
VLM_LIMIT = 0.60;
alphaVec  = [-4, -2, 0, 2, 4, 8, 12, 16, 20, 40, 60, 80];

machVLM = [0.20, 0.30, 0.40, 0.50];
reVLM   = [0.75e6, 0.9e6, 1.3e6, 1.6e6];

vlmCfg.machVec  = machVLM;
vlmCfg.alphaVec = alphaVec;
vlmCfg.xcg      = 32 * 0.3048;
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

% ---- Shared geometry (computed once) ------------------------------------
L_m     = getval(geom.fuselage.length);
D_m     = getval(geom.fuselage.diameter);
r_max_m = D_m / 2;

xFrac = [0.15, 0.30, 0.50, 0.70, 0.88];
rFrac = [0.70, 1.00, 1.00, 0.95, 0.78];
xb_m  = xFrac * L_m;
rb_m  = rFrac * r_max_m;
xb    = m2ft(xb_m);
rb    = m2ft(rb_m);
bln_ft = xb(1);
bla_ft = m2ft(L_m) - xb(end);

rb_at_wing_m = interp1(xb_m, rb_m, L_m * 0.45, 'linear', rb_m(1));
rb_at_ht_m   = interp1(xb_m, rb_m, L_m * 0.80, 'linear', rb_m(end));

% =========================================================================
function tbl = runDatcomPass(cfg, geom, model, examplesDir, ...
                              machVec, reVec, alphaVec, ...
                              xb, rb, xb_m, rb_m, bln_ft, bla_ft, ...
                              rb_at_wing_m, rb_at_ht_m, passName)
    nMach = numel(machVec);

    cLa = zeros(1, nMach);
    for iM = 1:nMach
        M = machVec(iM);
        if M < 1.0
            cLa(iM) = (2*pi / sqrt(1 - M^2)) * (pi/180);
        else
            cLa(iM) = (4 / sqrt(M^2 - 1)) * (pi/180);
        end
    end
    clmaxWing = linspace(1.40, 0.90, nMach);
    clmaxHT   = linspace(1.10, 0.75, nMach);

    c = struct();
    c.caseid = 'GENERIC SUPERSONIC FIGHTER - BASELINE';
    c.fltcon.nmach  = nMach;   c.fltcon.mach   = machVec;
    c.fltcon.nalpha = numel(alphaVec);
    c.fltcon.alschd = alphaVec;
    c.fltcon.rnnub  = reVec;

    c.optins.sref  = m2ft(m2ft(geom.ref_area.v));
    c.optins.cbarr = m2ft(geom.wing.average_chord.v);
    c.optins.blref = m2ft(geom.wing.span.v);

    c.synths.xcg    = 32;
    c.synths.zcg    = m2ft(-0.003 * geom.fuselage.length.v);
    c.synths.xw     = m2ft(geom.wing.le_x.v);
    c.synths.zw     = m2ft(getval(geom.wing.sections(1).le_z));
    c.synths.aliw   = 0;
    c.synths.xh     = m2ft(geom.elevator.le_x.v);
    c.synths.zh     = m2ft(getval(geom.elevator.sections(1).le_z));
    c.synths.alih   = 0.0;
    c.synths.xv     = m2ft(geom.rudder.le_x.v);
    c.synths.zv     = m2ft(getval(geom.rudder.sections(1).le_z));  % <-- ADD
    c.synths.vertup = true;
    

    c.body.nx = 5;  c.body.bnose = 2;  c.body.btail = 1;
    c.body.bln = bln_ft;  c.body.bla = bla_ft;
    c.body.x = xb;  c.body.r = rb;
    c.body.s = pi*rb.^2;  c.body.p = 2*pi*rb;

    c.wgplnf.chrdr  = m2ft(geom.wing.root_chord.v);
    c.wgplnf.chrdtp = m2ft(geom.wing.tip_chord.v);
    c.wgplnf.sspn   = m2ft(geom.wing.span.v / 2);
    c.wgplnf.sspne  = m2ft((geom.wing.span.v - rb_at_wing_m) / 2);
    c.wgplnf.savsi  = geom.wing.average_qrtr_chd_sweep.v;
    c.wgplnf.chstat = 0.25;
    c.wgplnf.swafp  = 0.0;  c.wgplnf.twista = 0.0;
    c.wgplnf.sspndd = 0.0;  c.wgplnf.dhdadi = 0.0;  c.wgplnf.dhdado = 0.0;
    c.wgplnf.type   = 2;
    c.wgschr.tovc   = geom.wing.average_tc.v;
    c.wgschr.tovco  = geom.wing.average_tc.v;
    c.wgschr.xovc   = 0.40;
    c.wgschr.deltay = 8.0;  c.wgschr.cli = 0.05;  c.wgschr.alphai = 0.5;
    c.wgschr.clalpa = cLa;  c.wgschr.clmax = clmaxWing;
    c.wgschr.cmo    = -0.015;  c.wgschr.leri = 0.008;  c.wgschr.clamo = 0.105;


    c.htplnf.chrdr  = m2ft(model.geom.elevator.root_chord.v);
    c.htplnf.chrdtp = m2ft(model.geom.elevator.tip_chord.v);
    c.htplnf.sspn   = m2ft(model.geom.elevator.span.v / 2);
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

    c.vtplnf.chrdr  = m2ft(model.geom.rudder.root_chord.v);
    c.vtplnf.chrdtp = m2ft(model.geom.rudder.tip_chord.v);
    c.vtplnf.sspn   = m2ft(model.geom.rudder.span.v);
    c.vtplnf.sspne  = m2ft(model.geom.rudder.span.v - rb_at_ht_m);
    c.vtplnf.savsi  = model.geom.rudder.average_qrtr_chd_sweep.v;
    c.vtplnf.chstat = 0.25;
    c.vtplnf.swafp  = 0.0;  c.vtplnf.twista = 0.0;
    c.vtplnf.type   = 1;
    c.vtschr.tovc   = model.geom.rudder.average_tc.v;
    c.vtschr.tovco  = model.geom.rudder.average_tc.v;
    c.vtschr.xovc   = 0.40;
    c.vtschr.deltay = 6.0;
    c.vtschr.cli    = 0.0;
    c.vtschr.alphai = 0.0;
    c.vtschr.cmo    = 0.0;
    c.vtschr.clamo  = 0.095;
    c.vtschr.clalpa = repmat(0.090, 1, nMach);
    c.vtschr.clmax  = repmat(0.80,  1, nMach);
    c.vtschr.leri   = 0.007;

    cfgPass  = struct(); cfgPass.dim = 'FT'; cfgPass.cases(1) = c;
    inpLocal = write_datcom_input(cfgPass, [passName '.inp']);

    inpLines = splitlines(string(fileread(inpLocal)));
    for kL = 1:numel(inpLines)
        if strlength(inpLines(kL)) > 72
            fprintf('WARNING [%s] line %d too long (%d chars)\n', ...
                    passName, kL, strlength(inpLines(kL)));
        end
    end

    inpFile = fullfile(examplesDir, [passName '.inp']);
    copyfile(inpLocal, inpFile, 'f');
    out = runDatcom(inpFile, 'keepOut', true);
    fprintf('DATCOM %s: status=%d  raw tables=%d\n', passName, out.status, numel(out.tables));

       tbl = out.tables([]);
    if numel(out.tables) > 0
        mL = [out.tables.Mach];
        uM = unique(mL);
        for km = 1:numel(uM)
            idx = find(mL == uM(km));
            tbl = [tbl, out.tables(idx)];  % keep ALL tables (long. + lat.-dir.)
        end
    end
    if isfile(inpLocal), delete(inpLocal); end
end

% =========================================================================
cfg = struct(); cfg.dim = 'FT';

machA = [0.20, 0.30, 0.40, 0.50, 0.60, 0.75, 1.15, 1.30, 1.50];
reA   = [2.0e6, 2.8e6, 3.5e6, 4.5e6, 5.5e6, 6.5e6, 7.5e6, 8.0e6, 8.5e6];
tblA  = runDatcomPass(cfg, geom, model, examplesDir, ...
                      machA, reA, alphaVec, xb, rb, xb_m, rb_m, ...
                      bln_ft, bla_ft, rb_at_wing_m, rb_at_ht_m, 'datcom_A');

machB = [1.20, 1.35, 1.65, 1.80];
reB   = [5.0e6, 5.8e6, 7.2e6, 8.0e6];
tblB  = runDatcomPass(cfg, geom, model, examplesDir, ...
                      machB, reB, alphaVec, xb, rb, xb_m, rb_m, ...
                      bln_ft, bla_ft, rb_at_wing_m, rb_at_ht_m, 'datcom_B');

machC = [1.60, 1.70, 1.80, 1.90, 2.00];
reC   = [7.5e6, 8.0e6, 8.5e6, 9.0e6, 9.5e6];
tblC  = runDatcomPass(cfg, geom, model, examplesDir, ...
                      machC, reC, alphaVec, xb, rb, xb_m, rb_m, ...
                      bln_ft, bla_ft, rb_at_wing_m, rb_at_ht_m, 'datcom_C');

rawTables = [tblA, tblB, tblC];
outDATCOM.tables = rawTables;  % keep all — both long. and lat.-dir. tables per Mach

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
[~, uIdx] = unique([allTables.Mach]);
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

%% ========================================================================
%%  Neutral point & static margin vs Mach
%% ========================================================================
%% ========================================================================
%%  Correct Static Margin vs Mach (REFERENCE SHIFTED TO CG)
%% ========================================================================

% xcg_ft  = 32;                               % ft from nose — UPDATE to your CG
xcg_ft  = 32;   % <-- your CG from nose [ft]
cbar_ft = m2ft(geom.wing.average_chord.v);

machPts = [allTables.Mach];
nPts    = numel(allTables);

machPts = [allTables.Mach]; nPts = numel(allTables); CLa_pt = NaN(1, nPts); CMa_pt = NaN(1, nPts); 

for k = 1:nPts t = allTables(k); 
    if isempty(t.data), continue; 
    end 
    [~, i0] = min(abs(t.data.Alpha)); 
    if ~isnan(t.data.CLA(i0)), CLa_pt(k) = t.data.CLA(i0); 
    end 
    if ~isnan(t.data.CMA(i0)), CMa_pt(k) = t.data.CMA(i0); 
    end 
end

CLA_vec      = NaN(1, nPts);   % lift curve slope (per deg)
CMA_nose_vec = NaN(1, nPts);   % moment slope about nose
CMA_cg_vec   = NaN(1, nPts);   % corrected moment slope about CG
SM_vec       = NaN(1, nPts);   % static margin

for k = 1:nPts
    t = allTables(k);

    if isempty(t.data), continue; end

    % Find alpha closest to 0 (DATCOM reports derivatives here)
    [~, i0] = min(abs(t.data.Alpha));

    % Extract slopes
    CLA = t.data.CLA(i0);   % per deg
    CMA_nose = t.data.CMA(i0); % per deg (about nose)

    if isnan(CLA) || isnan(CMA_nose), continue; end

    % Store raw values
    CLA_vec(k)      = CLA;
    CMA_nose_vec(k) = CMA_nose;

    % 🔑 SHIFT MOMENT TO CG
    CMA_cg = CMA_nose - CLA * (xcg_ft)/m2ft(model.geom.fuselage.length.v);

    CMA_cg_vec(k) = CMA_cg;

    % 🔑 COMPUTE STATIC MARGIN
    SM_vec(k) = -CMA_cg / CLA;
end

% Convert to percent
SM_percent = SM_vec * 100;

% Mask valid points
validMask = ~isnan(SM_percent) & ~isinf(SM_percent);
isVLMpts  = machPts < VLM_LIMIT;

%% ---- Plot --------------------------------------------------------------
figure('Name','Corrected Static Margin vs Mach','Position',[200 200 700 500]);
hold on; grid on; box on;

yline(0,'k--','LineWidth',1.5,'DisplayName','Neutral Stability');
yline(5,'g:','LineWidth',1.2,'DisplayName','SM = 5%');

msk = validMask & isVLMpts;
if any(msk)
    plot(machPts(msk), SM_percent(msk), 'r--^', ...
        'LineWidth',2,'MarkerSize',8,'DisplayName','SM (VLM)');
end

msk = validMask & ~isVLMpts;
if any(msk)
    plot(machPts(msk), SM_percent(msk), 'r-o', ...
        'LineWidth',2,'MarkerSize',8,'DisplayName','SM (DATCOM)');
end

xline(VLM_LIMIT,'k:','LineWidth',1.2);

xlabel('Mach');
ylabel('Static Margin (% MAC)');
title('Corrected Static Margin vs Mach (CG-referenced)');
legend('Location','best');

%% ---- Debug print (VERY useful) -----------------------------------------
fprintf('\n=== Corrected Static Margin Debug ===\n');
fprintf('Mach    CLA(/deg)   CMA_nose   CMA_cg   SM(%%)\n');

for k = 1:nPts
    if ~validMask(k), continue; end
    fprintf('%.2f    %8.4f    %8.4f    %8.4f    %8.2f\n', ...
        machPts(k), CLA_vec(k), CMA_nose_vec(k), ...
        CMA_cg_vec(k), SM_percent(k));
end
%% ========================================================================
%%  Classical Scissor Plot
%% ========================================================================
% =========================================================================
% PARAMETERS — UPDATE THESE
% =========================================================================
x_cg_full  = 0.649 * m2ft(model.geom.fuselage.length.v);  % CG at MGTOW (ft)
x_cg_empty = 0.617 * m2ft(model.geom.fuselage.length.v);  % CG at empty (ft)

CM_ac_w    = -0.015;     % wing zero-lift CM (from wgschr.cmo)
eta_H      = 0.86;       % HT efficiency
tau        = 0.70;       % elevator effectiveness (hinged ~0.65, stabilator ~1.0)
delta_e_max = 25;        % max elevator deflection (deg)
CL_design  = 0.30;       % design CL for control sizing — UPDATE
zEng = 0.167386;
CM_E       = model.geom.prop.T0_NoAB.v * zEng / ...
      (model.cond.qinf.v * model.geom.ref_area.v * model.geom.wing.average_chord.v);        % engine pitching moment (set 0 if unknown)
% =========================================================================

% ---- Geometry -----------------------------------------------------------
lambda_w  = model.geom.wing.tip_chord.v / model.geom.wing.root_chord.v;
AR_w      = model.geom.wing.AR.v;
LambdaLE  = deg2rad(model.geom.wing.average_sweep.v);
Lambda_c4 = deg2rad(model.geom.wing.average_qrtr_chd_sweep.v);
b_w       = model.geom.wing.span.v;   % m

% HT moment arm (from xcg to HT quarter-chord, ft)
l_h = m2ft(model.geom.elevator.qrtr_chd_x.v - model.geom.wing.qrtr_chd_x.v);

% Vertical offset HT from wing (ft) — hardcoded if field unavailable
z_H = 0.1;

elevrootchord = model.geom.elevator.root_chord.v;
elevtipchord = model.geom.elevator.tip_chord.v;
%elevrootchord = 3;
%elevtipchord = 1.8;
% HT area (ft^2, trapezoidal)
SH_ft2 = m2ft(m2ft((elevrootchord + ...
                     elevtipchord) / 2 ...
                     * model.geom.elevator.span.v));
SW_ft2 = m2ft(m2ft(geom.ref_area.v));

fprintf('\n=== Scissor Plot Setup ===\n');
fprintf('  l_h = %.2f ft   z_H = %.3f ft\n', l_h, z_H);
fprintf('  SH = %.2f ft^2   SW = %.2f ft^2   SH/SW actual = %.4f\n', ...
        SH_ft2, SW_ft2, SH_ft2/SW_ft2);
fprintf('  x_cg_full = %.2f ft   x_cg_empty = %.2f ft   x_ac_wb = %.2f ft\n', ...
        x_cg_full, x_cg_empty);

% ---- Lift curve slopes (per rad) ----------------------------------------
cla_2d     = 2*pi;
CLalpha_w  = cla_2d / (1 + cla_2d / (pi * AR_w));   % wing /rad (Helmbold)
AR_H       = model.geom.elevator.span.v^2 / (SH_ft2 / 3.28084^2);
CLalpha_H  = cla_2d / (1 + cla_2d / (pi * AR_H));    % HT /rad

% Wing-body CLalpha: use DATCOM M=0.6 value converted to /rad
ref_idx    = find(~isnan(CLa_pt) & abs(machPts - 0.60) < 0.05, 1);
if isempty(ref_idx), [~, ref_idx] = min(abs(machPts - 0.60)); end
CLalpha_wb = CLa_pt(ref_idx) * (180/pi);   % /rad

lambda   = model.geom.wing.tip_chord.v / model.geom.wing.root_chord.v;
AR_w     = model.geom.wing.AR.v;
LambdaLE = deg2rad(model.geom.wing.average_sweep.v);  % LE sweep in rad

xac_wing_frac = 0.25 + (tan(LambdaLE)/4) * (1 + 2*lambda) / ((1 + lambda) * AR_w);
x_ac_w = model.geom.wing.le_x.v + xac_wing_frac * model.geom.wing.root_chord.v;

% Body lift curve slope (DATCOM slender body approx)
% Munk factor K2 ~ 0.9 for typical fuselage fineness ratios
K2         = 0.9;
S_Bmax     = model.geom.fuselage.max_area.v;  % max cross-section area
CLalpha_B  = 2 * K2 * S_Bmax / model.geom.wing.area.v; % per radian

% Body AC: for slender fuselage approximately at 25% body length
% More accurate: use Munk integral, but 25% is standard first estimate
x_ac_B = 0.25 * model.geom.fuselage.length.v;

% Combined wing-body AC (area-weighted)
x_ac_wb = m2ft((x_ac_w * CLalpha_w + x_ac_B * CLalpha_B) / CLalpha_wb);
% x_ac_wb = 31.5;
% ---- Downwash gradient (Nelson/DATCOM) ----------------------------------
K_A      = 1/AR_w - 1/(1 + AR_w^1.7);
K_lambda = (10 - 3*lambda_w) / 7;
K_H      = (1 - abs(z_H / b_w)) / (2 * l_h / b_w)^(1/3);
depsda = 4.44 * (K_A * K_lambda * K_H * sqrt(cos(Lambda_c4)))^1.19;
%depsda = 0.1;
fprintf('  dε/dα = %.4f (clamped)\n', depsda);

% ---- Wing CMac (sweep correction) ---------------------------------------
CMW = CM_ac_w * (AR_w + 2*cos(Lambda_c4)) / (AR_w + 4*cos(Lambda_c4));

% ---- Scissor curve functions --------------------------------------------

xcg_ac_norm_cntrl = linspace(-0.35,0,400);
xcg_ac_norm_stab = linspace(0,0.35,400);
% Stability limit (positive slope)
K_stab      = CLalpha_H * eta_H * (1 - depsda) * (l_h / cbar_ft);
SHSW_stab   = @(x) CLalpha_wb*180/pi .* x ./ K_stab;

% Control limit (negative slope)
inc = -0.09;
eps0      = 2 * model.cond.CL.v / (pi * model.geom.wing.AR.v);
CLH_max   = CLalpha_H * (-eps0-inc);
K_ctrl    = CLH_max * eta_H * (l_h / cbar_ft);
SHSW_ctrl = @(x) (model.cond.CL.v .* x +CMW + CM_E) ./ K_ctrl;

% Normalised CG limits
Xcg_full_norm  = (x_cg_full  - x_ac_wb) / cbar_ft;
Xcg_empty_norm = (x_cg_empty - x_ac_wb) / cbar_ft;

% Design SH/SW
x_fwd = min(Xcg_full_norm, Xcg_empty_norm);
x_aft = max(Xcg_full_norm, Xcg_empty_norm);
SH_design = max(SHSW_stab(x_aft), SHSW_ctrl(x_fwd));

slope_s     = SHSW_stab(1)  - SHSW_stab(0);
slope_c     = SHSW_ctrl(1)  - SHSW_ctrl(0);
intercept_c = SHSW_ctrl(0);
x_stab_cross = SH_design / slope_s;
x_ctrl_cross = (SH_design - intercept_c) / slope_c;
SH_SW_actual = SH_ft2 / SW_ft2;

fprintf('  SH/SW design = %.4f   SH/SW actual = %.4f\n', SH_design, SH_SW_actual);

% ---- Plot ---------------------------------------------------------------
figure('Name','Hellstinger Scissor Plot','Position',[50 50 700 620]);
hold on; grid on; box on;

plot(xcg_ac_norm_stab, SHSW_stab(xcg_ac_norm_stab), 'r-',  'LineWidth', 2.5, 'DisplayName', 'Stability Limit');
plot(xcg_ac_norm_cntrl, SHSW_ctrl(xcg_ac_norm_cntrl), 'g-',  'LineWidth', 2.5, 'DisplayName', 'Control Limit');

yline(SH_SW_actual, 'b--', 'LineWidth', 1.5, ...
      'DisplayName', sprintf('S_H/S_W actual = %.3f', SH_SW_actual));

plot(x_ctrl_cross, SH_design, 'gs', 'MarkerFaceColor','g','MarkerSize',9,'HandleVisibility','off');
plot(0, (SHSW_stab(0) + SHSW_ctrl(0))/2, 'ks', 'MarkerFaceColor','k','MarkerSize',12,'HandleVisibility','off');
xline(Xcg_full_norm,  'Color',[0.35 0.35 0.35],'LineWidth',2.5,'HandleVisibility','off');
xline(Xcg_empty_norm, 'Color',[0.35 0.35 0.35],'LineWidth',2.5,'HandleVisibility','off');
yl = ylim;
text(Xcg_full_norm,  yl(2)*0.95, 'XCG at MGTOW', ...
     'Rotation',90,'HorizontalAlignment','right','FontSize',9,'Color',[0.35 0.35 0.35],'FontWeight','bold');
text(Xcg_empty_norm, yl(2)*0.95, 'XCG at empty weight', ...
     'Rotation',90,'HorizontalAlignment','right','FontSize',9,'Color',[0.35 0.35 0.35],'FontWeight','bold');

xline(0,'k:','LineWidth',0.8,'HandleVisibility','off');
xlim([-0.35, 0.35]); ylim([-0.8, 0.8]);
xlabel('x_{cg} - x_{ac} normalized','Interpreter','tex','FontSize',12);
ylabel('S_H/S_W','Interpreter','tex','FontSize',12);
title('Hellstinger Longitudinal Stability','FontSize',13);
text(-0.33, SH_design+0.07, sprintf('  S_H/S_W = %.3f', SH_design), ...
     'FontSize',11,'Color','b','FontWeight','bold');

m_stab = CLalpha_wb*180/pi / K_stab;

x_anchor = x_aft;        % right CG limit (already defined)
y_anchor = SH_design;    % horizontal blue line value

x_trunc = linspace(0, max(xcg_ac_norm_stab), 200);
y_trunc = m_stab * (x_trunc - x_anchor) + y_anchor;

plot(x_trunc, y_trunc, 'r--', 'LineWidth', 2, ...
    'DisplayName','Stability (truncated)');
x_blue = linspace(x_ctrl_cross, x_anchor, 100);
plot(x_blue, SH_design*ones(size(x_blue)), 'b-', 'LineWidth', 2, ...
    'DisplayName', sprintf('S_H/S_W design = %.3f', SH_design));

plot(x_anchor, y_anchor, 'rs', ...
    'MarkerFaceColor','r','MarkerSize',9,'HandleVisibility','off');

% Intersection of stability line with horizontal design line
x_int = SH_design / m_stab;

% Static margin relative to aft CG
static_margin = x_int - x_aft;

plot(x_int, SH_design, 'ko', 'MarkerFaceColor','k')

y_arrow = SH_design;   % keep it on the design line


dx = (x_int - x_aft);

% Draw thick arrow
quiver(x_aft, y_arrow, ...
       (x_int - x_aft), 0, ...   % horizontal arrow
       0, ...                    % no auto scaling
       'k', 'LineWidth', 3, 'MaxHeadSize', 4);

% Arrow from intersection → aft CG (reverse direction)
quiver(x_int, y_arrow, -dx, 0, 0, ...
    'k','LineWidth',3,'MaxHeadSize',4,'HandleVisibility','off');

% --- Text label ---
x_mid = (x_aft + x_int)/2;

text(0.1, y_arrow + 0.2, ...
    sprintf('STATIC MARGIN = %.3f', static_margin), ...
    'HorizontalAlignment','center', ...
    'FontSize',18, ...
    'FontWeight','bold', ...
    'Color','k');
legend('Location','northwest','FontSize',10);

%% CN_beta vs. alpha generation
CN_beta = 180/pi *-1*[-0.0007911 -0.0007198 -0.0006842 -0.0007198 -0.0007882 -0.000919];
Alpha_vec = [-4 -2 0 2 4 8, 10, 20, 40, 60, 80];
figure; 
plot(Alpha_vec,CN_beta);
xlabel('alpha (deg)')
ylabel('Cn_beta (/deg)')
title('Cn_Beta vs. alpha');

plot_0412_planform('datcom', xb, rb, x_cg_full, x_cg_empty, ...
                   x_ac_wb, Xnp_ft, SM_mach, machPts, ...
                   VLM_LIMIT, cbar_ft, validMask, isVLMpts)

Alpha_vec = [-4 -2 0 2 4 8];

figure;
plot(Alpha_vec, CN_beta, 'b-o', 'LineWidth', 1.5);
xlabel('alpha (deg)')
ylabel('Cn\_beta (/deg)')
title('Cn\_Beta vs. alpha');

% Set y-axis lower limit to -0.01
ylim([-0.01, max(ylim)]);

% Horizontal line at y = 0 — Level 1 flying qualities requirement
yline(0, 'r--', 'LineWidth', 1.5, 'Label', 'Level 1 Flying Qualities Requirement', ...
    'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment', 'bottom');

% Horizontal line at y = 0.04 — Navy preferred yaw stability value
yline(0.04, 'k--', 'LineWidth', 1.5, 'Label', 'Navy Preferred Yaw Stability value', ...
    'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment', 'bottom');
legend('Cn_beta');
grid on;
% =========================================================================
function v = getval(x)
if isstruct(x), v = x.v; else, v = double(x); end
end

function s = ternary(cond, a, b)
if cond, s = a; else, s = b; end
end

