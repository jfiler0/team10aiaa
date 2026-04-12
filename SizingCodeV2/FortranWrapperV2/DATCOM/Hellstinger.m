%% datcom_example.m
<<<<<<< HEAD
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
=======
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
>>>>>>> 00ee69bc43a2649abcd3be0e40f41ba5309da5ed

initialize
matlabSetup
%build_f18_template
build_kevin_cad

% INITIAL OBJECTS TO LOAD
build_default_settings
settings = readSettings();
% geom = loadAircraft("f18_superhornet", settings);
geom = loadAircraft("kevin_cad", settings);
model = model_class(settings, geom);
    N = 100;
    perf = performance_class(model);
    settings = readSettings();
   
thisDir = fileparts(mfilename('fullpath'));
examplesDir = fullfile(thisDir, 'Examples');

<<<<<<< HEAD
%% ========================================================================
%%  Part 1 — JKayVLM  (M < 0.6)
%% ========================================================================
VLM_LIMIT = 0.60;
alphaVec  = [-4, -2, 0, 2, 4, 8, 12, 16, 20];
=======
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
>>>>>>> 00ee69bc43a2649abcd3be0e40f41ba5309da5ed

%% Stability Search Test Values
model.geom.wing.le_x.v = 7.8;
model.geom.wing.average_sweep.v = 45;

l_h = 14; % global l_h value 
% %l_h = m2ft(model.geom.elevator.qrtr_chd_x.v - model.geom.wing.qrtr_chd_x.v);
% %z_H     = model.geom.elevator.sections(1).le_z.v - model.geom.wing.sections(1).le_z.v;
 z_H = 6;
%% ---- Case 3: Build custom input from struct ----------------------------
% Generic supersonic fighter: circular fuselage + swept wing + tails.
% Demonstrates write_datcom_input — replace numbers with your own geometry.

<<<<<<< HEAD
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
=======
cfg = struct();
cfg.dim = 'FT';

c = struct();
c.caseid = 'GENERIC SUPERSONIC FIGHTER - BASELINE';

% Flight conditions: 4 Mach numbers, 9 alpha points each
c.fltcon.nmach  = 4;
c.fltcon.mach   = [0.61, 0.9, 1.4, 2.0];
c.fltcon.nalpha = 9;
c.fltcon.alschd = [-4, -2, 0, 2, 4, 8, 12, 16, 20];
c.fltcon.rnnub  = [2.5e6, 3.8e6, 6.0e6, 9.5e6];

% cLa model updates 
perf.model.cond = levelFlightCondition(perf, 0, c.fltcon.mach(1),model.geom.weights.mtow.v);
cLa_M1 = model.CLa;
perf.model.cond = levelFlightCondition(perf, 0, c.fltcon.mach(2),model.geom.weights.mtow.v);
cLa_M2 = model.CLa;
perf.model.cond = levelFlightCondition(perf, 0, c.fltcon.mach(3),model.geom.weights.mtow.v);
cLa_M3 = model.CLa;
perf.model.cond = levelFlightCondition(perf, 0, c.fltcon.mach(4),model.geom.weights.mtow.v);
cLa_M4 = model.CLa;
perf.model.cond = levelFlightCondition(perf, 0, c.fltcon.mach(1),model.geom.weights.mtow.v);
>>>>>>> 00ee69bc43a2649abcd3be0e40f41ba5309da5ed

% Reference geometry
c.optins.sref  = m2ft(m2ft(geom.ref_area.v));    % ft^2  gross wing area
c.optins.cbarr = m2ft(geom.wing.average_chord.v);     % ft    mean aerodynamic chord
c.optins.blref = m2ft(geom.wing.span.v);     % ft    wing span

% Component positions measured from nose (ft)
x_cg_empty = 0.647*m2ft(model.geom.fuselage.length.v);
x_cg_full = 0.617*m2ft(model.geom.fuselage.length.v);
c.synths.xcg    = x_cg_full;    % CG x-location ---- NEEDS UPDATE ----- 
c.synths.zcg    = m2ft(-0.003*geom.fuselage.length.v);
c.synths.xw     = m2ft(geom.wing.le_x.v);    % wing LE at root
c.synths.zw     = m2ft(geom.wing.sections(1).le_z.v);    % wing below body centreline
c.synths.aliw   = 0;     % wing incidence (deg)
c.synths.xh     = m2ft(geom.elevator.le_x.v);    % horiz tail LE at root
c.synths.zh     = m2ft(geom.elevator.sections(1).le_z.v);
c.synths.alih   = 0.0; % <------ WHAT IS THIS
c.synths.xv     = m2ft(geom.rudder.le_x.v);    % vert tail LE at root
c.synths.vertup = true;    % vert tail above centreline

<<<<<<< HEAD
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
=======
% Fuselage: 12 circular cross-sections
xb = m2ft([0, 1.385, 2.771, 4.156, 5.542, 6.927, 8.313, 9.698, 11.084, 12.469, 13.855, 15.24]);
rb = m2ft([0, 0.441, 0.807, 0.976, 0.977, 0.977, 0.977, 0.977, 0.977, 0.909, 0.906, 0.906]);
>>>>>>> 00ee69bc43a2649abcd3be0e40f41ba5309da5ed

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

c.wgschr.tovc   = geom.wing.sections(1).tc.v;    % 5% t/c root
c.wgschr.tovco  = geom.wing.sections(end).tc.v;    % 4% t/c tip
c.wgschr.xovc   = 0.40;    % max thickness at 40% chord
c.wgschr.deltay = 8.0; % need
c.wgschr.cli    = 0.05; % need
c.wgschr.alphai = 0.5; % need 
c.wgschr.clalpa = [cLa_M1, cLa_M2, cLa_M3, cLa_M4];  % per deg, one per Mach. Need
c.wgschr.clmax  = [1.2,  1.0,  0.8,  0.6]; % need 
c.wgschr.cmo    = -0.015;
c.wgschr.leri   = 0.008; % assumed to be the same as f18
c.wgschr.clamo  = 0.105; % assumed to be the same as f18

<<<<<<< HEAD
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
=======
% Horizontal tail: 55 deg LE sweep
c.htplnf.chrdr  = m2ft(model.geom.elevator.root_chord.v);    c.htplnf.chrdtp = m2ft(model.geom.elevator.tip_chord.v);
c.htplnf.sspn   = m2ft(model.geom.elevator.span.v/2);    c.htplnf.sspne  = m2ft((geom.wing.span.v - rb(11))/2);
c.htplnf.savsi  = model.geom.elevator.average_qrtr_chd_sweep.v;    c.htplnf.chstat = 0.25;
c.htplnf.swafp  = 0.0;     c.htplnf.twista = 0.0;
c.htplnf.sspndd = 0.0;     c.htplnf.dhdadi = 0.0;
c.htplnf.dhdado = 0.0;     c.htplnf.type   = 1;
>>>>>>> 00ee69bc43a2649abcd3be0e40f41ba5309da5ed

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

<<<<<<< HEAD
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

machA = [0.60, 0.75, 1.15, 1.30]; % [0.60, 0.75, 1.15, 1.30, 1.40]
reA   = [2.0e6, 2.8e6, 4.5e6, 5.5e6]; %  [2.0e6, 2.8e6, 4.5e6, 5.5e6, 6.0e6]
tblA  = runDatcomPass(cfg, geom, model, examplesDir, ...
                      machA, reA, alphaVec, ...
                      xb, rb, xb_m, rb_m, bln_ft, bla_ft, ...
                      rb_at_wing_m, rb_at_ht_m, 'datcom_A');

machB = [1.350, 1.55, 1.65, 1.75, 1.85];
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
=======
% Write input file then run
inpFile = write_datcom_input(cfg, 'fighter_baseline.inp');
out3    = runDatcom(fullfile(examplesDir, 'fighter_baseline.inp'));

fprintf('\n=== Case 3: Custom fighter (struct input) ===\n');
for k = 1:numel(out3.tables)
    t = out3.tables(k);
    fprintf('\n  [%d] M=%.2f | %s\n', k, t.Mach, t.caseTitle);
>>>>>>> 00ee69bc43a2649abcd3be0e40f41ba5309da5ed
    if ~isempty(t.data) && ~all(isnan(t.data.CL))
        disp(t.data)
    end
end

<<<<<<< HEAD
%% ========================================================================
%%  Merge + plots
%% ========================================================================
=======
% Plot CL, CD, CM vs alpha at first Mach
t = out3.tables(1);
if ~isempty(t.data) && ~all(isnan(t.data.CL))
    figure('Name', sprintf('DATCOM Fighter M=%.1f', t.Mach));
    subplot(1,3,1);
    plot(t.data.Alpha, t.data.CL, 'b-o', 'LineWidth', 1.5);
    xlabel('\alpha (deg)'); ylabel('C_L'); title('Lift'); grid on;
>>>>>>> 00ee69bc43a2649abcd3be0e40f41ba5309da5ed

    subplot(1,3,2);
    plot(t.data.Alpha, t.data.CD, 'r-o', 'LineWidth', 1.5);
    xlabel('\alpha (deg)'); ylabel('C_D'); title('Drag'); grid on;

    subplot(1,3,3);
    plot(t.data.Alpha, t.data.CM, 'k-o', 'LineWidth', 1.5);
    xlabel('\alpha (deg)'); ylabel('C_M'); title('Pitch Moment'); grid on;

    sgtitle(sprintf('%s  M=%.1f', t.caseTitle, t.Mach));
end

%% X_ac_wb generation
% Wing AC (fraction of root chord from apex, then convert to fuse station)
x_cg_empty = 0.647*m2ft(model.geom.fuselage.length.v);
x_cg_full = 0.617*m2ft(model.geom.fuselage.length.v);
lambda   = model.geom.wing.tip_chord.v / model.geom.wing.root_chord.v;
AR_w     = model.geom.wing.AR.v;
LambdaLE = deg2rad(model.geom.wing.average_sweep.v);  % LE sweep in rad

xac_wing_frac = 0.25 + (tan(LambdaLE)/4) * (1 + 2*lambda) / ((1 + lambda) * AR_w);
wing_le_X_trial = model.geom.wing.le_x.v
x_ac_w = m2ft(wing_le_X_trial) + xac_wing_frac * m2ft(model.geom.wing.root_chord.v);

<<<<<<< HEAD
%% ---- Scissor plot ------------------------------------------------------
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
SM        = (Xnp_ft - xcg_ft) / cbar_ft;
validMask = ~isnan(Xnp_ft) & ~isnan(SM) & ~isinf(SM);
isVLMpts  = machPts < VLM_LIMIT;

figure('Name','Scissor Plot — Neutral Point & Static Margin','Position',[50 50 1100 480]);

subplot(1,2,1); hold on; grid on; box on;
yline(xcg_ft,'k--','LineWidth',1.5,'DisplayName',sprintf('CG = %.1f ft',xcg_ft));
msk = validMask & isVLMpts;
if any(msk)
    plot(machPts(msk),Xnp_ft(msk),'b--^','LineWidth',2,'MarkerSize',8,'DisplayName','Xnp (VLM)');
end
msk = validMask & ~isVLMpts;
if any(msk)
    plot(machPts(msk),Xnp_ft(msk),'b-o','LineWidth',2,'MarkerSize',8,'DisplayName','Xnp (DATCOM)');
end
xline(VLM_LIMIT,'k:','LineWidth',1.2);
xlabel('Mach','Interpreter','none');
ylabel('Distance from nose (ft)','Interpreter','none');
title('Neutral Point vs Mach','Interpreter','none');
legend('Location','best','Interpreter','none');
text(0.05,0.05,'Aft \uparrow','Units','normalized','FontSize',8,'Color',[.4 .4 .4],'Interpreter','tex');

subplot(1,2,2); hold on; grid on; box on;
yline(0,   'k--','LineWidth',1.5,'DisplayName','Neutral (SM=0)');
yline(0.05,'g:', 'LineWidth',1.2,'DisplayName','SM = 5%');
yline(0.10,'m:', 'LineWidth',1.2,'DisplayName','SM = 10%');
msk = validMask & isVLMpts;
if any(msk)
    plot(machPts(msk),SM(msk)*100,'r--^','LineWidth',2,'MarkerSize',8,'DisplayName','SM (VLM)');
end
msk = validMask & ~isVLMpts;
if any(msk)
    plot(machPts(msk),SM(msk)*100,'r-o','LineWidth',2,'MarkerSize',8,'DisplayName','SM (DATCOM)');
end
xline(VLM_LIMIT,'k:','LineWidth',1.2);
xlabel('Mach','Interpreter','none');
ylabel('Static Margin (%c)','Interpreter','none');
title('Static Margin vs Mach','Interpreter','none');
legend('Location','best','Interpreter','none');
text(0.05,0.95,'Stable (+SM)',  'Units','normalized','FontSize',8,'Color',[0 .5 0],'Interpreter','none');
text(0.05,0.05,'Unstable (-SM)','Units','normalized','FontSize',8,'Color',[.8 0 0],'Interpreter','none');
sgtitle(sprintf('Scissor Plot  |  CG = %.1f ft from nose  |  cbar = %.2f ft', ...
        xcg_ft, cbar_ft), 'Interpreter', 'none');

% Stability summary table
fprintf('\n=== Stability Summary ===\n');
fprintf('  CG = %.2f ft from nose  (%.2f%% MAC from wing LE)\n', ...
        xcg_ft, (xcg_ft - xw_ft) / cbar_ft * 100);
fprintf('  %-6s  %-6s  %-10s  %-10s  %-12s  %-10s\n', ...
        'Mach','Src','CLa/deg','CMa/deg','Xnp (ft)','SM (%c)');
for k = 1:nPts
    if ~validMask(k), continue; end
    src = 'VLM'; if machPts(k) >= VLM_LIMIT, src = 'DAT'; end
    fprintf('  %.2f   %-3s  %10.5f  %10.5f  %12.3f  %10.2f\n', ...
            machPts(k), src, CLa_pt(k), CMa_pt(k), Xnp_ft(k), SM(k)*100);
end
=======
% Wing lift curve slope (Helmbold/DATCOM)
clalpha_w = 2*pi;
CLalpha_w = clalpha_w / (1 + clalpha_w/(pi*AR_w));
>>>>>>> 00ee69bc43a2649abcd3be0e40f41ba5309da5ed


% Body lift curve slope (DATCOM slender body approx)
% Munk factor K2 ~ 0.9 for typical fuselage fineness ratios
K2         = 0.9;
ft_per_m      = 3.28084;
S_Bmax     = model.geom.fuselage.max_area.v*ft_per_m^2;  % max cross-section area
CLalpha_B  = 2 * K2 * S_Bmax / (model.geom.wing.area.v*ft_per_m^2); % per radian

% Wing-body combined slope (using your existing model value)
CLalpha_wb = model.CLa;

% Body AC: for slender fuselage approximately at 25% body length
% More accurate: use Munk integral, but 25% is standard first estimate
x_ac_B = 0.25 * m2ft(model.geom.fuselage.length.v);

% Combined wing-body AC (area-weighted)
x_ac_wb = (x_ac_w * CLalpha_w + x_ac_B * CLalpha_B) / (CLalpha_B + CLalpha_w);

%% Downwash Gradient DATCOM estimation
AR      = model.geom.wing.AR.v;
lambda  = model.geom.wing.tip_chord.v / model.geom.wing.root_chord.v;
Lambda_c4 = deg2rad(model.geom.wing.average_qrtr_chd_sweep.v);
b       = model.geom.wing.span.v;

K_A      = 1/AR - 1/(1 + AR^1.7);
K_lambda = (10 - 3*lambda) / 7;
K_H      = (1 - abs(z_H/b)) / (2*l_h/b)^(1/3);

depsdalpha = 4.44 * (K_A * K_lambda * K_H * sqrt(cos(Lambda_c4)))^1.19

%% Scissor Plot Generation

clalphH = 2*pi; %/rad
CLalphH = clalphH/(1 + clalphH/(pi*model.geom.elevator.AR.v)); %/rad
etaH  = 0.86; % Assume middle of the road 

xcg_ac_norm = linspace(-0.3,0.3,100);

eps0 = 2*model.cond.CL.v/(pi*model.geom.wing.AR.v); %rad
CLH = CLalphH*(-eps0);
tau = 0.7; % elevator effectiveness due to stabilator
delta_e_max = 25; %deg
CLH_max = CLH;
% CLH_max = CLalphH * (-eps0 - tau * delta_e_max*pi/180);

zEng = 0.167386; %m

CMW = c.wgschr.cmo * (AR_w + 2*cos(Lambda_c4)) / (AR_w + 4*cos(Lambda_c4));
CME = model.cond.throttle.v * 0.25 * model.geom.prop.T0_NoAB.v * zEng / ...
      (model.cond.qinf.v * model.geom.wing.area.v * model.geom.wing.average_chord.v);
% Stability Requirement
SHSW_stability = @(xcg_ac_norm) model.CLa.*xcg_ac_norm./(CLalphH*etaH*(1-depsdalpha).*(l_h./m2ft(model.geom.wing.average_chord.v)));

% Control Requirement 
SHSW_control = @(xcg_ac_norm) (model.cond.CL.v.*xcg_ac_norm./(CLH_max*etaH*l_h/m2ft(model.geom.wing.average_chord.v))) + (CMW + CME)/(CLH_max*etaH*l_h/m2ft(model.geom.wing.average_chord.v));

figure;

plot(xcg_ac_norm, SHSW_stability(xcg_ac_norm),'r');
hold on
plot(xcg_ac_norm, SHSW_control(xcg_ac_norm),'g');

Xcgfull_norm = (x_cg_full - x_ac_wb)/m2ft(model.geom.wing.average_chord.v);
Xcgempty_norm = (x_cg_empty - x_ac_wb)/m2ft(model.geom.wing.average_chord.v);
dub1 = xline(Xcgfull_norm,'LineWidth',3);
dub1.Label = 'XCG at MGTOW';
dub2 = xline(Xcgempty_norm,'LineWidth',3);
dub2.Label = 'XCG at empty weight';
xline(0);
%xline(0,'k','LineWidth',4)
legend('Stability Limit','Control Limit');
xlabel('x_cg - x_ac normalized');
ylabel('SH/SW');
if isfile(inpFile), delete(inpFile); end