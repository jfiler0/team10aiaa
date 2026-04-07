%% idrag_example.m
% Demonstrates calling the induced-drag solver through runIdrag.m
%
% Two cases:
%   1. Flat rectangular wing (AR=6, known answer e≈0.92)
%   2. Actual aircraft cranked delta wing geometry

%% Case 1 — Rectangular wing, AR=6
% Known result: e converges to ~0.92 with sufficient vortices.
% Use this as a sanity check whenever the solver is rebuilt.

b_semi = 3.0;   % semi-span (m)
c      = 1.0;   % chord (m)
S_ref  = 2 * b_semi * c;   % = 6.0 m^2
AR     = (2*b_semi)^2 / S_ref;  % = 6.0

cfg1              = struct();
cfg1.input_mode   = 0;
cfg1.sym_flag     = 1;
cfg1.cl_design    = 0.5;
cfg1.cm_flag      = 0;
cfg1.cm_design    = 0.0;
cfg1.xcg          = 0.25;
cfg1.cp           = 0.25;
cfg1.sref         = S_ref;      % 6.0 m^2
cfg1.cavg         = c;          % 1.0 m  →  bref = sref/cavg = 6.0 = b_full
cfg1.npanels      = 1;
cfg1.xc           = [0,      0,      c,      c     ];   % root-LE tip-LE tip-TE root-TE
cfg1.yc           = [0,      b_semi, b_semi, 0     ];
cfg1.zc           = [0,      0,      0,      0     ];
cfg1.nvortices    = 160;    % high count for accuracy — see convergence below
cfg1.spacing_flag = 3;
cfg1.load_flag    = 1;
cfg1.loads        = [];

out1 = runIdrag(cfg1);
CDi1 = abs(out1.cd_induced);
e1   = 0.5^2 / (pi * AR * CDi1);

fprintf('=== Case 1: Rectangular wing AR=6, CL=0.5 ===\n');
fprintf('  CDi        = %.6f\n', CDi1);
fprintf('  e_oswald   = %.4f   (expect ~0.85-0.92 at nv=160)\n', e1);
fprintf('  CDi_ellipt = %.6f   (e=1 lower bound)\n\n', 0.5^2/(pi*AR));

% nvortices convergence
fprintf('  nv convergence:\n');
for nv = [10, 20, 40, 80, 160]
    cfg1.nvortices = nv;
    o = runIdrag(cfg1);
    e_nv = 0.5^2 / (pi * AR * abs(o.cd_induced));
    fprintf('    nv=%-4d  CDi=%.6f  e=%.4f\n', nv, abs(o.cd_induced), e_nv);
end


%% Case 2 — Actual aircraft cranked delta wing
% Sections from the sizing code (physical coordinates before y-shift):
%   sec0: y=1.000  LE=5.522  TE=12.522  chord=7.000 m  (LERX root)
%   sec1: y=2.000  LE=8.100  TE=12.522  chord=4.422 m  (wing root)
%   sec6: y=5.417  LE=9.544  TE=10.163  chord=0.619 m  (wing tip)
%
% y is shifted so root=0 before passing to idrag.
% cavg is set consistently: cavg = sref / (2*b_semi_exposed)

S_ref_ac = 28.646;   % m^2  aircraft reference area
y_root   = 1.000;    % innermost section y (m) — subtracted as shift

% Sections [LE_x, y, TE_x] after y-shift
sec0_le = [5.5221,  1.000 - y_root,  0.0];  sec0_te = [12.5221, 1.000 - y_root, 0.0];
sec1_le = [8.1000,  2.000 - y_root,  0.0];  sec1_te = [12.5221, 2.000 - y_root, 0.0];
sec6_le = [9.5439,  5.4165 - y_root, 0.0];  sec6_te = [10.1630, 5.4165 - y_root, 0.0];

b_semi_ac = 5.4165 - y_root;   % = 4.4165 m
cavg_ac   = S_ref_ac / (2 * b_semi_ac);   % consistent with bref

% Panel 1: root (sec0) → break (sec1)
% Panel 2: break (sec1) → tip (sec6), forward-swept TE clipped to zero chord
% Chord goes to zero somewhere between sec1 and sec6 — find clip point
chord1 = sec1_te(1) - sec1_le(1);   % 4.422 m
chord6 = sec6_te(1) - sec6_le(1);   % 0.619 m  (positive — no clip needed)

cfg2              = struct();
cfg2.input_mode   = 0;
cfg2.sym_flag     = 1;
cfg2.cl_design    = 0.5;
cfg2.cm_flag      = 0;
cfg2.cm_design    = 0.0;
cfg2.xcg          = (5.5221 + 12.5221) / 2;   % approximate mid-chord at root
cfg2.cp           = 0.25;
cfg2.sref         = S_ref_ac;
cfg2.cavg         = cavg_ac;
cfg2.npanels      = 2;

cfg2.xc = zeros(2,4);
cfg2.yc = zeros(2,4);
cfg2.zc = zeros(2,4);

% Panel 1: sec0 -> sec1  [root-LE, tip-LE, tip-TE, root-TE]
cfg2.xc(1,:) = [sec0_le(1), sec1_le(1), sec1_te(1), sec0_te(1)];
cfg2.yc(1,:) = [sec0_le(2), sec1_le(2), sec1_te(2), sec0_te(2)];
cfg2.zc(1,:) = [0, 0, 0, 0];

% Panel 2: sec1 -> sec6
cfg2.xc(2,:) = [sec1_le(1), sec6_le(1), sec6_te(1), sec1_te(1)];
cfg2.yc(2,:) = [sec1_le(2), sec6_le(2), sec6_te(2), sec1_te(2)];
cfg2.zc(2,:) = [0, 0, 0, 0];

cfg2.nvortices    = [160; 160];
cfg2.spacing_flag = [3;   3  ];
cfg2.load_flag    = 1;
cfg2.loads        = [];

fprintf('=== Case 2: Aircraft cranked delta, CL=0.5 ===\n');
fprintf('  sref=%.3f m^2  cavg=%.4f m  b_semi=%.4f m\n', ...
    S_ref_ac, cavg_ac, b_semi_ac);
fprintf('  bref = sref/cavg = %.4f  (should = 2*b_semi = %.4f)\n', ...
    S_ref_ac/cavg_ac, 2*b_semi_ac);

out2 = runIdrag(cfg2);
CDi2 = abs(out2.cd_induced);
AR_ac = (2*b_semi_ac)^2 / S_ref_ac;
e2   = 0.5^2 / (pi * AR_ac * CDi2);

fprintf('  AR         = %.4f\n', AR_ac);
fprintf('  CDi        = %.6f\n', CDi2);
fprintf('  e_oswald   = %.4f\n', e2);
fprintf('  CDi_ellipt = %.6f   (e=1 lower bound)\n\n', 0.5^2/(pi*AR_ac));

% CL sweep
fprintf('  CL sweep:\n');
for CL = [0.1, 0.2, 0.3, 0.4, 0.5]
    cfg2.cl_design = CL;
    o   = runIdrag(cfg2);
    CDi = abs(o.cd_induced);
    e   = CL^2 / (pi * AR_ac * CDi);
    fprintf('    CL=%.2f  CDi=%.6f  e=%.4f\n', CL, CDi, e);
end