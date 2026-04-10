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
%  Part 1 — JKayVLM  (M < 0.6)
% ========================================================================
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

% ---- DATCOM run helper --------------------------------------------------
% DATCOM's RNNUB line is limited to 72 chars. With decimal Re notation
% (~10 chars each), max 5 Mach points fit per run.  To get more coverage,
% we run DATCOM twice with different Mach ranges and merge the results.
%
% Pass A: subsonic join + low supersonic  [0.60, 0.80, 1.15, 1.30, 1.50]
% Pass B: mid supersonic                   [1.20, 1.35, 1.50, 1.65, 1.80]
% Pass C: upper supersonic                 [1.60, 1.70, 1.80, 1.90, 2.00]
%
% Transonic M=0.90-1.10 excluded — DATCOM returns NDM for this geometry.

% Shared geometry quantities (computed once, reused in both runs)
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
% Run a single DATCOM pass and return the best-CLa table per Mach.
    nMach = numel(machVec);

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

    c.synths.xcg    = 34;
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

    cfgPass     = struct(); cfgPass.dim = 'FT'; cfgPass.cases(1) = c;
    inpLocal    = write_datcom_input(cfgPass, [passName '.inp']);

    % Line-length diagnostic
    inpLines = splitlines(string(fileread(inpLocal)));
    for kL = 1:numel(inpLines)
        if strlength(inpLines(kL)) > 72
            fprintf('WARNING [%s] line %d too long (%d chars)\n', ...
                    passName, kL, strlength(inpLines(kL)));
        end
    end

    inpFile = fullfile(examplesDir, [passName '.inp']);
    copyfile(inpLocal, inpFile, 'f');
    out     = runDatcom(inpFile, 'keepOut', true);
    fprintf('DATCOM %s: status=%d  raw tables=%d\n', passName, out.status, numel(out.tables));

    % Select best (highest CLa) table at each Mach = full BWHV config
    % Use index accumulation to avoid dissimilar-struct assignment error.
    tbl = out.tables([]); % empty with same fields as out.tables
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
    if isfile(inpLocal), delete(inpLocal); end
end

% =========================================================================
% Three passes of 5 Mach points each — all confined to M=0.6 to M=2.0.
% Transonic band M=0.88-1.12 excluded (DATCOM NDM for this geometry).
%
% Pass A: subsonic + low supersonic       [0.60, 0.80, 1.15, 1.30, 1.50]
% Pass B: mid supersonic                  [1.15, 1.40, 1.55, 1.70, 1.85]  (1.15 overlap for continuity check)
% Pass C: upper supersonic                [1.60, 1.70, 1.80, 1.90, 2.00]
%
% Re values scaled ~linearly with Mach at ~30kft conditions.
machA = [0.60, 0.75, 1.15, 1.30, 1.50];   % [0.60, 0.75, 1.15, 1.30, 1.50]
reA   = [2.0e6, 2.8e6, 4.5e6, 5.5e6, 6.5e6]; % [2.0e6, 2.8e6, 4.5e6, 5.5e6, 6.5e6]
tblA  = runDatcomPass(cfg, geom, model, examplesDir, ...
                      machA, reA, alphaVec, ...
                      xb, rb, xb_m, rb_m, bln_ft, bla_ft, ...
                      rb_at_wing_m, rb_at_ht_m, 'datcom_A');

machB = [1.20, 1.35, 1.65, 1.80];
reB   = [5.0e6, 5.8e6, 7.2e6, 8.0e6];
tblB  = runDatcomPass(cfg, geom, model, examplesDir, ...
                      machB, reB, alphaVec, ...
                      xb, rb, xb_m, rb_m, bln_ft, bla_ft, ...
                      rb_at_wing_m, rb_at_ht_m, 'datcom_B');

machC = [1.60, 1.70, 1.80, 1.90, 2.00];
reC   = [7.5e6, 8.0e6, 8.5e6, 9.0e6, 9.5e6];
tblC  = runDatcomPass(cfg, geom, model, examplesDir, ...
                      machC, reC, alphaVec, ...
                      xb, rb, xb_m, rb_m, bln_ft, bla_ft, ...
                      rb_at_wing_m, rb_at_ht_m, 'datcom_C');

% Merge all passes then dedup overlapping Mach points (keep highest CLa)
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

%% Merged resiults and plots 

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

%% ---- Scissor plot ------------------------------------------------------
% 
% CLAUDE TRIED DOING THIS NEEDS TO BE FIXED --
%
% Reference quantities (ft) — read directly from geometry, not from c struct
xcg_ft  = 34;                              % ft from nose — UPDATE to match c.synths.xcg
cbar_ft = m2ft(geom.wing.average_chord.v); % mean aerodynamic chord (ft)
xw_ft   = m2ft(geom.wing.le_x.v);         % wing LE x-position (ft)

% Extract CLa and CMa at alpha=0 for each Mach point
machPts = [allTables.Mach];
nPts    = numel(allTables);
CLa_pt  = NaN(1, nPts);
CMa_pt  = NaN(1, nPts);

for k = 1:nPts
    t = allTables(k);
    if isempty(t.data), continue; end
    % Use alpha=0 row if present, else smallest |alpha|
    [~, i0] = min(abs(t.data.Alpha));
    if ~isnan(t.data.CLA(i0)), CLa_pt(k) = t.data.CLA(i0); end
    if ~isnan(t.data.CMA(i0)), CMa_pt(k) = t.data.CMA(i0); end
end

% Neutral point and static margin
% Xnp = Xcg - (CMa/CLa)*cbar   (positive = aft of CG = stable)
Xnp_ft = xcg_ft - (CMa_pt ./ CLa_pt) * cbar_ft;
SM      = (Xnp_ft - xcg_ft) / cbar_ft;   % fraction of cbar (positive = stable)

% Only plot where both CLa and CMa are valid
validMask = ~isnan(Xnp_ft) & ~isnan(SM) & ~isinf(SM);
isVLMpts  = machPts < VLM_LIMIT;

figure('Name','Scissor Plot — Neutral Point & Static Margin','Position',[50 50 1100 480]);

% ---- Panel 1: Neutral point location vs Mach ----------------------------
subplot(1,2,1); hold on; grid on; box on;

% CG reference line
yline(xcg_ft, 'k--', 'LineWidth', 1.5, 'DisplayName', ...
      sprintf('CG = %.1f ft', xcg_ft));

msk = validMask & isVLMpts;
if any(msk)
    plot(machPts(msk), Xnp_ft(msk), 'b--^', 'LineWidth', 2, ...
         'MarkerSize', 8, 'DisplayName', 'Xnp (VLM)');
end
msk = validMask & ~isVLMpts;
if any(msk)
    plot(machPts(msk), Xnp_ft(msk), 'b-o', 'LineWidth', 2, ...
         'MarkerSize', 8, 'DisplayName', 'Xnp (DATCOM)');
end

xline(VLM_LIMIT, 'k:', 'LineWidth', 1.2);
xlabel('Mach',                 'Interpreter', 'none');
ylabel('Distance from nose (ft)', 'Interpreter', 'none');
title('Neutral Point vs Mach', 'Interpreter', 'none');
legend('Location', 'best', 'Interpreter', 'none');
% Annotate: aft = top of plot → add arrow note
text(0.05, 0.05, 'Aft \uparrow', 'Units', 'normalized', ...
     'FontSize', 8, 'Color', [0.4 0.4 0.4], 'Interpreter', 'tex');

% ---- Panel 2: Static margin vs Mach -------------------------------------
subplot(1,2,2); hold on; grid on; box on;

% Zero SM line
yline(0, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Neutral (SM=0)');
% 5% and 10% SM reference lines
yline(0.05, 'g:', 'LineWidth', 1.2, 'DisplayName', 'SM = 5%');
yline(0.10, 'm:', 'LineWidth', 1.2, 'DisplayName', 'SM = 10%');

msk = validMask & isVLMpts;
if any(msk)
    plot(machPts(msk), SM(msk)*100, 'r--^', 'LineWidth', 2, ...
         'MarkerSize', 8, 'DisplayName', 'SM (VLM)');
end
msk = validMask & ~isVLMpts;
if any(msk)
    plot(machPts(msk), SM(msk)*100, 'r-o', 'LineWidth', 2, ...
         'MarkerSize', 8, 'DisplayName', 'SM (DATCOM)');
end

xline(VLM_LIMIT, 'k:', 'LineWidth', 1.2);
xlabel('Mach',              'Interpreter', 'none');
ylabel('Static Margin (%c)', 'Interpreter', 'none');
title('Static Margin vs Mach', 'Interpreter', 'none');
legend('Location', 'best', 'Interpreter', 'none');

% Positive SM = stable (nose pitches down when disturbed)
text(0.05, 0.95, 'Stable (+SM)', 'Units', 'normalized', ...
     'FontSize', 8, 'Color', [0 0.5 0], 'Interpreter', 'none');
text(0.05, 0.05, 'Unstable (-SM)', 'Units', 'normalized', ...
     'FontSize', 8, 'Color', [0.8 0 0], 'Interpreter', 'none');

sgtitle(sprintf('Scissor Plot  |  CG = %.1f ft from nose  |  c̄ = %.2f ft', ...
        xcg_ft, cbar_ft), 'Interpreter', 'none');

% Print summary table
fprintf('\n=== Stability Summary ===\n');
fprintf('  CG = %.2f ft from nose  (%.2f%% MAC)\n', xcg_ft, ...
        (xcg_ft - xw_ft) / cbar_ft * 100);
fprintf('  %-6s  %-10s  %-10s  %-10s  %-10s\n', ...
        'Mach', 'CLa/deg', 'CMa/deg', 'Xnp (ft)', 'SM (%c)');
for k = 1:nPts
    if ~validMask(k), continue; end
    src = 'VLM'; if machPts(k) >= VLM_LIMIT, src = 'DAT'; end
    fprintf('  %.2f   %-3s  %9.5f  %9.5f  %9.3f  %9.2f\n', ...
            machPts(k), src, CLa_pt(k), CMa_pt(k), Xnp_ft(k), SM(k)*100);
end

%% ---- Cleanup -----------------------------------------------------------
% Input files are deleted inside runDatcomPass; nothing to clean up here.


% =========================================================================
function v = getval(x)
%GETVAL  Return numeric value from plain double or .v struct field.
if isstruct(x), v = x.v; else, v = double(x); end
end

function s = ternary(cond, a, b)
if cond, s = a; else, s = b; end
end