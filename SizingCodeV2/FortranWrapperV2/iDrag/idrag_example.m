%% idrag_example.m
% Demonstrates calling the induced-drag solver through runIdrag.m
%
% The solver implements Blackwell's nonplanar vortex-lattice method
% (NASA SP-405) for multi-panel wings.
%
% Two cases are run:
%   1. Flat rectangular wing  (design mode, find optimal loading)
%   2. Same wing in analysis mode (feed back the elliptic load)

%% Case 1 — flat rectangular wing, design mode
% Find the minimum-induced-drag loading for CL = 0.5.

cfg1.input_mode   = 0;      % 0 = design (solver finds optimal loading)
cfg1.sym_flag     = 1;      % 1 = symmetric about xz-plane
cfg1.cl_design    = 0.5;    % target lift coefficient
cfg1.cm_flag      = 0;      % no pitching moment constraint
cfg1.cm_design    = 0.0;
cfg1.xcg          = 0.25;   % CG x-location (same units as xc)
cfg1.cp           = 0.25;   % centre-of-pressure as fraction of chord
cfg1.sref         = 1.0;    % reference area (ft^2 or m^2, consistent units)
cfg1.cavg         = 1.0;    % average chord
cfg1.npanels      = 1;      % one trapezoidal panel

% Panel corners — row order: [root-LE, tip-LE, tip-TE, root-TE]
b_half = 1.0;               % semi-span
c_root = 1.0;               % root chord
c_tip  = 1.0;               % tip  chord (rectangular => same as root)
sweep  = 0.0;               % leading-edge sweep offset (in chord units)
dihedral = 0.0;             % dihedral angle, radians

cfg1.xc = [0,         sweep,                  sweep + c_tip,  c_root];
cfg1.yc = [0,         b_half,                 b_half,         0     ];
cfg1.zc = [0, tan(dihedral)*b_half, tan(dihedral)*b_half,     0     ];

cfg1.nvortices    = 30;     % vortex strips across the semi-span
cfg1.spacing_flag = 3;      % 3 = end-compressed (cosine-like, most accurate)
cfg1.load_flag    = 1;      % loads are Cn*c/cavg values
cfg1.loads        = [];     % empty => design mode ignores this

out1 = runIdrag(cfg1);

fprintf('=== Case 1: Rectangular wing, CL=0.5 (design mode) ===\n');
fprintf('  cd_induced = %.8f\n\n', out1.cd_induced);


%% Case 2 — two-panel configuration (wing + winglet), design mode
% A simple swept wing with a vertical winglet panel.

cfg2.input_mode   = 0;
cfg2.sym_flag     = 1;
cfg2.cl_design    = 0.4;
cfg2.cm_flag      = 0;
cfg2.cm_design    = 0.0;
cfg2.xcg          = 0.3;
cfg2.cp           = 0.25;
cfg2.sref         = 2.0;
cfg2.cavg         = 1.0;
cfg2.npanels      = 2;

% Panel 1: swept main wing
b_half  = 1.5;
c_root  = 1.2;
c_tip   = 0.6;
sweep_x = 0.3;              % LE swept back by 0.3 chord-lengths at tip

% Panel 2: vertical winglet at the tip
wl_height = 0.3;            % winglet height
wl_chord  = 0.4;

% xc,yc,zc are npanels x 4
cfg2.xc = zeros(2, 4);
cfg2.yc = zeros(2, 4);
cfg2.zc = zeros(2, 4);

% Main wing panel
cfg2.xc(1,:) = [0,              sweep_x,              sweep_x + c_tip, c_root];
cfg2.yc(1,:) = [0,              b_half,               b_half,          0     ];
cfg2.zc(1,:) = [0,              0,                    0,               0     ];

% Winglet panel (rises vertically from wingtip)
cfg2.xc(2,:) = [sweep_x,        sweep_x,              sweep_x+wl_chord, sweep_x+wl_chord];
cfg2.yc(2,:) = [b_half,         b_half,               b_half,           b_half          ];
cfg2.zc(2,:) = [0,              wl_height,            wl_height,        0               ];

cfg2.nvortices    = [20; 10];   % 20 strips on wing, 10 on winglet
cfg2.spacing_flag = [3;  3 ];
cfg2.load_flag    = 1;
cfg2.loads        = [];

out2 = runIdrag(cfg2);

fprintf('=== Case 2: Swept wing + winglet, CL=0.4 (design mode) ===\n');
fprintf('  cd_induced = %.8f\n\n', out2.cd_induced);