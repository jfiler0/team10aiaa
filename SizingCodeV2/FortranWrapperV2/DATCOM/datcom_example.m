%% datcom_example.m
% Full Mach sweep: JKayVLM for M < 0.6, DATCOM for M >= 0.6.
% Built from the original kevin_cad version with these fixes applied:
%   1. rb uses single m2ft (radius is a length, not an area)
%   2. rb_m kept in metres so sspne subtraction is unit-consistent
%   3. xb starts away from 0 to avoid BODYRT x=0 singularity
%   4. Both write_datcom_input and runDatcom use the same resolved path
%   5. synths.zw / synths.zh use getval() for struct-or-double le_z fields
%   6. Best (highest CLa = BWHV) table selected per Mach from DATCOM output
%
% M=1.50 removed from Pass A — sits on DATCOM method table boundary and
% produces inconsistent results. Pass B covers that region cleanly.
%
% Pass A: [0.60, 0.75, 1.15, 1.30, 1.40]  subsonic + low supersonic
% Pass B: [1.50, 1.55, 1.65, 1.75, 1.85]  mid supersonic
% Pass C: [1.70, 1.80, 1.90, 1.95, 2.00]  upper supersonic

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

% ---- Shared geometry (computed once, reused in all passes) --------------
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

xcg_ft  = 34;                               % ft from nose — UPDATE to your CG
cbar_ft = m2ft(geom.wing.average_chord.v);
xw_ft   = m2ft(geom.wing.le_x.v);

% =========================================================================
function tbl = runDatcomPass(cfg, geom, model, examplesDir, ...
                              machVec, reVec, alphaVec, ...
                              xb, rb, xb_m, rb_m, bln_ft, bla_ft, ...
                              rb_at_wing_m, rb_at_ht_m, passName)
% Run a single DATCOM pass (max 5 Mach points) and return best-CLa table.
    nMach = numel(machVec);
    assert(nMach <= 5, 'Max 5 Mach points per DATCOM pass (RNNUB line limit)');
    assert(nMach == numel(reVec), 'machVec and reVec must be same length');

    % 2D section CLa (Prandtl-Glauert subsonic / Ackeret supersonic)
    cLa = zeros(1, nMach);
    for iM = 1:nMach
        M = machVec(iM);
        if M < 1.0
            cLa(iM) = (2*pi / sqrt(1 - M^2)) * (pi/180);
        else
            cLa(iM) = (4 / sqrt(M^2 - 1)) * (pi/180);
        end
    end
    clmaxWing = linspace(1.40, 0.45, nMach);
    clmaxHT   = linspace(1.10, 0.35, nMach);

    c = struct();
    c.caseid = 'GENERIC SUPERSONIC FIGHTER - BASELINE';
    c.fltcon.nmach  = nMach;
    c.fltcon.mach   = machVec;
    c.fltcon.nalpha = numel(alphaVec);
    c.fltcon.alschd = alphaVec;
    c.fltcon.rnnub  = reVec;

    c.optins.sref  = m2ft(m2ft(geom.ref_area.v));
    c.optins.cbarr = m2ft(geom.wing.average_chord.v);
    c.optins.blref = m2ft(geom.wing.span.v);

    c.synths.xcg    = 34;    % ft — UPDATE to match xcg_ft above
    c.synths.zcg    = m2ft(-0.003 * geom.fuselage.length.v);
    c.synths.xw     = m2ft(geom.wing.le_x.v);
    c.synths.zw     = m2ft(getval(geom.wing.sections(1).le_z));
    c.synths.aliw   = 0;
    c.synths.xh     = m2ft(geom.elevator.le_x.v);
    c.synths.zh     = m2ft(getval(geom.elevator.sections(1).le_z));
    c.synths.alih   = 0.0;
    c.synths.xv     = m2ft(geom.rudder.le_x.v);
    c.synths.vertup = true;

    c.body.nx    = 5;
    c.body.bnose = 2;  c.body.btail = 1;
    c.body.bln   = bln_ft;  c.body.bla = bla_ft;
    c.body.x = xb;  c.body.r = rb;
    c.body.s = pi * rb.^2;  c.body.p = 2 * pi * rb;

    c.wgplnf.chrdr  = m2ft(geom.wing.root_chord.v);
    c.wgplnf.chrdtp = m2ft(geom.wing.tip_chord.v);
    c.wgplnf.sspn   = m2ft(geom.wing.span.v / 2);
    c.wgplnf.sspne  = m2ft((geom.wing.span.v - rb_at_wing_m) / 2);
    c.wgplnf.savsi  = geom.wing.average_qrtr_chd_sweep.v;
    c.wgplnf.chstat = 0.25;
    c.wgplnf.swafp  = 0.0;  c.wgplnf.twista = 0.0;
    c.wgplnf.sspndd = 0.0;  c.wgplnf.dhdadi = 0.0;  c.wgplnf.dhdado = 0.0;
    c.wgplnf.type   = 1;
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
    c.vtschr.xovc   = 0.40;
    c.vtschr.clalpa = repmat(0.090, 1, nMach);
    c.vtschr.clmax  = repmat(0.80,  1, nMach);
    c.vtschr.leri   = 0.007;

    cfgPass  = struct(); cfgPass.dim = 'FT'; cfgPass.cases(1) = c;
    inpLocal = write_datcom_input(cfgPass, [passName '.inp']);

    % Line-length diagnostic — any overflow causes silent DATCOM abort
    inpLines = splitlines(string(fileread(inpLocal)));
    anyOverflow = false;
    for kL = 1:numel(inpLines)
        if strlength(inpLines(kL)) > 72
            fprintf('WARNING [%s] line %d too long (%d chars): %s\n', ...
                    passName, kL, strlength(inpLines(kL)), inpLines(kL));
            anyOverflow = true;
        end
    end
    if ~anyOverflow
        fprintf('[%s] inp OK — all lines within 72 chars\n', passName);
    end

    inpFile = fullfile(examplesDir, [passName '.inp']);
    copyfile(inpLocal, inpFile, 'f');
    out = runDatcom(inpFile, 'keepOut', true);
    fprintf('DATCOM %s: status=%d  raw tables=%d\n', passName, out.status, numel(out.tables));
    if isfile(inpLocal), delete(inpLocal); end

    % Select best (highest CLa) table per Mach = full BWHV configuration.
    % Index accumulation avoids dissimilar-struct assignment error.
    tbl = out.tables([]);
    if numel(out.tables) > 0
        mL      = [out.tables.Mach];
        uM      = unique(mL);
        bestIdx = zeros(1, numel(uM));
        for km = 1:numel(uM)
            idx     = find(mL == uM(km));
            CLaVals = zeros(1, numel(idx));
            for ki = 1:numel(idx)
                t = out.tables(idx(ki));
                if ~isempty(t.data) && ~all(isnan(t.data.CLA))
                    CLaVals(ki) = max(abs(t.data.CLA), [], 'omitnan');
                end
            end
            [~, best]   = max(CLaVals);
            bestIdx(km) = idx(best);
        end
        tbl = out.tables(bestIdx);
    end
end

% =========================================================================
% Three passes — each max 5 Mach points (72-char RNNUB limit).
% M=1.50 moved from Pass A to Pass B — avoids DATCOM method table boundary.
% Transonic M~0.82–1.12 excluded — DATCOM NDM for this geometry.

cfg = struct(); cfg.dim = 'FT';   % shell cfg (dim only; passes build their own)

machA = [0.60, 0.75, 1.15, 1.30, 1.40];
reA   = [2.0e6, 2.8e6, 4.5e6, 5.5e6, 6.0e6];
tblA  = runDatcomPass(cfg, geom, model, examplesDir, ...
                      machA, reA, alphaVec, ...
                      xb, rb, xb_m, rb_m, bln_ft, bla_ft, ...
                      rb_at_wing_m, rb_at_ht_m, 'datcom_A');

machB = [1.50, 1.55, 1.65, 1.75, 1.85];
reB   = [6.5e6, 6.8e6, 7.2e6, 7.7e6, 8.2e6];
tblB  = runDatcomPass(cfg, geom, model, examplesDir, ...
                      machB, reB, alphaVec, ...
                      xb, rb, xb_m, rb_m, bln_ft, bla_ft, ...
                      rb_at_wing_m, rb_at_ht_m, 'datcom_B');

machC = [1.70, 1.80, 1.90, 1.95, 2.00];
reC   = [8.0e6, 8.5e6, 9.0e6, 9.2e6, 9.5e6];
tblC  = runDatcomPass(cfg, geom, model, examplesDir, ...
                      machC, reC, alphaVec, ...
                      xb, rb, xb_m, rb_m, bln_ft, bla_ft, ...
                      rb_at_wing_m, rb_at_ht_m, 'datcom_C');

% Merge and dedup overlapping Mach points — keep highest CLa per point
rawTables = [tblA, tblB, tblC];
if numel(rawTables) > 0
    mL      = [rawTables.Mach];
    uM      = unique(mL);
    bestIdx = zeros(1, numel(uM));
    for km = 1:numel(uM)
        idx     = find(abs(mL - uM(km)) < 1e-6);
        CLaVals = zeros(1, numel(idx));
        for ki = 1:numel(idx)
            t = rawTables(idx(ki));
            if ~isempty(t.data) && ~all(isnan(t.data.CLA))
                CLaVals(ki) = max(abs(t.data.CLA), [], 'omitnan');
            end
        end
        [~, best]   = max(CLaVals);
        bestIdx(km) = idx(best);
    end
    outDATCOM.tables = rawTables(bestIdx);
else
    outDATCOM.tables = rawTables;
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

%% ---- Neutral point & static margin vs Mach ----------------------------
machPts = [allTables.Mach];
nPts    = numel(allTables);
CLa_pt  = NaN(1, nPts);
CMa_pt  = NaN(1, nPts);

for k = 1:nPts
    t = allTables(k);
    if isempty(t.data), continue; end
    [~, i0] = min(abs(t.data.Alpha));
    if ~isnan(t.data.CLA(i0)), CLa_pt(k) = t.data.CLA(i0); end
    if ~isnan(t.data.CMA(i0)), CMa_pt(k) = t.data.CMA(i0); end
end

Xnp_ft    = xcg_ft - (CMa_pt ./ CLa_pt) * cbar_ft;
SM_mach   = (Xnp_ft - xcg_ft) / cbar_ft;
validMask = ~isnan(Xnp_ft) & ~isnan(SM_mach) & ~isinf(SM_mach);
isVLMpts  = machPts < VLM_LIMIT;

figure('Name','Neutral Point & Static Margin vs Mach','Position',[50 50 1100 420]);
subplot(1,2,1); hold on; grid on; box on;
yline(xcg_ft,'k--','LineWidth',1.5,'DisplayName',sprintf('CG = %.1f ft',xcg_ft));
msk = validMask & isVLMpts;
if any(msk), plot(machPts(msk),Xnp_ft(msk),'b--^','LineWidth',2,'MarkerSize',8,'DisplayName','Xnp (VLM)'); end
msk = validMask & ~isVLMpts;
if any(msk), plot(machPts(msk),Xnp_ft(msk),'b-o','LineWidth',2,'MarkerSize',8,'DisplayName','Xnp (DATCOM)'); end
xline(VLM_LIMIT,'k:','LineWidth',1.2);
xlabel('Mach','Interpreter','none'); ylabel('Distance from nose (ft)','Interpreter','none');
title('Neutral Point vs Mach','Interpreter','none'); legend('Location','best','Interpreter','none');

subplot(1,2,2); hold on; grid on; box on;
yline(0,'k--','LineWidth',1.5,'DisplayName','Neutral (SM=0)');
yline(5,'g:','LineWidth',1.2,'DisplayName','SM = 5%');
msk = validMask & isVLMpts;
if any(msk), plot(machPts(msk),SM_mach(msk)*100,'r--^','LineWidth',2,'MarkerSize',8,'DisplayName','SM (VLM)'); end
msk = validMask & ~isVLMpts;
if any(msk), plot(machPts(msk),SM_mach(msk)*100,'r-o','LineWidth',2,'MarkerSize',8,'DisplayName','SM (DATCOM)'); end
xline(VLM_LIMIT,'k:','LineWidth',1.2);
xlabel('Mach','Interpreter','none'); ylabel('Static Margin (%MAC)','Interpreter','none');
title('Static Margin vs Mach','Interpreter','none'); legend('Location','best','Interpreter','none');
sgtitle('Mach Sweep Stability','Interpreter','none');

%% ---- Classical scissor plot --------------------------------------------
% =========================================================================
% SCISSOR PLOT PARAMETERS — UPDATE THESE
% =========================================================================
x_cg_full  = 0.617 * m2ft(geom.fuselage.length.v);  % CG ft from nose at MGTOW
x_cg_empty = 0.649 * m2ft(geom.fuselage.length.v);  % CG ft from nose at empty
x_ac_wb    = 31.7;                                    % ft — wing-body AC from nose
                                                       %       (UPDATE from DATCOM or w&b)
eta_H      = 0.86;   % HT efficiency factor
tau        = 0.70;   % elevator effectiveness (stabilator ~1.0, hinged ~0.5-0.7)
delta_e_max = 25;    % max elevator deflection (deg)
CM_ac_w    = -0.015; % wing zero-lift pitching moment coefficient (from WGSCHR CMO)
zEng_m     = 0.167;  % engine thrust line offset below CG (m), positive = below CG
CL_design  = 0.30;   % representative cruise CL for control sizing
T_design   = 0;      % representative thrust (N) — set 0 if thrust moment negligible
q_design   = 10000;  % representative dynamic pressure (Pa) for thrust moment
% =========================================================================

% ---- Geometry -----------------------------------------------------------
lambda_w  = geom.wing.tip_chord.v / geom.wing.root_chord.v;
AR_w      = geom.wing.AR.v;
LambdaLE  = deg2rad(geom.wing.average_sweep.v);       % wing LE sweep (rad)
Lambda_c4 = deg2rad(geom.wing.average_qrtr_chd_sweep.v); % quarter-chord sweep (rad)
b_w       = geom.wing.span.v;                          % wing span (m)

% HT moment arm (from CG to HT quarter-chord, ft)
xh_qc_ft  = m2ft(geom.elevator.le_x.v) + 0.25 * m2ft(geom.elevator.root_chord.v);
l_h       = xh_qc_ft - xcg_ft;                        % ft

% Vertical offset of HT from wing (ft) — used in downwash K_H
z_H_m     = getval(geom.elevator.sections(1).le_z) - getval(geom.wing.sections(1).le_z);
z_H       = m2ft(z_H_m);                               % ft

% Wing AC position (Kuchemann approximation)
xac_wing_frac = 0.25 + (tan(LambdaLE)/4) * (1 + 2*lambda_w) / ((1 + lambda_w) * AR_w);
x_ac_w    = m2ft(geom.wing.le_x.v) + xac_wing_frac * m2ft(geom.wing.root_chord.v); % ft

% HT area (trapezoidal, ft^2)
SH_ft2    = m2ft(m2ft((geom.elevator.root_chord.v + geom.elevator.tip_chord.v) / 2 ...
                       * geom.elevator.span.v));
SW_ft2    = m2ft(m2ft(geom.ref_area.v));

fprintf('\n=== Scissor Plot Geometry ===\n');
fprintf('  l_h = %.2f ft   SH = %.2f ft^2   SW = %.2f ft^2\n', l_h, SH_ft2, SW_ft2);
fprintf('  x_cg_full=%.2f ft   x_cg_empty=%.2f ft   x_ac_wb=%.2f ft\n', ...
        x_cg_full, x_cg_empty, x_ac_wb);

% ---- Lift curve slopes (per rad) ----------------------------------------
% Wing 3D CLalpha (Helmbold)
cla_2d    = 2*pi;
CLalpha_w = cla_2d / (1 + cla_2d / (pi * AR_w));  % /rad

% HT 3D CLalpha (Helmbold, same formula for HT planform)
AR_H      = (geom.elevator.span.v)^2 / (SH_ft2 / (3.28084^2));  % HT AR (m-based)
CLalpha_H = cla_2d / (1 + cla_2d / (pi * AR_H));  % /rad

% Wing-body CLalpha from DATCOM at reference Mach (use full-config value)
ref_mach  = 0.60;
ref_idx   = find(~isnan(CLa_pt) & abs(machPts - ref_mach) < 0.05, 1);
if isempty(ref_idx), [~, ref_idx] = min(abs(machPts - ref_mach)); end
CLalpha_wb_perdeg = CLa_pt(ref_idx);          % per degree from DATCOM
CLalpha_wb = CLalpha_wb_perdeg * (180/pi);    % convert to per radian

fprintf('  CLalpha_wb = %.4f /rad  (from DATCOM M=%.2f)\n', ...
        CLalpha_wb, machPts(ref_idx));

% ---- DATCOM downwash gradient -------------------------------------------
% Nelson / DATCOM method (Eq. 3.51-style)
K_A      = 1/AR_w - 1/(1 + AR_w^1.7);
K_lambda = (10 - 3*lambda_w) / 7;
K_H      = (1 - abs(z_H / m2ft(b_w))) / (2 * l_h / m2ft(b_w))^(1/3);
depsda   = 4.44 * (K_A * K_lambda * K_H * sqrt(cos(Lambda_c4)))^1.19;

% Clamp downwash gradient to physical range [0, 0.85].
% The DATCOM formula can exceed 1.0 for some geometries, which would
% flip the sign of (1-dε/dα) and invert the stability line slope.
depsda = max(0, min(depsda, 0.85));
fprintf('  dε/dα = %.4f (clamped)   K_A=%.4f  K_λ=%.4f  K_H=%.4f\n', ...
        depsda, K_A, K_lambda, K_H);

% ---- Pitching moment terms ----------------------------------------------
% Wing CMac (Raymer eq. with sweep correction)
CMac_w   = CM_ac_w * (AR_w + 2*cos(Lambda_c4)) / (AR_w + 4*cos(Lambda_c4));

% Engine pitching moment (thrust × moment arm, normalised)
% Positive zEng → engine below CG → nose-down from thrust
zEng_ft  = m2ft(zEng_m);
CME      = T_design * zEng_ft / (q_design * SW_ft2 * cbar_ft);

% Zero-lift HT CL (due to downwash offset at α=0)
eps0     = 0;   % assume downwash at α=0 is zero (symmetric airfoil, 0 wing twist)
CLH_0    = CLalpha_H * (-eps0);

% ---- CG normalised sweep ------------------------------------------------
xcg_ac_norm = linspace(-0.40, 0.40, 400);

% Stability limit: minimum SH/SW to maintain static margin ≥ SM_req
% SH/SW = (xcg_ac_norm + SM_req) / K_stab
% Positive slope — more aft CG (positive x) needs more tail for stability.
K_stab      = eta_H * (CLalpha_H / CLalpha_wb) * (1 - depsda) * (l_h / cbar_ft);
SHSW_stab   = (xcg_ac_norm + SM_req) ./ K_stab;

% Control limit: minimum SH/SW for pitch trim (trim at CL_design with delta_e_max)
% CLH*ηH*(SH/SW)*(lH/c) = CL*(Xcg-Xac)/c - CMac_w - CME
% CLH at max deflection: CLH_max = CLaH*(−ε0 − τ*δe_max)
CLH_max   = CLalpha_H * (-eps0 - tau * delta_e_max * pi/180);
K_ctrl    = CLH_max * eta_H * (l_h / cbar_ft);
SHSW_ctrl = (CL_design .* xcg_ac_norm - CMac_w - CME) ./ K_ctrl;

% Normalised CG limits
Xcg_full_norm  = (x_cg_full  - x_ac_wb) / cbar_ft;
Xcg_empty_norm = (x_cg_empty - x_ac_wb) / cbar_ft;

% ---- Design point: find SH/SW at each CG extreme -----------------------
% Stability is critical at AFT CG (empty weight)
% Control  is critical at FWD CG (MGTOW / full fuel)
x_fwd = min(Xcg_full_norm, Xcg_empty_norm);
x_aft = max(Xcg_full_norm, Xcg_empty_norm);

slope_s      = 1 / K_stab;                           % stability line slope
intercept_s  = SM_req / K_stab;                       % stability line y-intercept
slope_c      = CL_design / K_ctrl;                    % control line slope
intercept_c  = -(CMac_w + CME) / K_ctrl;              % control line intercept

SH_stab_aft  = x_aft  / K_stab + intercept_s;        % stability at aft CG
SH_ctrl_fwd  = slope_c * x_fwd + intercept_c;        % control at fwd CG

% Constrained design: must satisfy both
SH_SW_design = max(SH_stab_aft, SH_ctrl_fwd);
SH_SW_actual = SH_ft2 / SW_ft2;

fprintf('  SH/SW design = %.4f   SH/SW actual = %.4f\n', SH_SW_design, SH_SW_actual);

% Intersections of design line with each curve
x_stab_cross = (SH_SW_design - intercept_s) * K_stab;   % x where stab line = design SH/SW
x_ctrl_cross = (SH_SW_design - intercept_c) / slope_c;

% ---- Plot ---------------------------------------------------------------
figure('Name','Scissor Plot','Position',[50 50 700 620]);
hold on; grid on; box on;

plot(xcg_ac_norm, SHSW_stab, 'r-',  'LineWidth', 2.5, 'DisplayName', 'Stability Limit');
plot(xcg_ac_norm, SHSW_ctrl, 'g-',  'LineWidth', 2.5, 'DisplayName', 'Control Limit');

% Actual SH/SW reference line
yline(SH_SW_actual, 'b--', 'LineWidth', 1.5, ...
      'DisplayName', sprintf('S_H/S_W actual = %.3f', SH_SW_actual));

% Design SH/SW with extent between intersection points
x_plot = linspace(min(x_stab_cross,x_ctrl_cross), max(x_stab_cross,x_ctrl_cross), 100);
plot(x_plot, SH_SW_design*ones(size(x_plot)), 'b-', 'LineWidth', 2, ...
     'DisplayName', sprintf('S_H/S_W design = %.3f', SH_SW_design));
plot(x_stab_cross, SH_SW_design, 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 9, 'HandleVisibility', 'off');
plot(x_ctrl_cross, SH_SW_design, 'gs', 'MarkerFaceColor', 'g', 'MarkerSize', 9, 'HandleVisibility', 'off');

% CG limit verticals (thick grey, matching image style)
xl1 = xline(Xcg_full_norm,  'Color', [0.35 0.35 0.35], 'LineWidth', 2.5, 'HandleVisibility', 'off');
xl2 = xline(Xcg_empty_norm, 'Color', [0.35 0.35 0.35], 'LineWidth', 2.5, 'HandleVisibility', 'off');

% Rotated labels on CG lines
yl = ylim;
txt_y = yl(2) - 0.03*(yl(2)-yl(1));
text(Xcg_full_norm,  txt_y, 'XCG at MGTOW', ...
     'Rotation', 90, 'HorizontalAlignment', 'right', ...
     'FontSize', 9, 'Color', [0.35 0.35 0.35], 'FontWeight', 'bold');
text(Xcg_empty_norm, txt_y, 'XCG at empty weight', ...
     'Rotation', 90, 'HorizontalAlignment', 'right', ...
     'FontSize', 9, 'Color', [0.35 0.35 0.35], 'FontWeight', 'bold');

% Zero-line
xline(0, 'k:', 'LineWidth', 0.8, 'HandleVisibility', 'off');

xlim([-0.40, 0.40]);
ylim([-0.8, 0.8]);
xlabel('x_{cg} - x_{ac} normalized', 'Interpreter', 'tex', 'FontSize', 12);
ylabel('S_H/S_W',                     'Interpreter', 'tex', 'FontSize', 12);
title('Hellstinger Scissor Plot', 'FontSize', 13);
legend('Location', 'northwest', 'FontSize', 10);

% SH/SW label on design line
text(-0.38, SH_SW_design + 0.03, sprintf('S_H/S_W = %.3f', SH_SW_design), ...
     'FontSize', 11, 'Color', 'b', 'FontWeight', 'bold');

% ---- Print stability summary --------------------------------------------
fprintf('\n=== Stability Summary ===\n');
fprintf('  CG = %.2f ft from nose  (%.2f%% MAC from wing LE)\n', ...
        xcg_ft, (xcg_ft - xw_ft) / cbar_ft * 100);
fprintf('  %-6s  %-6s  %-10s  %-10s  %-12s  %-10s\n', ...
        'Mach','Src','CLa/deg','CMa/deg','Xnp (ft)','SM (%c)');
for k = 1:nPts
    if ~validMask(k), continue; end
    src = 'VLM'; if machPts(k) >= VLM_LIMIT, src = 'DAT'; end
    fprintf('  %.2f   %-3s  %10.5f  %10.5f  %12.3f  %10.2f\n', ...
            machPts(k), src, CLa_pt(k), CMa_pt(k), Xnp_ft(k), SM_mach(k)*100);
end


% =========================================================================
function v = getval(x)
%GETVAL  Return numeric value from plain double or .v struct field.
if isstruct(x), v = x.v; else, v = double(x); end
end

function s = ternary(cond, a, b)
if cond, s = a; else, s = b; end
end