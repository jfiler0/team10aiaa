function input = getPlaneRaymerWeightInput(geom)

% Input struct (metric units: m, m^2, N)
input = struct();

% -----------------------------
% Basic aircraft parameters 
% -----------------------------
input.Wdg    = geom.weights.mtow.v;   % Design gross weight [N] ~ 15000 kg
input.Nz     = 1.3 * geom.input.g_limit.v;            % Ultimate load factor
input.Sw     = geom.wing.area.v;           % Wing area [m^2]
input.AR     = geom.wing.AR.v;          % Wing aspect ratio
input.tc_root= geom.wing.sections(1).tc.v;         % t/c at root
input.lambda = geom.wing.taper_ratio.v;          % Wing taper
input.sweep  = geom.wing.average_sweep.v;           % Wing sweep [deg]
input.Scsw   = (2/37)*geom.wing.area.v;            % Wing control-surface area [m^2]
input.K_dw   = 1.3;             % Wing design correction
input.K_vs   = 1;             % Wing structural factor

% Horizontal tail
input.Sht    = 0.3 * geom.wing.area.v;           % Horizontal tail area [m^2]
input.F_w    = 0.2;          % F_w/B_h factor
input.B_h    = 1.5;             % Horizontal tail span factor

% Vertical tail
input.Svt    = 0.18 * geom.wing.area.v;            % Vertical tail area [m^2]
input.K_rht  = 1.3;             % Correction factor
input.H_t    = 2; 
input.H_v    = 3; 
input.M      = 1;           % Mach factor for tail
input.L_t    = geom.fuselage.length.v / 2;            % Tail moment arm [m]
input.S_r    = 1;            % Additional area
input.A_vt   = 1.5;          % Vertical tail aspect ratio
input.lam_vt = 0.4;          % Vertical tail taper
input.sweep_vt = geom.wing.average_sweep.v;         % Sweep [deg]

% Fuselage
input.L      = geom.fuselage.length.v;           % Length [m]
input.D      = geom.fuselage.diameter.v;            % Diameter [m] 
input.W_param= 100;         % W parameter for fuselage (not clear what this is supposed to be so tuned for "reasonability)
input.K_dwf  = 1.3;             % Correction

% Landing gear
input.WNl    = 0.5 * geom.weights.mtow.v;   % Landing weight [N] (estimate since we don't have landing weight calculated at this point) ***
input.K_cb   = 1; 
input.K_tpg  = 1; 
input.Lm     = geom.wing_height.v;             % Main gear length [m]
input.Ln     = 0.8 * geom.wing_height.v;           % Nose gear length [m]
input.Nnw    = 2;             % Number of nose wheels

% Engines
input.Nen    = geom.prop.num_engine.v;             % Number of engines
input.T      = geom.prop.T0_AB.v;         % Total thrust [N] per engine ~ 77000 N  *** THESE NEED TO HAVE AN INPUT
input.Wen    = geom.prop.dry_weight.v;     % Engine weight [N]
input.Sfw    = geom.fuselage.max_area.v;             % Firewall area [m^2]
input.K_vg   = 1;
input.Ld     = 0.1333 * geom.fuselage.length.v;             % Intake length [m]
input.Kd     = 0.0667 * geom.fuselage.length.v;
input.Ls     = 0.1 * geom.fuselage.length.v;           % Intake sub-length [m]
input.De     = geom.prop.diam.v;             % Engine diameter [m]
input.Ltp    = 0.1333 * geom.fuselage.length.v;             % Tailpipe length [m]
input.Lsh    = 0.0667 * geom.fuselage.length.v;             % Engine cooling length [m]
input.Te     = 500;           % Starter pneumatic param

fuel_den = 0.8; % g/ml -> 1000ml/m3 * kg / 1000g -> kg/m3

% Fuel system

% fuel_vol = plane.internal_fuel_weight; % would be nice but we haven't actually calculated this
fuel_vol = 0.3 * geom.weights.mtow.v; % rough estimate ***

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
input.W_uav  = geom.weights.w_fixed.v * 0.2; % Not all the avionics
input.Nci    = 1; % num cockpit insturments
input.Lec    = 1;

end