%% idrag_example_hellstinger.m
% Induced-drag analysis for HellstingerV3 using geometry loaded from JSON
% through loadAircraft().
%
% This version blends the LERX and main wing into one continuous section
% table for the "LERX + wing" cases so IDRAG treats that configuration as
% one surface instead of two separate panel blocks.

clear; clc;

%% ---- Load aircraft geometry -------------------------------------------
build_default_settings
settings = readSettings();
geom = loadAircraft("HellstingerV3", settings);

%% ---- Reference quantities ---------------------------------------------
sref   = geom.ref_area.v;            % m^2, full reference area
cavg   = geom.wing.average_chord.v;  % m
b_full = geom.wing.span.v;           % m, full span
AR_geo = b_full^2 / sref;            % use b^2/S for Oswald efficiency
xcg    = geom.wing.x_cp.v;           % approximate aerodynamic center

%% ---- Build section tables from JSON -----------------------------------
% Section format:
%   [le_x, le_y, chord]
%
% Assumptions:
% - wing.sections are ordered root to tip
% - section 2 is the LERX/wing junction
% - elevator.sections define the horizontal tail semispan

nWing = numel(geom.wing.sections);
wing_secs = zeros(nWing,3);

for i = 1:nWing
    sec = geom.wing.sections(i);
    wing_secs(i,:) = [sec.le_x.v, sec.le_y.v, sec.chord_length.v];
end

nElev = numel(geom.elevator.sections);
elev_secs = zeros(nElev,3);

for i = 1:nElev
    sec = geom.elevator.sections(i);
    elev_secs(i,:) = [sec.le_x.v, sec.le_y.v, sec.chord_length.v];
end

%% ---- Split wing into LERX and main wing -------------------------------
% Change splitIdx if your JSON section ordering changes.
splitIdx = 2;

lerx_secs = wing_secs(1:splitIdx, :);
main_secs = wing_secs(splitIdx:end, :);

% Blended continuous LERX + wing definition
% Remove duplicated junction row from main wing before merging.
full_secs = [lerx_secs; main_secs(2:end,:)];

%% ---- Flight conditions -------------------------------------------------
% Condition A: representative cruise
M_A   = 0.85;
rho_A = 0.380;      % kg/m^3 at ~35 kft
a_A   = 296.5;      % m/s
q_A   = 0.5 * rho_A * (M_A * a_A)^2;

% weights handling:
% Assumes geom.weights.mtow.v is in lbf.
% If already in N, remove the * 4.44822 conversion.
W_A = geom.weights.mtow.v * 4.44822;
if isfield(geom.weights, 'fuel') && isfield(geom.weights.fuel, 'v')
    W_A = (geom.weights.mtow.v - 0.5 * geom.weights.fuel.v) * 4.44822;
end

CL_A = W_A / (q_A * sref);

% Condition B: representative approach
q_B = 6000;   % Pa
W_B = geom.weights.mtow.v * 4.44822;
CL_B = W_B / (q_B * sref);

fprintf('Flight conditions:\n');
fprintf('  Condition A (cruise):   CL = %.4f\n', CL_A);
fprintf('  Condition B (approach): CL = %.4f\n\n', CL_B);

%% ---- Build panel geometry and strip counts ----------------------------
[xc_lerx, yc_lerx, zc_lerx] = buildPanels(lerx_secs);
[xc_main, yc_main, zc_main] = buildPanels(main_secs);
[xc_full, yc_full, zc_full] = buildPanels(full_secs);
[xc_elev, yc_elev, zc_elev] = buildPanels(elev_secs);

nv_lerx = stripCounts(lerx_secs, 12);
nv_main = stripCounts(main_secs, 60);
nv_full = stripCounts(full_secs, 72);
nv_elev = stripCounts(elev_secs, 20);

% Combined geometry blocks
xc_wt = [xc_main; xc_elev];
yc_wt = [yc_main; yc_elev];
zc_wt = [zc_main; zc_elev];
nv_wt = [nv_main; nv_elev];

xc_all = [xc_full; xc_elev];
yc_all = [yc_full; yc_elev];
zc_all = [zc_full; zc_elev];
nv_all = [nv_full; nv_elev];

plot_0412_planform('strips', nv_lerx, nv_main, nv_elev);

%% ======================================================================
%% Case 1 — Main wing only
%% ======================================================================
fprintf('============================================================\n');
fprintf('CASE 1: Main wing only\n');
fprintf('============================================================\n');

out1A = runIdrag(makeCfg(xc_main, yc_main, zc_main, nv_main, CL_A, sref, cavg, xcg));
out1B = runIdrag(makeCfg(xc_main, yc_main, zc_main, nv_main, CL_B, sref, cavg, xcg));

fprintf('  Condition A (CL=%.4f):  CDi = %.8f   e = %.4f\n', ...
    CL_A, out1A.cd_induced, oswald(CL_A, out1A.cd_induced, AR_geo));
fprintf('  Condition B (CL=%.4f):  CDi = %.8f   e = %.4f\n\n', ...
    CL_B, out1B.cd_induced, oswald(CL_B, out1B.cd_induced, AR_geo));

%% ======================================================================
%% Case 2 — Blended LERX + main wing
%% ======================================================================
fprintf('============================================================\n');
fprintf('CASE 2: Blended LERX + main wing (single continuous surface)\n');
fprintf('============================================================\n');

out2A = runIdrag(makeCfg(xc_full, yc_full, zc_full, nv_full, CL_A, sref, cavg, xcg));
out2B = runIdrag(makeCfg(xc_full, yc_full, zc_full, nv_full, CL_B, sref, cavg, xcg));

fprintf('  Condition A (CL=%.4f):  CDi = %.8f   e = %.4f   dCDi(LERX) = %+.8f\n', ...
    CL_A, out2A.cd_induced, oswald(CL_A, out2A.cd_induced, AR_geo), ...
    out2A.cd_induced - out1A.cd_induced);
fprintf('  Condition B (CL=%.4f):  CDi = %.8f   e = %.4f   dCDi(LERX) = %+.8f\n\n', ...
    CL_B, out2B.cd_induced, oswald(CL_B, out2B.cd_induced, AR_geo), ...
    out2B.cd_induced - out1B.cd_induced);

%% ======================================================================
%% Case 3 — Main wing + horizontal tail
%% ======================================================================
fprintf('============================================================\n');
fprintf('CASE 3: Main wing + horizontal tail\n');
fprintf('============================================================\n');

out3A = runIdrag(makeCfg(xc_wt, yc_wt, zc_wt, nv_wt, CL_A, sref, cavg, xcg));
out3B = runIdrag(makeCfg(xc_wt, yc_wt, zc_wt, nv_wt, CL_B, sref, cavg, xcg));

fprintf('  Condition A (CL=%.4f):  CDi = %.8f   e = %.4f   dCDi(tail) = %+.8f\n', ...
    CL_A, out3A.cd_induced, oswald(CL_A, out3A.cd_induced, AR_geo), ...
    out3A.cd_induced - out1A.cd_induced);
fprintf('  Condition B (CL=%.4f):  CDi = %.8f   e = %.4f   dCDi(tail) = %+.8f\n\n', ...
    CL_B, out3B.cd_induced, oswald(CL_B, out3B.cd_induced, AR_geo), ...
    out3B.cd_induced - out1B.cd_induced);

%% ======================================================================
%% Case 4 — Blended LERX + main wing + horizontal tail
%% ======================================================================
fprintf('============================================================\n');
fprintf('CASE 4: Blended LERX + main wing + horizontal tail\n');
fprintf('============================================================\n');

out4A = runIdrag(makeCfg(xc_all, yc_all, zc_all, nv_all, CL_A, sref, cavg, xcg));
out4B = runIdrag(makeCfg(xc_all, yc_all, zc_all, nv_all, CL_B, sref, cavg, xcg));

fprintf('  Condition A (CL=%.4f):  CDi = %.8f   e = %.4f\n', ...
    CL_A, out4A.cd_induced, oswald(CL_A, out4A.cd_induced, AR_geo));
fprintf('  Condition B (CL=%.4f):  CDi = %.8f   e = %.4f\n\n', ...
    CL_B, out4B.cd_induced, oswald(CL_B, out4B.cd_induced, AR_geo));

%% ---- Summary table ----------------------------------------------------
fprintf('\n%s\n', repmat('=',1,76));
fprintf('%-34s  %4s  %6s  %10s  %10s\n', 'Configuration', 'Cond', 'CL', 'CDi', 'e_oswald');
fprintf('%s\n', repmat('-',1,76));

rows = { ...
    'Wing only',                     'A', CL_A, out1A.cd_induced; ...
    'Wing only',                     'B', CL_B, out1B.cd_induced; ...
    'Blended LERX + wing',           'A', CL_A, out2A.cd_induced; ...
    'Blended LERX + wing',           'B', CL_B, out2B.cd_induced; ...
    'Wing + H-tail',                 'A', CL_A, out3A.cd_induced; ...
    'Wing + H-tail',                 'B', CL_B, out3B.cd_induced; ...
    'Blended LERX + wing + H-tail',  'A', CL_A, out4A.cd_induced; ...
    'Blended LERX + wing + H-tail',  'B', CL_B, out4B.cd_induced  ...
};

for k = 1:size(rows,1)
    cl  = rows{k,3};
    cdi = rows{k,4};
    fprintf('%-34s  %4s  %6.4f  %10.8f  %10.4f\n', ...
        rows{k,1}, rows{k,2}, cl, cdi, oswald(cl, cdi, AR_geo));
end
fprintf('%s\n', repmat('=',1,76));

%% ======================================================================
%% Local helper functions
%% ======================================================================

function [xc, yc, zc] = buildPanels(secs)
    % Converts N-section table [le_x, le_y, chord] into (N-1) panel arrays
    % with corner order [root-LE, tip-LE, tip-TE, root-TE].
    np = size(secs,1) - 1;
    xc = zeros(np,4);
    yc = zeros(np,4);
    zc = zeros(np,4);

    for k = 1:np
        r = secs(k,:);
        t = secs(k+1,:);

        xc(k,:) = [r(1), t(1), t(1)+t(3), r(1)+r(3)];
        yc(k,:) = [r(2), t(2), t(2),      r(2)];
        zc(k,:) = [0,    0,    0,         0];
    end
end

function nv = stripCounts(secs, n_total)
    % Distribute total vortex strips proportionally to panel span.
    % Minimum 3 strips per panel.
    dy = abs(diff(secs(:,2)));
    nv = max(3, round(n_total * dy(:) / sum(dy)));
end

function e = oswald(CL, CDi, AR)
    e = CL.^2 ./ (pi * AR .* CDi);
end

function cfg = makeCfg(xc, yc, zc, nv, CL, sref, cavg, xcg)
    np               = size(xc,1);
    cfg.input_mode   = 0;
    cfg.sym_flag     = 1;
    cfg.cl_design    = CL;
    cfg.cm_flag      = 0;
    cfg.cm_design    = 0.0;
    cfg.xcg          = xcg;
    cfg.cp           = 0.25;
    cfg.sref         = sref;
    cfg.cavg         = cavg;
    cfg.npanels      = np;
    cfg.xc           = xc;
    cfg.yc           = yc;
    cfg.zc           = zc;
    cfg.nvortices    = nv;
    cfg.spacing_flag = repmat(3, np, 1);   % cosine-compressed spacing
    cfg.load_flag    = 1;
    cfg.loads        = [];
end