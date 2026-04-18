clear all
close all
%% datcom_HellstingerV3.m
% Full Mach sweep: JKayVLM for M < 0.6, DATCOM for M >= 0.6.
% High-alpha maneuver condition evaluated separately via VLM.
%
% ROOT CAUSE OF 8-DEG CUTOFF (diagnosed via Block 4/5):
%   WGSCHR/HTSCHR lines combine CLALPA(...) + CLMAX(...) + CMO= on one line.
%   With 6 Mach points that line exceeds 72 chars → DATCOM truncates CLMAX
%   array, reads zeros/garbage, and immediately flags stall at low alpha.
%   FIX: max 3 Mach points per pass — keeps combined CLALPA+CLMAX line ≤65 chars.
%
% TRANSONIC DEAD ZONE: DATCOM fails M=0.75–1.40 (known limitation).
%   Removed those Mach values from all passes.
%
% TABLE SELECTION: fixed to pick max-CLa table per Mach (not first table).
%
% SM FORMULA: VLM normalises CM by fuselage length; DATCOM by cbar.
%   Different reference lengths applied per source.

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

displayAircraftGeom(geom)

%% ---- Alpha schedules ---------------------------------------------------
alphaVec_datcom = [-4, -2, 0, 2, 4, 6, 8, 10, 12, 16, 20];
alphaVec_vlm    = [-4, -2, 0, 2, 4, 8, 12, 16, 20, 25, 30, 35, 40, 50, 60, 70, 80];

%% ========================================================================
%%  Part 1 — JKayVLM subsonic sweep  (M < 0.6)
%% ========================================================================
VLM_LIMIT = 0.60;

machVLM = [0.20, 0.30, 0.40, 0.50];
reVLM   = [0.75e6, 0.9e6, 1.3e6, 1.6e6];

vlmCfg.machVec  = machVLM;
vlmCfg.alphaVec = alphaVec_vlm;
vlmCfg.xcg      = 32 * 0.3048;
vlmCfg.zcg      = -0.003 * geom.fuselage.length.v;
vlmCfg.Re       = reVLM;
vlmCfg.icase    = 3;

outVLM = runVLM(geom, vlmCfg, 'cdCorr', true, 'keepFiles', true);

fprintf('\n=== JKayVLM subsonic sweep (M < %.2f) ===\n', VLM_LIMIT);
for k = 1:numel(outVLM.tables)
    t = outVLM.tables(k);
    fprintf('\n  [%d] M=%.2f | %s\n', k, t.Mach, t.caseTitle);
    if ~isempty(t.data) && ~all(isnan(t.data.CL)), disp(t.data); end
end

%% ========================================================================
%%  Part 2 — JKayVLM high-alpha maneuver conditions
%% ========================================================================
L_ref_m = geom.fuselage.length.v;
Re_HA_A = 1.225 * (0.30*340.3) * L_ref_m / 1.789e-5;
Re_HA_B = 1.225 * (0.60*340.3) * L_ref_m / 1.789e-5;
Re_HA_C = 0.771 * (1.20*327.5) * L_ref_m / 1.742e-5;

vlmHA.machVec  = [0.30, 0.60, 1.20];
vlmHA.alphaVec = alphaVec_vlm;
vlmHA.xcg      = 32 * 0.3048;
vlmHA.zcg      = -0.003 * geom.fuselage.length.v;
vlmHA.Re       = [Re_HA_A, Re_HA_B, Re_HA_C];
vlmHA.icase    = 3;

outVLM_HA = runVLM(geom, vlmHA, 'cdCorr', true, 'keepFiles', true);

fprintf('\n=== JKayVLM high-alpha maneuver conditions ===\n');
for k = 1:numel(outVLM_HA.tables)
    t = outVLM_HA.tables(k);
    fprintf('\n  [%d] M=%.2f | %s\n', k, t.Mach, t.caseTitle);
    if ~isempty(t.data) && ~all(isnan(t.data.CL)), disp(t.data); end
end

%% ========================================================================
%%  Part 3 — DATCOM  (M >= 0.6)
%%
%%  CRITICAL: MAX 3 MACH PER PASS
%%  With >3 Mach, the WGSCHR line combining CLALPA(N) + CLMAX(N) + CMO=
%%  exceeds 72 chars and DATCOM truncates CLMAX → early stall at 8 deg.
%%  3 Mach = ~65 chars on that line. 4+ Mach = 73+ chars = corrupt input.
%%
%%  TRANSONIC DEAD ZONE: Do not use M=0.75–1.40 — DATCOM fails those.
%% ========================================================================
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

    assert(numel(machVec) <= 3, ...
        'runDatcomPass: max 3 Mach per pass — see CLALPA+CLMAX line limit comment');

    nMach = numel(machVec);

    % Section lift curve slopes (per deg)
    cLa = zeros(1, nMach);
    for iM = 1:nMach
        M = machVec(iM);
        if M < 1.0
            cLa(iM) = round((2*pi / sqrt(1 - M^2)) * (pi/180), 3);
        else
            cLa(iM) = round((4 / sqrt(M^2 - 1)) * (pi/180), 3);
        end
    end

    % clmaxWing = 3.0 everywhere — high enough that CLmax/CLalpha never
    % triggers early stall (DATCOM's physical model handles actual stall)
    clmaxWing = repmat(3.0, 1, nMach);
    clmaxHT   = repmat(2.5, 1, nMach);

    % FIX: round tc values to 3 decimal places to keep VTSCHR line <= 72 chars
    wing_tc  = round(geom.wing.average_tc.v, 3);
    elev_tc  = round(model.geom.elevator.average_tc.v, 3);
    rudd_tc  = round(model.geom.rudder.average_tc.v, 3);

    c = struct();
    c.caseid = 'HELLSTINGER V3';   % short caseid — long string pushes line 3 over 72
    c.fltcon.nmach  = nMach;
    c.fltcon.mach   = machVec;
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
    c.synths.zv     = m2ft(getval(geom.rudder.sections(1).le_z));
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
    c.wgschr.tovc   = wing_tc;
    c.wgschr.tovco  = wing_tc;
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
    c.htschr.tovc   = elev_tc;
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
    c.vtschr.tovc   = rudd_tc;     % rounded to 3dp — fixes VTSCHR line at 73 chars
    c.vtschr.tovco  = rudd_tc;
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

    % ================================================================
    % DIAGNOSTIC — full line-length audit + stall-alpha check
    % ================================================================
    inpLines = splitlines(string(fileread(inpLocal)));
    anyLong  = false;
    for kL = 1:numel(inpLines)
        if strlength(inpLines(kL)) > 72
            if ~anyLong
                fprintf('  --- Lines >72 chars in %s ---\n', passName);
                anyLong = true;
            end
            fprintf('  WARNING line %3d (%d chars): %s\n', ...
                kL, strlength(inpLines(kL)), inpLines(kL));
        end
    end
    if ~anyLong
        fprintf('  [OK] All lines <=72 chars in %s\n', passName);
    end

    fprintf('  --- Stall-alpha check (need > 20 deg) ---\n');
    for iM = 1:nMach
        a_stall = clmaxWing(iM) / cLa(iM);
        ok = 'OK'; if a_stall < 20, ok = '** LOW'; end
        fprintf('  M=%.2f  CLmax=%.1f  CLalpa=%.4f  alpha_stall=%.1f  %s\n', ...
            machVec(iM), clmaxWing(iM), cLa(iM), a_stall, ok);
    end

    inpFile = fullfile(examplesDir, [passName '.inp']);
    copyfile(inpLocal, inpFile, 'f');
    out = runDatcom(inpFile, 'keepOut', true);
    fprintf('  DATCOM %s: status=%d  raw tables=%d\n', passName, out.status, numel(out.tables));

    % ================================================================
    % DIAGNOSTIC — alpha coverage using max-CLa table per Mach
    % ================================================================
    fprintf('  --- Alpha coverage (max-CLa table per Mach) ---\n');
    if numel(out.tables) > 0
        mL  = [out.tables.Mach];
        uMd = unique(mL);
        for km = 1:numel(uMd)
            bestCLa = -Inf; bestAlpha = -99; bestCL = NaN; bestN = 0;
            for ki = find(mL == uMd(km))
                tt = out.tables(ki);
                if isempty(tt.data), continue; end
                [~,i0] = min(abs(tt.data.Alpha));
                if ~isnan(tt.data.CLA(i0)) && tt.data.CLA(i0) > bestCLa
                    validR    = ~isnan(tt.data.CL);
                    bestCLa   = tt.data.CLA(i0);
                    bestAlpha = max(tt.data.Alpha(validR));
                    bestCL    = max(tt.data.CL(validR));
                    bestN     = sum(validR);
                end
            end
            flag = ''; if bestAlpha < 18, flag = ' << STOPPED EARLY'; end
            fprintf('  M=%.2f  maxAlpha=%.0f  maxCL=%.4f  CLa=%.5f  nRows=%d%s\n', ...
                uMd(km), bestAlpha, bestCL, bestCLa, bestN, flag);
        end
    end

    tbl = out.tables([]);
    if numel(out.tables) > 0
        mL  = [out.tables.Mach];
        uMl = unique(mL);           % assign first — MATLAB can't index unique() directly
        for km = 1:numel(uMl)
            idx = find(mL == uMl(km));
            tbl = [tbl, out.tables(idx)];
        end
    end
    if isfile(inpLocal), delete(inpLocal); end
end

% =========================================================================
%  Pass definitions — MAX 3 MACH PER PASS
%  Avoid transonic dead zone: M = 0.75–1.40 excluded
% =========================================================================
cfg = struct(); cfg.dim = 'FT';

fprintf('\n======= DATCOM PASS A (subsonic) =======\n');
machA = [0.30, 0.60];           % 2 subsonic points
reA   = [2e6, 5e6];
tblA  = runDatcomPass(cfg, geom, model, examplesDir, ...
                      machA, reA, alphaVec_datcom, xb, rb, xb_m, rb_m, ...
                      bln_ft, bla_ft, rb_at_wing_m, rb_at_ht_m, 'datcom_A');

fprintf('\n======= DATCOM PASS B (low supersonic) =======\n');
machB = [1.45, 1.60, 1.75];     % 3 supersonic points
reB   = [7e6, 8e6, 8e6];
tblB  = runDatcomPass(cfg, geom, model, examplesDir, ...
                      machB, reB, alphaVec_datcom, xb, rb, xb_m, rb_m, ...
                      bln_ft, bla_ft, rb_at_wing_m, rb_at_ht_m, 'datcom_B');

fprintf('\n======= DATCOM PASS C (mid supersonic) =======\n');
machC = [1.55, 1.70, 1.85];     % 3 supersonic points
reC   = [7e6, 8e6, 9e6];
tblC  = runDatcomPass(cfg, geom, model, examplesDir, ...
                      machC, reC, alphaVec_datcom, xb, rb, xb_m, rb_m, ...
                      bln_ft, bla_ft, rb_at_wing_m, rb_at_ht_m, 'datcom_C');

fprintf('\n======= DATCOM PASS D (high supersonic) =======\n');
machD = [1.80, 1.95, 2.10];
reD   = [8e6, 9e6, 9e6];
tblD  = runDatcomPass(cfg, geom, model, examplesDir, ...
                      machD, reD, alphaVec_datcom, xb, rb, xb_m, rb_m, ...
                      bln_ft, bla_ft, rb_at_wing_m, rb_at_ht_m, 'datcom_D');

rawTables = [tblA, tblB, tblC, tblD];
outDATCOM.tables = rawTables;

%% ========================================================================
%%  Merge — FIX: select max-CLa table per Mach (not first table)
%%  DATCOM outputs ~10 component tables per Mach; the first is body-alone
%%  with CLA~0.001, which is wrong for SM.  Max CLa gives the table most
%%  representative of the complete aircraft configuration.
%% ========================================================================
allTables = [outVLM.tables, outDATCOM.tables];
[~, sortIdx] = sort([allTables.Mach]);
allTables = allTables(sortIdx);

uMachs     = unique([allTables.Mach]);
bestTables = [];
allMachs   = [allTables.Mach];          % cache once — struct logical indexing unreliable
for km = 1:numel(uMachs)
    candidates = allTables(allMachs == uMachs(km));
    bestCLa = -Inf;
    bestT   = candidates(1);
    for kc = 1:numel(candidates)
        t = candidates(kc);
        if isempty(t.data), continue; end
        validRows = ~isnan(t.data.CL);
        if ~any(validRows), continue; end
        [~,i0] = min(abs(t.data.Alpha));
        if ~isnan(t.data.CLA(i0)) && t.data.CLA(i0) > bestCLa
            bestCLa = t.data.CLA(i0);
            bestT   = t;
        end
    end
    bestTables = [bestTables, bestT];
end
allTables = bestTables;

fprintf('\n=== MERGED sweep (%d Mach points) ===\n', numel(allTables));
for k = 1:numel(allTables)
    t   = allTables(k);
    src = 'VLM   '; if t.Mach >= VLM_LIMIT, src = 'DATCOM'; end
    fprintf('  [%d] M=%.2f  %-6s  data=%d\n', k, t.Mach, src, ...
        ~isempty(t.data) && ~all(isnan(t.data.CL)));
end

% ---- CL/CD/CM vs alpha plots --------------------------------------------
figure('Name','Full Mach Sweep VLM + DATCOM','Position',[50 50 1200 400]);
nT   = numel(allTables);
cmap = parula(nT);
for sp = 1:3
    subplot(1,3,sp); hold on; grid on;
    xlabel('Alpha (deg)','Interpreter','none');
    switch sp
        case 1; ylabel('CL','Interpreter','none');  title('Lift','Interpreter','none');
        case 2; ylabel('CD','Interpreter','none');  title('Drag','Interpreter','none');
        case 3; ylabel('CM','Interpreter','none');  title('Pitch Moment','Interpreter','none');
    end
end
for k = 1:nT
    t = allTables(k);
    if isempty(t.data) || all(isnan(t.data.CL)), continue; end
    isVLM  = t.Mach < VLM_LIMIT;
    lstyle = '-o'; if isVLM, lstyle = '--^'; end
    col = cmap(k,:);
    lbl = sprintf('M=%.2f (%s)', t.Mach, ternary(isVLM,'VLM','DAT'));
    subplot(1,3,1); plot(t.data.Alpha,t.data.CL,lstyle,'Color',col,'LineWidth',1.5,'DisplayName',lbl);
    subplot(1,3,2); plot(t.data.Alpha,t.data.CD,lstyle,'Color',col,'LineWidth',1.5,'DisplayName',lbl);
    subplot(1,3,3); plot(t.data.Alpha,t.data.CM,lstyle,'Color',col,'LineWidth',1.5,'DisplayName',lbl);
end
for sp = 1:3; subplot(1,3,sp); legend('Location','best','Interpreter','none','FontSize',7); end
sgtitle('VLM (dashed) + DATCOM (solid)','Interpreter','none');

% ---- CLa continuity -----------------------------------------------------
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
title('CLa continuity at VLM/DATCOM join','Interpreter','none');
legend('Interpreter','none');

%% ========================================================================
%%  Static margin vs Mach
%%
%%  NOTE on CM normalisation:
%%  VLM (JKayVLM) normalises CM by fuselage length → shift formula uses Lfus.
%%  DATCOM normalises CM by wing MAC (cbar) → shift formula uses cbar.
%%  Different denominators applied per source.
%% ========================================================================
xcg_ft  = 32;
cbar_ft = m2ft(geom.wing.average_chord.v);
Lfus_ft = m2ft(geom.fuselage.length.v);

nPts    = numel(allTables);
machPts = [allTables.Mach];
CLa_pt  = NaN(1, nPts);

CLA_vec      = NaN(1, nPts);
CMA_nose_vec = NaN(1, nPts);
CMA_cg_vec   = NaN(1, nPts);
SM_vec       = NaN(1, nPts);
Xnp_ft       = NaN(1, nPts);

for k = 1:nPts
    t = allTables(k);
    if isempty(t.data), continue; end
    [~, i0] = min(abs(t.data.Alpha));
    CLA      = t.data.CLA(i0);
    CMA_nose = t.data.CMA(i0);
    if isnan(CLA) || isnan(CMA_nose) || CLA < 0.005, continue; end  % skip spurious tables

    CLA_vec(k)      = CLA;
    CMA_nose_vec(k) = CMA_nose;
    CLa_pt(k)       = CLA;

    % Apply correct reference length per solver
    if machPts(k) < VLM_LIMIT
        % VLM: CM normalised by Lfus
        CMA_cg = CMA_nose - CLA * (xcg_ft / Lfus_ft);
        SM_vec(k) = -CMA_cg / CLA * (Lfus_ft / cbar_ft);  % convert to MAC fractions
    else
        % DATCOM: CM normalised by cbar
        CMA_cg = CMA_nose - CLA * (xcg_ft / cbar_ft);
        SM_vec(k) = -CMA_cg / CLA;
    end
    CMA_cg_vec(k) = CMA_cg;
    Xnp_ft(k)     = xcg_ft + SM_vec(k) * cbar_ft;
end

SM_percent = SM_vec * 100;
SM_mach    = SM_percent;
validMask  = ~isnan(SM_percent) & ~isinf(SM_percent);
isVLMpts   = machPts < VLM_LIMIT;

figure('Name','Static Margin vs Mach','Position',[200 200 700 500]);
hold on; grid on; box on;
yline(0,'k--','LineWidth',1.5,'DisplayName','Neutral Stability');
yline(5,'g:','LineWidth',1.2,'DisplayName','SM = 5% MAC');
msk = validMask & isVLMpts;
if any(msk)
    plot(machPts(msk),SM_percent(msk),'r--^','LineWidth',2,'MarkerSize',8,'DisplayName','SM (VLM)');
end
msk = validMask & ~isVLMpts;
if any(msk)
    plot(machPts(msk),SM_percent(msk),'r-o','LineWidth',2,'MarkerSize',8,'DisplayName','SM (DATCOM)');
end
xline(VLM_LIMIT,'k:','LineWidth',1.2);
xlabel('Mach','Interpreter','none');
ylabel('Static Margin (% MAC)','Interpreter','none');
title('Hellstinger V3 Static Margin vs Mach','Interpreter','none');
legend('Location','best');

fprintf('\n=== Static Margin Debug ===\n');
fprintf('%-6s  %-6s  %-10s  %-10s  %-10s  %-8s\n', ...
    'Mach','Src','CLA(/deg)','CMA_nose','CMA_cg','SM(%MAC)');
for k = 1:nPts
    if ~validMask(k), continue; end
    src = 'VLM'; if machPts(k) >= VLM_LIMIT, src = 'DATCOM'; end
    fprintf('%-6.2f  %-6s  %-10.4f  %-10.4f  %-10.4f  %-8.2f\n', ...
        machPts(k), src, CLA_vec(k), CMA_nose_vec(k), CMA_cg_vec(k), SM_percent(k));
end

%% ========================================================================
%%  Part 4 — HIGH-ALPHA MANEUVER ANALYSIS
%% ========================================================================
fprintf('\n========================================================\n');
fprintf('HIGH-ALPHA MANEUVER ANALYSIS\n');
fprintf('========================================================\n');

W_N  = model.geom.weights.mtow.v;
S_m2 = 2 * geom.wing.area.v;
g    = 9.80665;

rho_SL = 1.225;   a_SL = 340.3;
V_A = 0.30*a_SL;  q_A = 0.5*rho_SL*V_A^2;  T_A = 2*76300;
V_B = 0.60*a_SL;  q_B = 0.5*rho_SL*V_B^2;  T_B = 2*71000;
rho_15k = 0.771;  a_15k = 327.5;
V_C = 1.20*a_15k; q_C = 0.5*rho_15k*V_C^2; T_C = 2*55000;

HA_conds = struct( ...
    'label', {'HA-A  M=0.30 SL', 'HA-B  M=0.60 SL', 'HA-C  M=1.20 15kft'}, ...
    'Mach',  {0.30,  0.60,  1.20}, ...
    'q',     {q_A,   q_B,   q_C},  ...
    'V',     {V_A,   V_B,   V_C},  ...
    'T',     {T_A,   T_B,   T_C}   ...
);
g_limit = model.geom.input.g_limit.v;

fprintf('\n%-24s  %6s  %6s  %6s  %8s  %8s\n', ...
    'Condition','CLmax','a@CLmax','LoD@a','ITR(d/s)','STR(d/s)');
fprintf('%s\n', repmat('-',1,72));

haColors = {'b','r',[0.1 0.6 0.1]};

figure('Name','High-Alpha Maneuver','Position',[100 100 1200 420]);
sp_CL  = subplot(1,3,1); hold on; grid on;
xlabel('Alpha (deg)','Interpreter','none'); ylabel('CL','Interpreter','none');
title('CL vs Alpha','Interpreter','none');
sp_LoD = subplot(1,3,2); hold on; grid on;
xlabel('Alpha (deg)','Interpreter','none'); ylabel('L/D','Interpreter','none');
title('L/D vs Alpha','Interpreter','none');
sp_TR  = subplot(1,3,3); hold on; grid on;
xlabel('Alpha (deg)','Interpreter','none'); ylabel('Turn Rate (deg/s)','Interpreter','none');
title('Turn Rate vs Alpha','Interpreter','none');

for kc = 1:numel(HA_conds)
    cond = HA_conds(kc);
    tIdx = [];
    for kt = 1:numel(outVLM_HA.tables)
        if abs(outVLM_HA.tables(kt).Mach - cond.Mach) < 0.01
            tIdx = kt; break;
        end
    end
    if isempty(tIdx) || isempty(outVLM_HA.tables(tIdx).data)
        fprintf('%-24s  (no VLM data)\n', cond.label); continue;
    end

    t       = outVLM_HA.tables(tIdx);
    alpha_v = t.data.Alpha;
    CL_v    = t.data.CL;
    CD_v    = t.data.CD;
    LoD_v   = CL_v ./ max(CD_v, 1e-6);

    [CLmax, iMax] = max(CL_v);
    alpha_CLmax   = alpha_v(iMax);

    L_v      = CL_v * cond.q * S_m2;
    n_inst_v = min(L_v / W_N, g_limit);
    n_inst_v(n_inst_v < 1) = 1;
    ITR_v    = rad2deg((g / cond.V) * sqrt(n_inst_v.^2 - 1));
    [ITR_peak, ~] = max(ITR_v);

    n_sust_v = min(cond.T ./ max(CD_v * cond.q * S_m2, 1), g_limit);
    n_sust_v(n_sust_v < 1) = 1;
    STR_v    = rad2deg((g / cond.V) * sqrt(n_sust_v.^2 - 1));
    [STR_peak, ~] = max(STR_v);

    fprintf('%-24s  %6.3f  %6.1f  %6.2f  %8.2f  %8.2f\n', ...
        cond.label, CLmax, alpha_CLmax, LoD_v(iMax), ITR_peak, STR_peak);

    col = haColors{kc};
    subplot(sp_CL);
    plot(alpha_v,CL_v,'-o','Color',col,'LineWidth',1.8,'DisplayName',cond.label);
    xline(alpha_CLmax,'--','Color',col,'LineWidth',0.8,'HandleVisibility','off');
    subplot(sp_LoD);
    plot(alpha_v,LoD_v,'-o','Color',col,'LineWidth',1.8,'DisplayName',cond.label);
    subplot(sp_TR);
    plot(alpha_v,ITR_v,'-', 'Color',col,'LineWidth',2.0,'DisplayName',sprintf('%s ITR',cond.label));
    plot(alpha_v,STR_v,'--','Color',col,'LineWidth',1.4,'DisplayName',sprintf('%s STR',cond.label));
end
subplot(sp_CL);  legend('Location','northwest','FontSize',8);
subplot(sp_LoD); legend('Location','northeast','FontSize',8);
subplot(sp_TR);  legend('Location','best','FontSize',8);
sgtitle('High-Alpha Maneuver (VLM) — solid=ITR, dashed=STR','Interpreter','none');

%% ---- Departure boundary -----------------------------------------------
fprintf('\n=== Departure Boundary (Cn_beta_dyn, MIL-SPEC-8785C) ===\n');

Alpha_CNb  = [-4, -2, 0, 2, 4, 8];
CN_beta_pd = 180/pi * -1 * ...
    [-0.0007911,-0.0007198,-0.0006842,-0.0007198,-0.0007882,-0.000919];
CN_beta_pr = CN_beta_pd * (180/pi);

AR_w_val     = geom.wing.AR.v;
LambdaLE_deg = geom.wing.average_sweep.v;
Cl_beta_pr   = -0.1*(AR_w_val+cosd(LambdaLE_deg))/(AR_w_val+4);
Iz_over_Ix   = 8.0;
fprintf('  Cl_beta=%.4f /rad   Iz/Ix=%.1f (update from MOI calc)\n', Cl_beta_pr, Iz_over_Ix);

Cnb_dyn = CN_beta_pr.*cosd(Alpha_CNb) - Iz_over_Ix*Cl_beta_pr.*sind(Alpha_CNb);

fprintf('\n  %-8s  %-12s  %-12s  %-14s  %s\n','Alpha','Cnb/rad','Clb/rad','Cnb_dyn','Status');
fprintf('  %s\n',repmat('-',1,60));
for k = 1:numel(Alpha_CNb)
    dep = 'Resistant';
    if Cnb_dyn(k) < 0, dep = '** DEPARTURE PRONE **'; end
    fprintf('  %-8.1f  %-12.5f  %-12.5f  %-14.5f  %s\n', ...
        Alpha_CNb(k),CN_beta_pr(k),Cl_beta_pr,Cnb_dyn(k),dep);
end

alpha_ext   = linspace(Alpha_CNb(1),Alpha_CNb(end),300);
CNb_ext     = interp1(Alpha_CNb,CN_beta_pr,alpha_ext,'pchip');
Cnb_dyn_ext = CNb_ext.*cosd(alpha_ext) - Iz_over_Ix*Cl_beta_pr.*sind(alpha_ext);

figure('Name','Departure Boundary','Position',[150 150 750 480]);
hold on; grid on; box on;
plot(alpha_ext,Cnb_dyn_ext,'b-','LineWidth',2.5,'DisplayName','Cn_beta_dyn');
plot(Alpha_CNb,Cnb_dyn,'bo','MarkerFaceColor','b','MarkerSize',7,'HandleVisibility','off');
yline(0,'r--','LineWidth',2,'DisplayName','Departure Boundary');
neg_mask = Cnb_dyn_ext < 0;
if any(neg_mask)
    fill([alpha_ext(neg_mask),fliplr(alpha_ext(neg_mask))], ...
         [Cnb_dyn_ext(neg_mask),zeros(1,sum(neg_mask))], ...
         'r','FaceAlpha',0.15,'EdgeColor','none','DisplayName','Departure-prone');
end
zero_crossings = find(diff(sign(Cnb_dyn_ext)) ~= 0);
for zc = zero_crossings
    alpha_dep = interp1(Cnb_dyn_ext(zc:zc+1),alpha_ext(zc:zc+1),0);
    xline(alpha_dep,'k:','LineWidth',1.8,'HandleVisibility','off');
    text(alpha_dep+0.15,max(Cnb_dyn_ext)*0.80, ...
         sprintf('alpha_dep=%.1f deg',alpha_dep),'FontSize',10,'FontWeight','bold');
end
xlabel('Alpha (deg)','Interpreter','none','FontSize',12);
ylabel('Cn_beta_dyn (per rad)','Interpreter','none','FontSize',12);
title('Hellstinger V3 - Departure Boundary (MIL-SPEC-8785C)','Interpreter','none','FontSize',13);
legend('Location','best','FontSize',10,'Interpreter','none');

%% ---- Cn_beta flying qualities -----------------------------------------
figure('Name','Cn_beta vs alpha','Position',[150 150 700 450]);
hold on; grid on;
plot(Alpha_CNb,CN_beta_pd,'b-o','LineWidth',1.5,'DisplayName','Cn_beta');
ylim([-0.01, max(ylim)]);
yline(0,   'r--','LineWidth',1.5,'Label','Level 1 Flying Qualities', ...
    'LabelHorizontalAlignment','left','LabelVerticalAlignment','bottom');
yline(0.04,'k--','LineWidth',1.5,'Label','Navy Preferred Yaw Stability', ...
    'LabelHorizontalAlignment','left','LabelVerticalAlignment','bottom');
xlabel('Alpha (deg)','Interpreter','none');
ylabel('Cn_beta (/deg)','Interpreter','none');
title('Hellstinger V3 - Cn_beta vs Alpha','Interpreter','none');
legend('Location','best','Interpreter','none');

%% ========================================================================
%%  Scissor Plot
%% ========================================================================
x_cg_full  = 0.649 * m2ft(model.geom.fuselage.length.v);
x_cg_empty = 0.617 * m2ft(model.geom.fuselage.length.v);

CM_ac_w = -0.015;   eta_H = 0.86;   zEng = 0.167386;
CM_E = model.geom.prop.T0_NoAB.v * zEng / ...
       (model.cond.qinf.v * model.geom.ref_area.v * model.geom.wing.average_chord.v);

lambda_w  = model.geom.wing.tip_chord.v / model.geom.wing.root_chord.v;
AR_w      = model.geom.wing.AR.v;
LambdaLE  = deg2rad(model.geom.wing.average_sweep.v);
Lambda_c4 = deg2rad(model.geom.wing.average_qrtr_chd_sweep.v);
b_w       = model.geom.wing.span.v;
l_h       = m2ft(model.geom.elevator.qrtr_chd_x.v - model.geom.wing.qrtr_chd_x.v);
z_H       = 0.1;

SH_ft2 = m2ft(m2ft((model.geom.elevator.root_chord.v + model.geom.elevator.tip_chord.v) ...
               / 2 * model.geom.elevator.span.v));
SW_ft2 = m2ft(m2ft(geom.ref_area.v));

cla_2d    = 2*pi;
CLalpha_w = cla_2d / (1 + cla_2d/(pi*AR_w));
AR_H      = model.geom.elevator.span.v^2 / (SH_ft2/3.28084^2);
CLalpha_H = cla_2d / (1 + cla_2d/(pi*AR_H));

% Use M=0.60 DATCOM CLa if available, else nearest valid point
ref_idx = find(~isnan(CLa_pt) & abs(machPts-0.60) < 0.05, 1);
if isempty(ref_idx), [~,ref_idx] = min(abs(machPts-0.60)); end
CLalpha_wb = CLa_pt(ref_idx) * (180/pi);
if isnan(CLalpha_wb) || CLalpha_wb < 0.1
    CLalpha_wb = 2*pi*(1/(1+2/AR_w));  % fallback: Helmbold estimate
    fprintf('  NOTE: using Helmbold CLalpha fallback (CLa_pt not available)\n');
end

xac_wing_frac = 0.25 + (tan(LambdaLE)/4)*(1+2*lambda_w)/((1+lambda_w)*AR_w);
x_ac_w   = model.geom.wing.le_x.v + xac_wing_frac*model.geom.wing.root_chord.v;
K2       = 0.9;
S_Bmax   = model.geom.fuselage.max_area.v;
CLalpha_B = 2*K2*S_Bmax/model.geom.wing.area.v;
x_ac_B   = 0.25*model.geom.fuselage.length.v;
x_ac_wb  = m2ft((x_ac_w*CLalpha_w + x_ac_B*CLalpha_B)/CLalpha_wb);

K_A      = 1/AR_w - 1/(1+AR_w^1.7);
K_lambda = (10-3*lambda_w)/7;
K_H      = (1-abs(z_H/b_w))/(2*l_h/b_w)^(1/3);
depsda   = 4.44*(K_A*K_lambda*K_H*sqrt(cos(Lambda_c4)))^1.19;
fprintf('\n=== Scissor Plot Setup ===\n');
fprintf('  l_h=%.2f ft  SH=%.2f ft^2  SW=%.2f ft^2  dε/dα=%.4f\n', ...
    l_h, SH_ft2, SW_ft2, depsda);

CMW = CM_ac_w*(AR_w+2*cos(Lambda_c4))/(AR_w+4*cos(Lambda_c4));

xcg_ac_norm_cntrl = linspace(-0.35,0,400);
xcg_ac_norm_stab  = linspace(0,0.35,400);
K_stab    = CLalpha_H*eta_H*(1-depsda)*(l_h/cbar_ft);
SHSW_stab = @(x) CLalpha_wb*180/pi .* x ./ K_stab;

inc=-.09; eps0=2*model.cond.CL.v/(pi*model.geom.wing.AR.v);
CLH_max  = CLalpha_H*(-eps0-inc);
K_ctrl   = CLH_max*eta_H*(l_h/cbar_ft);
SHSW_ctrl = @(x) (model.cond.CL.v.*x + CMW + CM_E)./K_ctrl;

Xcg_full_norm  = (x_cg_full  - x_ac_wb)/cbar_ft;
Xcg_empty_norm = (x_cg_empty - x_ac_wb)/cbar_ft;
x_fwd = min(Xcg_full_norm,Xcg_empty_norm);
x_aft = max(Xcg_full_norm,Xcg_empty_norm);
SH_design = max(SHSW_stab(x_aft),SHSW_ctrl(x_fwd));

slope_c      = SHSW_ctrl(1)-SHSW_ctrl(0);
intercept_c  = SHSW_ctrl(0);
x_ctrl_cross = (SH_design-intercept_c)/slope_c;
SH_SW_actual = SH_ft2/SW_ft2;

fprintf('  SH/SW design=%.4f  actual=%.4f\n', SH_design, SH_SW_actual);

figure('Name','Hellstinger V3 Scissor Plot','Position',[50 50 700 620]);
hold on; grid on; box on;
plot(xcg_ac_norm_stab, SHSW_stab(xcg_ac_norm_stab), 'r-','LineWidth',2.5,'DisplayName','Stability Limit');
plot(xcg_ac_norm_cntrl,SHSW_ctrl(xcg_ac_norm_cntrl),'g-','LineWidth',2.5,'DisplayName','Control Limit');
yline(SH_SW_actual,'b--','LineWidth',1.5,'DisplayName',sprintf('SH/SW actual=%.3f',SH_SW_actual));
plot(x_ctrl_cross,SH_design,'gs','MarkerFaceColor','g','MarkerSize',9,'HandleVisibility','off');
xline(Xcg_full_norm, 'Color',[.35 .35 .35],'LineWidth',2.5,'HandleVisibility','off');
xline(Xcg_empty_norm,'Color',[.35 .35 .35],'LineWidth',2.5,'HandleVisibility','off');
yl = ylim;
text(Xcg_full_norm, yl(2)*.95,'XCG at MGTOW',      'Rotation',90,'HorizontalAlignment','right','FontSize',9,'Color',[.35 .35 .35],'FontWeight','bold');
text(Xcg_empty_norm,yl(2)*.95,'XCG at empty weight','Rotation',90,'HorizontalAlignment','right','FontSize',9,'Color',[.35 .35 .35],'FontWeight','bold');
xline(0,'k:','LineWidth',0.8,'HandleVisibility','off');
xlim([-0.35,0.35]); ylim([-0.8,0.8]);
xlabel('(x_cg - x_ac) / cbar','Interpreter','none','FontSize',12);
ylabel('SH/SW','Interpreter','none','FontSize',12);
title('Hellstinger V3 Longitudinal Stability','Interpreter','none','FontSize',13);

m_stab  = CLalpha_wb*180/pi/K_stab;
x_trunc = linspace(0,max(xcg_ac_norm_stab),200);
y_trunc = m_stab*(x_trunc-x_aft)+SH_design;
plot(x_trunc,y_trunc,'r--','LineWidth',2,'DisplayName','Stability (truncated)');
x_blue = linspace(x_ctrl_cross,x_aft,100);
plot(x_blue,SH_design*ones(size(x_blue)),'b-','LineWidth',2, ...
     'DisplayName',sprintf('SH/SW design=%.3f',SH_design));
plot(x_aft,SH_design,'rs','MarkerFaceColor','r','MarkerSize',9,'HandleVisibility','off');
x_int = SH_design/m_stab;
static_margin = x_int-x_aft;
plot(x_int,SH_design,'ko','MarkerFaceColor','k');
quiver(x_aft,SH_design,(x_int-x_aft),0,0,'k','LineWidth',3,'MaxHeadSize',4);
quiver(x_int,SH_design,-(x_int-x_aft),0,0,'k','LineWidth',3,'MaxHeadSize',4,'HandleVisibility','off');
text(0.1,SH_design+0.2,sprintf('STATIC MARGIN = %.3f',static_margin), ...
     'HorizontalAlignment','center','FontSize',18,'FontWeight','bold','Color','k','Interpreter','none');
legend('Location','northwest','FontSize',10,'Interpreter','none');

%% ---- Planform ----------------------------------------------------------
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