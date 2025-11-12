%% Build atmo table -> Does not need to always be run as it is saved in atmosphere_lookup.mat
% build_atmosphere_lookup(-5000, ft2m(120000), 500);

%% Initial Setup
matlabSetup(); % Clears and sets plot defaults

%% Define Loadouts
% When applied to a plane they set extra payload weight, can add to potential fuel volume (if a tank), and add to CD0
empty = buildLoadout([]);

%% Set Geometry Inputs - All FA-18E Super Hornet
fixed_input.L_fuselage = 1.6; % m -> FA18 fuselage length
fixed_input.A_max = 0.2; % m2 -> trying to get the right FA18 wave drag. This was tuned to get M1.6
fixed_input.g_limit = 5; % G -> FA18 limit
fixed_input.max_alpha = 12; % deg -> Guess
fixed_input.type = "Homebuilt-composite"; % Which empty weight coefficents to take from Raymer. In weight_regression_lookup

geom.empty_weight = lb2N(20); % Gotta be Newtons m8. This drives MTOW using historical relations which eventually informs the amount of fuel which can be carried
geom.Lambda_LE = 8; % deg - Leading Edge Sweep
geom.c_r = 0.36; % m - Root Chord
geom.c_t = 0.213; % m - Tip Chord
geom.span = 2.283; % m - Wing Span
geom.W_F = lb2N(10); % N - Fixed Weight (Avionics)
geom.engine = "H20"; % engine: A string code which you can see in engine_lookup.xslx. More info in engine_getData

%% Make the icarus object
%                                     empty_weight,       Lambda_LE,     c_r,       c_t,    span,    num_engine,      engine,      W_F
icarus = planeObj(fixed_input, "ICARUS", geom.empty_weight, geom.Lambda_LE, geom.c_r, geom.c_t, geom.span,    1,         geom.engine, geom.W_F);
icarus = icarus.applyLoadout(empty); % Just two sidewinders

%% Define Missions
% The flightSegment2 and planeObj classes work together to calculate fuel burned from missions with flightSegment2 requiring the aerodynamic
% data driven by planeObj. And planeObj getting fuel burn info from flightSegment
% ferry = [...
%     flightSegment2("TAKEOFF") 
%     flightSegment2("CLIMB", 0.7) 
%     flightSegment2("CRUISE", 0.6, NaN, nm2m(1000)) % 800 nm flight
%     flightSegment2("LOITER", NaN, 10000, 20) % 20 min loiter
%     flightSegment2("COMBAT", 0.8, 1000, [8 0]) % 8 minutes of combat, deploy payload***
%     flightSegment2("CRUISE", 0.6, NaN, nm2m(1000)) % 800 nm flight
%     flightSegment2("LANDING") ];
% air2ground = [...
%     flightSegment2("TAKEOFF") 
%     flightSegment2("CLIMB", 0.85) % Check this mach
%     flightSegment2("CRUISE", 0.85, ft2m(30000), nm2m(700)) % 700 nm flight
%     flightSegment2("LANDING") % Saying this is decent
%     flightSegment2("LOITER", NaN, ft2m(10000), 10) % 10 min loiter
%     flightSegment2("CLIMB", 0.85) % Check this mach
%     flightSegment2("CRUISE", 0.85, NaN, nm2m(50)) % Penetrate
%     flightSegment2("COMBAT", 0.85, 1000, [30/60 0]) % quick combat ***
%     flightSegment2("CLIMB", 0.85) % Check this mach
%     flightSegment2("CRUISE", 0.85, ft2m(30000), nm2m(700)) % 700 nm flight
%     flightSegment2("LOITER", NaN, ft2m(10000), 20) % 20 min loiter
%     flightSegment2("LANDING") ];

%% Run anaylisis comparisons

fprintf("The ICARUS has a unit cost of %.2f million dollars and a stall speed of %.2f kt (lands at %.2f kt) for MTOW", icarus.calcUnitCost(), ms2kt( icarus.calcStallSpeed(0, icarus.MTOW) ), ms2kt( icarus.calcLandingSpeed(0, icarus.MTOW) ) );

[climbRate, climbAngle, climbSpeed] = icarus.calcMaxClimbRate(0, icarus.MTOW, 0);
fprintf("\nSealevel max climb rate = %.3f kft/min with a climb angle of %.2f deg at a speed of %.3f m/s", m2ft(climbRate) * 60 / 1000, climbAngle, climbSpeed);

[turn_rate, n] = icarus.getMaxTurn(0, 0.5, icarus.MTOW);
fprintf("\nSealevel, Mach 0.5 max turn rate = %.2f deg/s at a load factor of %.2f", turn_rate, n)

fprintf("\nICARUS spot factor = %.3f (Projected area of %.3f m2)", icarus.calcSpotFactor(0.3193), icarus.calcFoldedWingProjection(0.3193) )

% [maxAlt, maxAltMach, excessPower] = icarus.calcMaxAlt(icarus.MTOW, 0);
% fprintf("\nThe icarus has a service ceiling of %.2f kf (does Mach %.2f at its ceiling with a CL of %.3f).", m2ft(maxAlt)/1000, maxAltMach, icarus.calcTrimCL(maxAlt, maxAltMach, icarus.MTOW))

[maxMach, maxMachAlt] = icarus.calcMaxMach(icarus.MTOW, 0);
fprintf("\nICARUS has a maximum mach number of %.3f which it reaches at %.2f kf", maxMach, m2ft(maxMachAlt)/1000)

[h_maxR, M_maxR, V_maxR, L2D_maxR] = icarus.findMaxRangeState(icarus.MTOW);
[h_maxE, M_maxE, V_maxE, LD_maxE] = icarus.findMaxEnduranceState(icarus.MTOW);
fprintf("\nMax range altitude = %.2f kf at Mach %.2f with a speed of %.2f m/s and L^(1/2)/D ratio of %.2f", m2ft(h_maxR)/1000, M_maxR, V_maxR, L2D_maxR);
fprintf("\nMax endurance altitude = %.2f kf at Mach %.2f with a speed of %.2f m/s and L/D ratio of %.2f", m2ft(h_maxE)/1000, M_maxE, V_maxE, LD_maxE);

% icarus.buildPlots(icarus.MTOW, 50)