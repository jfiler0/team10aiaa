%% idrag_example_0412.m
% Induced-drag analysis for the 0412_Optimization jet fighter using
% Blackwell's nonplanar VLM solver (runIdrag.m / NASA SP-405).
%
% The wing leading-edge geometry breaks sharply at section 1 (y=2.172 m):
%   Sections 0-1:  LE sweep = 74.4 deg  — LERX
%   Sections 1-6:  LE sweep = 35.2 deg  — main wing
%
% LERX operates in vortex-lift regime at high CL; VLM assumes attached
% flow. Including the LERX panel will overstate its linear lift at
% approach but is still useful to quantify the induced drag increment.
%
% Four cases run at two flight conditions each:
%   Condition A — subsonic cruise:  M=0.85, 35 kft, CL ≈ 0.31
%   Condition B — approach:         ~190 kt SL,      CL ≈ 0.72
%
%   Case 1: Main wing only          (sections 1-6, no LERX)
%   Case 2: LERX + main wing        (sections 0-6, full planform)
%   Case 3: Main wing + H-tail      (sections 1-6 + elevator panels)
%   Case 4: LERX + wing + H-tail    (all surfaces)

%% ---- Geometry from 0412_Optimization JSON ----------------------------

% LERX spanwise sections: [le_x (m), le_y (m), chord (m)]
% LE sweep section 0->1: arctan(4.270/1.195) = 74.4 deg
lerx_secs = [ ...
    3.0452,  0.9772, 10.370; ...   % section 0 — fuselage root
    7.3152,  2.1720,  6.100];      % section 1 — LERX/wing junction

% Main wing spanwise sections: [le_x (m), le_y (m), chord (m)]
% LE sweep sections 1->6: 35.2 deg throughout
main_secs = [ ...
    7.3152,  2.1720,  6.100; ...   % section 1 — LERX/wing junction (shared)
    7.6886,  2.7016,  5.640; ...   % section 2
    9.1821,  4.8198,  3.800; ...   % section 3
    9.5555,  5.3494,  3.340; ...   % section 4
   10.6756,  6.9380,  1.960; ...   % section 5
   11.0490,  7.4676,  1.500];      % section 6 — tip

% Elevator (horizontal tail) spanwise sections: [le_x (m), le_y (m), chord (m)]
elev_secs = [ ...
   12.6492,  1.0000,  2.5908; ...  % section 0 — root
   12.7646,  1.2088,  2.4754; ...  % section 1 — hinge break
   13.8037,  3.0884,  1.4363];     % section 2 — tip

% Reference quantities
sref   = 59.925;  % m^2   ref_area (both semi-spans)
cavg   = 5.5388;  % m     wing.average_chord
b_full = 14.935;  % m     wing.span tip-to-tip
AR_geo = b_full^2 / sref;   % 3.722  (b^2/S — used for Oswald e)
%  Note: wing.AR in JSON = 2.70 is b/c_avg, not b^2/S. Do not use for e.
xcg    =  8.719;  % m     approximate aerodynamic centre (wing.x_cp)

%% ---- Flight conditions ------------------------------------------------
% Condition A: subsonic cruise
%   M=0.85, 35 kft: rho=0.380 kg/m^3, a=296.5 m/s
%   q = 0.5*0.380*(0.85*296.5)^2 = 12,066 Pa
%   W_cruise = MTOW - 0.5*W_fuel = 257,996 - 31,796 = 226,200 N
CL_A = 226200 / (12066 * sref);   % ≈ 0.31

% Condition B: approach
%   ~190 kt SL: q ≈ 6,000 Pa, W = MTOW (worst-case, no fuel burn credit)
CL_B = 257996 / (6000  * sref);   % ≈ 0.72

fprintf('Flight conditions:\n');
fprintf('  Condition A (cruise):   CL = %.4f  (M=0.85, 35 kft)\n', CL_A);
fprintf('  Condition B (approach): CL = %.4f  (~190 kt SL)\n\n',    CL_B);

%% ---- Helper: panel corner builder ------------------------------------
% Converts N-section table [le_x, le_y, chord] into (N-1) panel arrays.
% Column order: [root-LE, tip-LE, tip-TE, root-TE].  z = 0 (planar).
function [xc, yc, zc] = buildPanels(secs)
    np = size(secs,1) - 1;
    xc = zeros(np,4);
    yc = zeros(np,4);
    zc = zeros(np,4);
    for k = 1:np
        r = secs(k,:);
        t = secs(k+1,:);
        xc(k,:) = [r(1), t(1), t(1)+t(3), r(1)+r(3)];
        yc(k,:) = [r(2), t(2), t(2),       r(2)     ];
    end
end

%% ---- Helper: strip count distribution --------------------------------
% Distribute n_total vortex strips proportionally to each panel's Dy.
% Minimum 3 per panel.
function nv = stripCounts(secs, n_total)
    dy = abs(diff(secs(:,2)));
    nv = max(3, round(n_total * dy(:) / sum(dy)));
end

%% ---- Helper: Oswald efficiency ---------------------------------------
oswald = @(CL, CDi) CL.^2 ./ (pi * AR_geo .* CDi);

%% ---- Helper: cfg builder ---------------------------------------------
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
    cfg.spacing_flag = repmat(3, np, 1);   % cosine-compressed, all panels
    cfg.load_flag    = 1;
    cfg.loads        = [];
end

%% ---- Build panel geometry and strip counts ---------------------------
[xc_lerx, yc_lerx, zc_lerx] = buildPanels(lerx_secs);   % 1 panel
[xc_main, yc_main, zc_main] = buildPanels(main_secs);   % 5 panels
[xc_elev, yc_elev, zc_elev] = buildPanels(elev_secs);   % 2 panels

nv_lerx = stripCounts(lerx_secs, 12);   % LERX: smaller panel, coarser
nv_main = stripCounts(main_secs, 60);   % main wing: 60 total strips
nv_elev = stripCounts(elev_secs, 20);   % elevator:  20 total strips

% Combined geometry blocks for multi-surface cases
xc_full = [xc_lerx; xc_main];   yc_full = [yc_lerx; yc_main];   zc_full = [zc_lerx; zc_main];   nv_full = [nv_lerx; nv_main];
xc_wt   = [xc_main; xc_elev];   yc_wt   = [yc_main; yc_elev];   zc_wt   = [zc_main; zc_elev];   nv_wt   = [nv_main; nv_elev];
xc_all  = [xc_lerx; xc_main; xc_elev];
yc_all  = [yc_lerx; yc_main; yc_elev];
zc_all  = [zc_lerx; zc_main; zc_elev];
nv_all  = [nv_lerx; nv_main; nv_elev];

plot_0412_planform('strips', nv_lerx, nv_main, nv_elev)

%% ===================================================================
%% Case 1 — Main wing only  (sections 1-6, LERX excluded)
%% ===================================================================
fprintf('============================================================\n');
fprintf('CASE 1: Main wing only  (sections 1-6, no LERX)\n');
fprintf('============================================================\n');

out1A = runIdrag(makeCfg(xc_main, yc_main, zc_main, nv_main, CL_A, sref, cavg, xcg));
out1B = runIdrag(makeCfg(xc_main, yc_main, zc_main, nv_main, CL_B, sref, cavg, xcg));

fprintf('  Condition A (CL=%.4f):  CDi = %.8f   e = %.4f\n', CL_A, out1A.cd_induced, oswald(CL_A, out1A.cd_induced));
fprintf('  Condition B (CL=%.4f):  CDi = %.8f   e = %.4f\n\n', CL_B, out1B.cd_induced, oswald(CL_B, out1B.cd_induced));

%% ===================================================================
%% Case 2 — LERX + main wing  (sections 0-6, full planform)
%% ===================================================================
fprintf('============================================================\n');
fprintf('CASE 2: LERX + main wing  (sections 0-6)\n');
fprintf('  NOTE: VLM assumes attached flow. LERX CDi increment will\n');
fprintf('  be overstated at Condition B (high CL, vortex-lift regime).\n');
fprintf('============================================================\n');

out2A = runIdrag(makeCfg(xc_full, yc_full, zc_full, nv_full, CL_A, sref, cavg, xcg));
out2B = runIdrag(makeCfg(xc_full, yc_full, zc_full, nv_full, CL_B, sref, cavg, xcg));

fprintf('  Condition A (CL=%.4f):  CDi = %.8f   e = %.4f   dCDi(LERX) = %+.8f\n', ...
    CL_A, out2A.cd_induced, oswald(CL_A, out2A.cd_induced), out2A.cd_induced - out1A.cd_induced);
fprintf('  Condition B (CL=%.4f):  CDi = %.8f   e = %.4f   dCDi(LERX) = %+.8f\n\n', ...
    CL_B, out2B.cd_induced, oswald(CL_B, out2B.cd_induced), out2B.cd_induced - out1B.cd_induced);

%% ===================================================================
%% Case 3 — Main wing + horizontal tail  (no LERX)
%% ===================================================================
fprintf('============================================================\n');
fprintf('CASE 3: Main wing + horizontal tail  (no LERX)\n');
fprintf('============================================================\n');

out3A = runIdrag(makeCfg(xc_wt, yc_wt, zc_wt, nv_wt, CL_A, sref, cavg, xcg));
out3B = runIdrag(makeCfg(xc_wt, yc_wt, zc_wt, nv_wt, CL_B, sref, cavg, xcg));

fprintf('  Condition A (CL=%.4f):  CDi = %.8f   e = %.4f   dCDi(tail) = %+.8f\n', ...
    CL_A, out3A.cd_induced, oswald(CL_A, out3A.cd_induced), out3A.cd_induced - out1A.cd_induced);
fprintf('  Condition B (CL=%.4f):  CDi = %.8f   e = %.4f   dCDi(tail) = %+.8f\n\n', ...
    CL_B, out3B.cd_induced, oswald(CL_B, out3B.cd_induced), out3B.cd_induced - out1B.cd_induced);

%% ===================================================================
%% Case 4 — LERX + main wing + horizontal tail  (all surfaces)
%% ===================================================================
fprintf('============================================================\n');
fprintf('CASE 4: LERX + main wing + horizontal tail  (all surfaces)\n');
fprintf('============================================================\n');

out4A = runIdrag(makeCfg(xc_all, yc_all, zc_all, nv_all, CL_A, sref, cavg, xcg));
out4B = runIdrag(makeCfg(xc_all, yc_all, zc_all, nv_all, CL_B, sref, cavg, xcg));

fprintf('  Condition A (CL=%.4f):  CDi = %.8f   e = %.4f\n', CL_A, out4A.cd_induced, oswald(CL_A, out4A.cd_induced));
fprintf('  Condition B (CL=%.4f):  CDi = %.8f   e = %.4f\n\n', CL_B, out4B.cd_induced, oswald(CL_B, out4B.cd_induced));

%% ---- Summary table ---------------------------------------------------
fprintf('\n%s\n', repmat('=',1,76));
fprintf('%-34s  %4s  %6s  %10s  %10s\n', 'Configuration', 'Cond', 'CL', 'CDi', 'e_oswald');
fprintf('%s\n', repmat('-',1,76));

rows = { ...
    'Wing only',              'A', CL_A, out1A.cd_induced; ...
    'Wing only',              'B', CL_B, out1B.cd_induced; ...
    'LERX + wing',            'A', CL_A, out2A.cd_induced; ...
    'LERX + wing',            'B', CL_B, out2B.cd_induced; ...
    'Wing + H-tail',          'A', CL_A, out3A.cd_induced; ...
    'Wing + H-tail',          'B', CL_B, out3B.cd_induced; ...
    'LERX + wing + H-tail',   'A', CL_A, out4A.cd_induced; ...
    'LERX + wing + H-tail',   'B', CL_B, out4B.cd_induced  ...
};

for k = 1:size(rows,1)
    cl  = rows{k,3};
    cdi = rows{k,4};
    fprintf('%-34s  %4s  %6.4f  %10.8f  %10.4f\n', ...
        rows{k,1}, rows{k,2}, cl, cdi, oswald(cl, cdi));
end
fprintf('%s\n', repmat('=',1,76));