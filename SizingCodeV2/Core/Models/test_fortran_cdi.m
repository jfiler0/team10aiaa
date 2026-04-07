%% test_fortran_cdi.m
% Tests fortran_cdi using a rectangular unswept wing where the answer
% is well established:
%   AR = 6,  b = 6m,  c = 1m,  e ≈ 0.90-0.95  (classical VLM result)

clear; clc;

b_semi = 3.0;
c      = 1.0;
S_ref  = 2 * b_semi * c;
b_full = 2 * b_semi;
AR     = b_full^2 / S_ref;   % = 6.0

fprintf('=== Rectangular Wing Test ===\n');
fprintf('AR=%.1f  b=%.1f m  c=%.1f m  S=%.1f m^2\n\n', AR, b_full, c, S_ref);
fprintf('Analytical reference:\n');
fprintf('  CDi (e=1.00): %.6f  [elliptic]\n',   0.5^2/(pi*AR*1.00));
fprintf('  CDi (e=0.92): %.6f  [rectangular]\n\n', 0.5^2/(pi*AR*0.92));

% ---- Build cfg directly — no geom struct, no fortran_cdi wrapper --------
% This isolates runIdrag from everything else
cfg              = struct();
cfg.input_mode   = 0;
cfg.sym_flag     = 1;
cfg.cl_design    = 0.5;
cfg.cm_flag      = 0;
cfg.cm_design    = 0.0;
cfg.xcg          = 5.0;
cfg.cp           = 0.25;
cfg.sref         = S_ref;       % 6.0
cfg.cavg         = c;           % 1.0  → bref = sref/cavg = 6.0 = b_full  ✓
cfg.npanels      = 1;
cfg.xc           = [0, 0, c, c];        % root-LE, tip-LE, tip-TE, root-TE
cfg.yc           = [0, b_semi, b_semi, 0];
cfg.zc           = [0, 0, 0, 0];
cfg.nvortices    = 40;
cfg.spacing_flag = 3;
cfg.load_flag    = 1;
cfg.loads        = [];

fprintf('bref = sref/cavg = %.4f  (should equal b_full=%.4f)\n\n', ...
    cfg.sref/cfg.cavg, b_full);

% ---- nvortices convergence ---------------------------------------------
fprintf('--- nvortices convergence (CL=0.5) ---\n');
fprintf('  nv     CDi         e_oswald\n');
for nv = [10, 20, 40, 80, 160]
    cfg.nvortices = nv * ones(1,1);
    out = runIdrag(cfg);
    CDi = abs(out.cd_induced);
    e   = 0.5^2 / (pi * AR * CDi);
    fprintf('  %-4d   %.6f    %.4f\n', nv, CDi, e);
end

% ---- CL sweep at nv=40 --------------------------------------------------
cfg.nvortices = 40;
fprintf('\n--- CL sweep (nv=40) ---\n');
fprintf('  CL      CDi         e_oswald\n');
for CL = [0.1, 0.2, 0.3, 0.4, 0.5]
    cfg.cl_design = CL;
    out = runIdrag(cfg);
    CDi = abs(out.cd_induced);
    e   = CL^2 / (pi * AR * CDi);
    fprintf('  %.2f    %.6f    %.4f\n', CL, CDi, e);
end

fprintf('\nPass: e constant ~0.90-0.95, converges with increasing nv\n');