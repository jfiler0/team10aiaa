matlabSetup();
clear getSetting queryAtmosphere

build_atmosphere_lookup(-100, 20000, 200)
naca2412 = foil_class("NACA2412", 0.8, false);

x0(1) = 3; % Root Chord
x0(2) = 0.5; % Tip Chord
x0(3) = 7; % Span
x0(4) = 35; % Sweep
x0(5) = 0; % XPOS
x0(6) = 0.5; % YPOS
x0(7) = 0.1; % ZPOS
x0(8) = -10; % XROT
x0(9) = 0; % YROT

% control_surfaces = [0.1 0.3 ; 0.6 0.8]; %[start_span / span, end_span/span]
control_surfaces = [0.1 0.5 ; 0.7 0.8];

right_wing = surface_class(x0, naca2412, control_surfaces, false);
left_wing = right_wing.mirror_me();

figure;
ax = axes;

V = [100 0 30];
W = [0 0 0];
h = 1000;
CG = [0 0 0];

flaps = 20;
aileron = 30;

[F_right, M_right] = right_wing.queryWing([flaps aileron], V, W, h, CG, ax);
[F_left, M_left] = left_wing.queryWing([flaps -aileron], V, W, h, CG, ax);

F_total = F_right + F_left
M_total = M_right + M_left