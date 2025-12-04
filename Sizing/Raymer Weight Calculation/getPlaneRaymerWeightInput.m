function input = getPlaneRaymerWeightInput(plane)

% Input struct (metric units: m, m^2, N)
input = struct();

% -----------------------------
% Basic aircraft parameters
% -----------------------------
input.Wdg    = plane.MTOW;   % Design gross weight [N] ~ 15000 kg
input.Nz     = 1.3 * plane.g_limit;            % Ultimate load factor
input.Sw     = plane.S_wing;           % Wing area [m^2]
input.AR     = plane.AR;          % Wing aspect ratio
input.tc_root= 0.08;         % t/c at root
input.lambda = plane.tr;          % Wing taper
input.sweep  = plane.Lambda_LE;           % Wing sweep [deg]
input.Scsw   = (2/37)*plane.S_wing;            % Wing control-surface area [m^2]
input.K_dw   = 1.3;             % Wing design correction
input.K_vs   = 1;             % Wing structural factor

% Horizontal tail
input.Sht    = 0.3 * plane.S_wing;           % Horizontal tail area [m^2]
input.F_w    = 0.2;          % F_w/B_h factor
input.B_h    = 1.5;             % Horizontal tail span factor

% Vertical tail
input.Svt    = 0.18 * plane.S_wing;            % Vertical tail area [m^2]
input.K_rht  = 1.3;             % Correction factor
input.H_t    = 2; 
input.H_v    = 3; 
input.M      = 1;           % Mach factor for tail
input.L_t    = plane.L_fuselage / 2;            % Tail moment arm [m]
input.S_r    = 1;            % Additional area
input.A_vt   = 1.5;          % Vertical tail aspect ratio
input.lam_vt = 0.4;          % Vertical tail taper
input.sweep_vt = plane.Lambda_LE;         % Sweep [deg]

% Fuselage
input.L      = plane.L_fuselage;           % Length [m]
input.D      = plane.D;            % Diameter [m] 
input.W_param= 100;         % W parameter for fuselage (not clear what this is supposed to be so tuned for "reasonability)
input.K_dwf  = 1.3;             % Correction

% Landing gear
input.WNl    = 0.5 * plane.MTOW;   % Landing weight [N] (estimate since we don't have landing weight calculated at this point) ***
input.K_cb   = 1; 
input.K_tpg  = 1; 
input.Lm     = plane.wing_height;             % Main gear length [m]
input.Ln     = 0.8 * plane.wing_height;           % Nose gear length [m]
input.Nnw    = 2;             % Number of nose wheels

% Engines
input.Nen    = plane.num_engine;             % Number of engines
input.T      = plane.engine_T0AB;         % Total thrust [N] per engine ~ 77000 N  *** THESE NEED TO HAVE AN INPUT
input.Wen    = plane.engine_dry_weight;     % Engine weight [N]
input.Sfw    = plane.A_max;             % Firewall area [m^2]
input.K_vg   = 1;
input.Ld     = 0.1333 * plane.L_fuselage;             % Intake length [m]
input.Kd     = 0.0667 * plane.L_fuselage;
input.Ls     = 0.1 * plane.L_fuselage;           % Intake sub-length [m]
input.De     = plane.engine_diameter;             % Engine diameter [m]
input.Ltp    = 0.1333 * plane.L_fuselage;             % Tailpipe length [m]
input.Lsh    = 0.0667 * plane.L_fuselage;             % Engine cooling length [m]
input.Te     = 500;           % Starter pneumatic param

fuel_den = 0.8; % g/ml -> 1000ml/m3 * kg / 1000g -> kg/m3

% Fuel system

% fuel_vol = plane.internal_fuel_weight; % would be nice but we haven't actually calculated this
fuel_vol = 0.3 * plane.MTOW; % rough estimate ***

input.Vi     = (fuel_vol / 9.805)/fuel_den;             % Internal volume [m^3]
input.Vt     = 1.2 * input.Vi;             % Total fuel volume [m^3]
input.Vp     = input.Vt/1.5;             % External volume [m^3]
input.Nt     = 2;             % Number of tanks
input.SFC    = 0.242 * 60 / 1000;           % Specific fuel consumption

% Flight controls, instruments, crew   *** This needs more inputs
input.Mach   = 0.9;
input.Scs    = 5; 
input.Ns     = 4; % num flight control systems
input.Nc     = 1;  % num crew
input.Nu     = 3; % num hydralic units
input.K_vsh  = 1; 
input.K_mc   = 1; 
input.R_kva  = 50; % generator kva rating
input.Ngen   = 2; 
input.La     = 1; 
input.W_uav  = plane.W_F * 0.2; % Not all the avionics
input.Nci    = 1; % num cockpit insturments
input.Lec    = 1;

end