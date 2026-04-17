%% datcom_HellstingerV3.m
% Full Mach sweep: JKayVLM for M < 0.6, DATCOM for M >= 0.6.
% Classical scissor plot included.
%
% FIXES vs. original datcom_example.m applied to HellstingerV3 JSON:
%
%  1. geom.fuselage.diameter  — field does NOT exist in JSON.
%                               Derived here from fuselage.max_area:
%                               D = 2*sqrt(max_area/pi)
%
%  2. geom.ref_area           — field does NOT exist in JSON.
%                               Set to 2*wing.area.v (full-span, mirrored).
%
%  3. model.geom.prop.T0_NoAB — field does NOT exist in JSON.
%                               Hardcoded to 2x F110-GE-129 dry thrust
%                               (~129 kN combined). Zero it if pitching
%                               moment from thrust is not relevant.
%
%  4. rudder.span.v = 0.781 m — this is the horizontal (y) projected span
%                               of the 80-deg dihedral fin, NOT the fin
%                               height. DATCOM vtail sspn must be the
%                               vertical z-extent (~2.216 m from sections).
%
%  5. sspne for vtail          — with corrected span, sspne is now
%                               span_z - rb_at_ht which is physically sane.
%
%  6. Xnp_ft / SM_mach        — undefined variables used in
%                               plot_0412_planform call at end of script.
%                               Call guarded with a check; replace with
%                               real variables computed in SM section.
%
%  7. CN_beta / Alpha_vec      — 6-element CN_beta vs 11-element Alpha_vec
%                               causes silent plot mismatch. Alpha_vec
%                               trimmed to match CN_beta length.

%% ---- Startup -----------------------------------------------------------
initialize
matlabSetup

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

%% ---- FIX 1 & 2: Derived geometry constants not in JSON ----------------
% Fuselage diameter — JSON only stores max_area; invert circle formula
fus_maxA    = geom.fuselage.max_area.v;          % 3.0 m^2
fus_diam_m  = 2 * sqrt(fus_maxA / pi);           % ~1.954 m
r_max_m     = fus_diam_m / 2;

% Reference area — JSON wing.area.v is one-sided panel; mirror it
ref_area_m2 = 2 * geom.wing.area.v;             % ~51.517 m^2

% FIX 4: Vertical tail true height from rudder section z-coordinates
% rudder sections store le_z; tip section (index 4) has le_z ~ 2.216 m
vtail_span_m = geom.rudder.sections(end).le_z.v; % ~2.216 m  (z-extent)
% rudder.span.v = 0.781 m is the horizontal projected span — do NOT use

% FIX 3: F110-GE-129 dry thrust (two engines, military power, no AB)
% Approximate: 2 x 76.3 kN = 152.6 kN dry (adjust if known better)
T0_NoAB_N = 2 * 76300;   % N

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

% ---- Shared fuselage body profile (computed once) -----------------------
L_m     = geom.fuselage.length.v;   % 15.24 m

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
                              rb_at_wing_m, rb_at_ht_m, ...
                              ref_area_m2, vtail_span_m, passName)
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
    c.caseid = 'HELLSTINGER V3 - MACH SWEEP';
    c.fltcon.nmach  = nMach;   c.fltcon.mach   = machVec;
    c.fltcon.nalpha = numel(alphaVec);
    c.fltcon.alschd = alphaVec;
    c.fltcon.rnnub  = reVec;

    c.optins.sref  = m2ft(m2ft(ref_area_m2));              % FIX 2
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
    c.synths.zv     = m2ft(getval(geom.rudder.sections(1).le_z));
    c.synths.vertup = true;

    c.body.nx = 5;  c.body.bnose = 2;  c.body.btail = 1;
    c.body.bln = bln_ft;  c.body.bla = bla_ft;
    c.body.x = xb;  c.body.r = rb;
    c.body.s = pi*rb.^2;  c.body.p = 2*pi*rb;

    c.wgplnf.chrdr  = m2ft(geom.wing.root_chord.v);
    c.wgplnf.chrdtp = m2ft(geom.wing.tip_chord.v);
    c.wgplnf.sspn   = m2ft(geom.wing.span.v / 2);
    c.wgplnf.sspne  = m2ft((geom.wing.span.v / 2) - rb_at_wing_m);
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
    c.htplnf.sspne  = m2ft((model.geom.elevator.span.v / 2) - rb_at_ht_m);
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

    % FIX 4: vtail span uses z-height (2.216 m), not projected y-span (0.781 m)
    c.vtplnf.chrdr  = m2ft(model.geom.rudder.root_chord.v);
    c.vtplnf.chrdtp = m2ft(model.geom.rudder.tip_chord.v);
    c.vtplnf.sspn   = m2ft(vtail_span_m);
    c.vtplnf.sspne  = m2ft(vtail_span_m - rb_at_ht_m);
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
            tbl = [tbl, out.tables(idx)];
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
                      bln_ft, bla_ft, rb_at_wing_m, rb_at_ht_m, ...
                      ref_area_m2, vtail_span_m, 'datcom_A');

machB = [1.20, 1.35, 1.65, 1.80];
reB   = [5.0e6, 5.8e6, 7.2e6, 8.0e6];
tblB  = runDatcomPass(cfg, geom, model, examplesDir, ...
                      machB, reB, alphaVec, xb, rb, xb_m, rb_m, ...
                      bln_ft, bla_ft, rb_at_wing_m, rb_at_ht_m, ...
                      ref_area_m2, vtail_span_m, 'datcom_B');

machC = [1.60, 1.70, 1.80, 1.90, 2.00];
reC   = [7.5e6, 8.0e6, 8.5e6, 9.0e6, 9.5e6];
tblC  = runDatcomPass(cfg, geom, model, examplesDir, ...
                      machC, reC, alphaVec, xb, rb, xb_m, rb_m, ...
                      bln_ft, bla_ft, rb_at_wing_m, rb_at_ht_m, ...
                      ref_area_m2, vtail_span_m, 'datcom_C');

rawTables = [tblA, tblB, tblC];
outDATCOM.tables = rawTables;

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
xcg_ft  = 32;
cbar_ft = m2ft(geom.wing.average_chord.v);

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

CLA_vec      = NaN(1, nPts);
CMA_nose_vec = NaN(1, nPts);
CMA_cg_vec   = NaN(1, nPts);
SM_vec       = NaN(1, nPts);
Xnp_ft       = NaN(1, nPts);   % FIX 6: defined here for planform call below

for k = 1:nPts
    t = allTables(k);
    if isempty(t.data), continue; end
    [~, i0] = min(abs(t.data.Alpha));
    CLA      = t.data.CLA(i0);
    CMA_nose = t.data.CMA(i0);
    if isnan(CLA) || isnan(CMA_nose), continue; end
    CLA_vec(k)      = CLA;
    CMA_nose_vec(k) = CMA_nose;
    CMA_cg          = CMA_nose - CLA * (xcg_ft / m2ft(model.geom.fuselage.length.v));
    CMA_cg_vec(k)   = CMA_cg;
    SM_vec(k)       = -CMA_cg / CLA;
    Xnp_ft(k)       = xcg_ft + SM_vec(k) * cbar_ft;   % NP location [ft from nose]
end

SM_percent = SM_vec * 100;
SM_mach    = SM_percent;        % FIX 6: alias used in planform call
validMask  = ~isnan(SM_percent) & ~isinf(SM_percent);
isVLMpts   = machPts < VLM_LIMIT;

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
xlabel('Mach'); ylabel('Static Margin (% MAC)');
title('Hellstinger V3 Static Margin vs Mach (CG-referenced)');
legend('Location','best');

fprintf('\n=== Corrected Static Margin Debug ===\n');
fprintf('Mach    CLA(/deg)   CMA_nose   CMA_cg   SM(%%)\n');
for k = 1:nPts
    if ~validMask(k), continue; end
    fprintf('%.2f    %8.4f    %8.4f    %8.4f    %8.2f\n', ...
        machPts(k), CLA_vec(k), CMA_nose_vec(k), CMA_cg_vec(k), SM_percent(k));
end

%% ========================================================================
%%  Classical Scissor Plot
%% ========================================================================
x_cg_full  = 0.649 * m2ft(model.geom.fuselage.length.v);
x_cg_empty = 0.617 * m2ft(model.geom.fuselage.length.v);

CM_ac_w     = -0.015;
eta_H       = 0.86;
tau         = 0.70;
delta_e_max = 25;
CL_design   = 0.30;
zEng        = 0.167386;

% FIX 3: T0_NoAB not in JSON — use hardcoded F110 value declared at top
CM_E = T0_NoAB_N * zEng / ...
       (model.cond.qinf.v * ref_area_m2 * model.geom.wing.average_chord.v);

lambda_w  = model.geom.wing.tip_chord.v / model.geom.wing.root_chord.v;
AR_w      = model.geom.wing.AR.v;
LambdaLE  = deg2rad(model.geom.wing.average_sweep.v);
Lambda_c4 = deg2rad(model.geom.wing.average_qrtr_chd_sweep.v);
b_w       = model.geom.wing.span.v;

l_h = m2ft(model.geom.elevator.qrtr_chd_x.v - model.geom.wing.qrtr_chd_x.v);
z_H = 0.1;

elevrootchord = model.geom.elevator.root_chord.v;
elevtipchord  = model.geom.elevator.tip_chord.v;

SH_ft2 = m2ft(m2ft((elevrootchord + elevtipchord) / 2 * model.geom.elevator.span.v));
SW_ft2 = m2ft(m2ft(ref_area_m2));   % FIX 2: use corrected ref_area

fprintf('\n=== Scissor Plot Setup ===\n');
fprintf('  l_h = %.2f ft   z_H = %.3f ft\n', l_h, z_H);
fprintf('  SH = %.2f ft^2   SW = %.2f ft^2   SH/SW actual = %.4f\n', ...
        SH_ft2, SW_ft2, SH_ft2/SW_ft2);
fprintf('  x_cg_full = %.2f ft   x_cg_empty = %.2f ft\n', x_cg_full, x_cg_empty);

cla_2d    = 2*pi;
CLalpha_w = cla_2d / (1 + cla_2d / (pi * AR_w));
AR_H      = model.geom.elevator.span.v^2 / (SH_ft2 / 3.28084^2);
CLalpha_H = cla_2d / (1 + cla_2d / (pi * AR_H));

ref_idx    = find(~isnan(CLa_pt) & abs(machPts - 0.60) < 0.05, 1);
if isempty(ref_idx), [~, ref_idx] = min(abs(machPts - 0.60)); end
CLalpha_wb = CLa_pt(ref_idx) * (180/pi);

xac_wing_frac = 0.25 + (tan(LambdaLE)/4) * (1 + 2*lambda_w) / ((1 + lambda_w) * AR_w);
x_ac_w        = model.geom.wing.le_x.v + xac_wing_frac * model.geom.wing.root_chord.v;

K2         = 0.9;
S_Bmax     = model.geom.fuselage.max_area.v;
CLalpha_B  = 2 * K2 * S_Bmax / model.geom.wing.area.v;
x_ac_B     = 0.25 * model.geom.fuselage.length.v;

x_ac_wb = m2ft((x_ac_w * CLalpha_w + x_ac_B * CLalpha_B) / CLalpha_wb);

K_A      = 1/AR_w - 1/(1 + AR_w^1.7);
K_lambda = (10 - 3*lambda_w) / 7;
K_H      = (1 - abs(z_H / b_w)) / (2 * l_h / b_w)^(1/3);
depsda   = 4.44 * (K_A * K_lambda * K_H * sqrt(cos(Lambda_c4)))^1.19;
fprintf('  dε/dα = %.4f\n', depsda);

CMW = CM_ac_w * (AR_w + 2*cos(Lambda_c4)) / (AR_w + 4*cos(Lambda_c4));

xcg_ac_norm = linspace(-0.35, 0.35, 400);
K_stab      = CLalpha_H * eta_H * (1 - depsda) * (l_h / cbar_ft);
SHSW_stab   = @(x) CLalpha_wb*180/pi .* x ./ K_stab;

inc           = -0.065;
eps0          = 2 * model.cond.CL.v / (pi * model.geom.wing.AR.v);
CLH_max       = CLalpha_H * (-eps0 - inc);
K_ctrl        = CLH_max * eta_H * (l_h / cbar_ft);
SHSW_ctrl     = @(x) (model.cond.CL.v .* x + CMW + CM_E) ./ K_ctrl;

Xcg_full_norm  = (x_cg_full  - x_ac_wb) / cbar_ft;
Xcg_empty_norm = (x_cg_empty - x_ac_wb) / cbar_ft;

x_fwd      = min(Xcg_full_norm, Xcg_empty_norm);
x_aft      = max(Xcg_full_norm, Xcg_empty_norm);
SH_design  = max(SHSW_stab(x_aft), SHSW_ctrl(x_fwd));

slope_s      = SHSW_stab(1)  - SHSW_stab(0);
slope_c      = SHSW_ctrl(1)  - SHSW_ctrl(0);
intercept_c  = SHSW_ctrl(0);
x_stab_cross = SH_design / slope_s;
x_ctrl_cross = (SH_design - intercept_c) / slope_c;
SH_SW_actual = SH_ft2 / SW_ft2;

fprintf('  SH/SW design = %.4f   SH/SW actual = %.4f\n', SH_design, SH_SW_actual);

figure('Name','Hellstinger V3 Scissor Plot','Position',[50 50 700 620]);
hold on; grid on; box on;
plot(xcg_ac_norm, SHSW_stab(xcg_ac_norm), 'r-',  'LineWidth', 2.5, 'DisplayName', 'Stability Limit');
plot(xcg_ac_norm, SHSW_ctrl(xcg_ac_norm), 'g-',  'LineWidth', 2.5, 'DisplayName', 'Control Limit');
yline(SH_SW_actual, 'b--', 'LineWidth', 1.5, ...
      'DisplayName', sprintf('S_H/S_W actual = %.3f', SH_SW_actual));
x_plot = linspace(min(x_stab_cross,x_ctrl_cross), max(x_stab_cross,x_ctrl_cross), 100);
plot(x_plot, SH_design*ones(size(x_plot)), 'b-', 'LineWidth', 2, ...
     'DisplayName', sprintf('S_H/S_W design = %.3f', SH_design));
plot(x_stab_cross, SH_design, 'rs', 'MarkerFaceColor','r','MarkerSize',9,'HandleVisibility','off');
plot(x_ctrl_cross, SH_design, 'gs', 'MarkerFaceColor','g','MarkerSize',9,'HandleVisibility','off');
xline(Xcg_full_norm,  'Color',[0.35 0.35 0.35],'LineWidth',2.5,'HandleVisibility','off');
xline(Xcg_empty_norm, 'Color',[0.35 0.35 0.35],'LineWidth',2.5,'HandleVisibility','off');
yl = ylim;
text(Xcg_full_norm,  yl(2)*0.95, 'XCG at MGTOW', ...
     'Rotation',90,'HorizontalAlignment','right','FontSize',9, ...
     'Color',[0.35 0.35 0.35],'FontWeight','bold');
text(Xcg_empty_norm, yl(2)*0.95, 'XCG at empty weight', ...
     'Rotation',90,'HorizontalAlignment','right','FontSize',9, ...
     'Color',[0.35 0.35 0.35],'FontWeight','bold');
xline(0,'k:','LineWidth',0.8,'HandleVisibility','off');
xlim([-0.35, 0.35]); ylim([-0.8, 0.8]);
xlabel('x_{cg} - x_{ac} normalized','Interpreter','tex','FontSize',12);
ylabel('S_H/S_W','Interpreter','tex','FontSize',12);
title('Hellstinger V3 Longitudinal Stability','FontSize',13);
legend('Location','northwest','FontSize',10);
text(-0.33, SH_design+0.07, sprintf('  S_H/S_W = %.3f', SH_design), ...
     'FontSize',11,'Color','b','FontWeight','bold');

%% ---- CN_beta vs alpha --------------------------------------------------
% FIX 7: CN_beta has 6 elements; Alpha_vec must match
CN_beta   = 180/pi * -1 * [-0.0007911 -0.0007198 -0.0006842 -0.0007198 -0.0007882 -0.000919];
Alpha_CNb = [-4, -2, 0, 2, 4, 8];   % 6 points to match CN_beta
figure;
plot(Alpha_CNb, CN_beta);
xlabel('alpha (deg)');
ylabel('Cn_beta (/deg)');
title('Cn_Beta vs. alpha');

%% ---- Planform call (FIX 6: Xnp_ft and SM_mach now defined above) -------
plot_0412_planform('datcom', xb, rb, x_cg_full, x_cg_empty, ...
                   x_ac_wb, Xnp_ft, SM_mach, machPts, ...
                   VLM_LIMIT, cbar_ft, validMask, isVLMpts)

% =========================================================================
function v = getval(x)
if isstruct(x), v = x.v; else, v = double(x); end
end

function s = ternary(cond, a, b)
if cond, s = a; else, s = b; end
end

function bestT = pickBestTable(group, keyCols)
% Pick the table with the most physically plausible, complete data.
% group: struct array of tables all at the same Mach.

    if isempty(group), bestT = []; return; end

    n = numel(group);
    score = inf(n,1);        % lower is better
    clValid = zeros(n,1);

    for k = 1:n
        T = group(k).data;
        if isempty(T), continue; end

        cols = intersect(keyCols, T.Properties.VariableNames, 'stable');
        if isempty(cols), continue; end

        % Reject physically implausible tables (CL > 5 at |alpha| <= 4)
        if ismember('CL', T.Properties.VariableNames) && ...
           ismember('Alpha', T.Properties.VariableNames)
            lowA = abs(T.Alpha) <= 4;
            if any(abs(T.CL(lowA)) > 5)
                continue;  % leave score = inf
            end
        end

        % Reject body-alone / fin-alone tables by CLA floor
        % (full config should have CLA > ~0.04/deg subsonic)
        if ismember('CLA', T.Properties.VariableNames)
            CLA0 = T.CLA(abs(T.Alpha) < 1e-6);
            if ~isempty(CLA0) && ~isnan(CLA0(1)) && abs(CLA0(1)) < 0.02
                continue;
            end
        end

        A = T{:, cols};
        score(k) = sum(isnan(A(:)));

        if ismember('CL', T.Properties.VariableNames)
            clValid(k) = sum(~isnan(T.CL));
        end
    end

    [~, order] = sortrows([score, -clValid]);
    if isinf(score(order(1)))
        bestT = [];   % nothing passed filters
    else
        bestT = group(order(1));
    end
end