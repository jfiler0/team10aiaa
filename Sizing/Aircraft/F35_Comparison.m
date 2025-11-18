%% GOAL: Compare calculated F18E Super Hornet specs calculated from is general geometry, engine, and weight to the detailed performance specs seen in the NATOPS to check confidence in analyisis method
    % Note on the structure of the code here: Note that none of the functions called in this script have hard number embedded in them
    % anymore. The analysis should work just the same for a 747, F16, UAS, or pretty much anything with a jet engine and wings. You can
    % adjust the main geometry inputs to control wing & fuselage dimensions. You can add additional stores and engines by adding rows to the
    % two lookup tables engine_lookup and stores_lookup. EVERY function takes input and gives outputs in metric with weights always being in
    % Newtons instread of kg.

    % This script demonsrates most of the code functionaity (besides optimizaton) and sets geoemtry for the F18. You can use it a reference
    % on how to build planeObj variables and get useful analysis outputs.
    
%% Build atmo table -> Does not need to always be run as it is saved in atmosphere_lookup.mat
% build_atmosphere_lookup(-5000, ft2m(120000), 500);

%% Initial Setup
matlabSetup(); % Clears and sets plot defaults

%% Set Geometry Inputs - All F-35 Super Hornet
fixed_input.L_fuselage = 15.7; % m -> F35 fuselage length
fixed_input.A_max = 4.5; %NOCHANGE m2 -> trying to get the right FA18 wave drag. This was tuned to get M1.6
fixed_input.g_limit = 7.5; % G -> F35 limit
fixed_input.max_alpha = 50; % deg -> Guess
fixed_input.type = "Jet fighter"; % Which empty weight coefficents to take from Raymer. In weight_regression_lookup
fixed_input.KLOC = 10000; % in kilo-lines of code

geom.empty_weight = lb2N(34800); % Gotta be Newtons m8. This drives MTOW using historical relations which eventually informs the amount of fuel which can be carried
geom.Lambda_LE = 34.13; %FROM F-35A deg - Leading Edge Sweep
geom.c_r = ft2m(21.19); %F-35A m - Root Chord
geom.c_t = ft2m(5.15); %F-35A m - Tip Chordf1
geom.span = 13.11; % m - Wing Span
geom.W_F = lb2N(2000); % N - Fixed Weight (Avionics)
geom.engine = "F135"; % engine: A string code which you can see in engine_lookup.xslx. More info in engine_getData

%% Define Loadouts
% When applied to a plane they set extra payload weight, can add to potential fuel volume (if a tank), and add to CD0
clean_loadout = buildLoadout(["AIM-9X", "AIM-9X"]);
strike_loadout = buildLoadout(["AIM-9X", "FPU-12", "AIM-120", "AIM-120", "FPU-12", "AIM-9X"]);

%% Make the f18 object
%                                     empty_weight,       Lambda_LE,     c_r,       c_t,    span,    num_engine,      engine,      W_F
f35 = planeObj(fixed_input, "FA35", geom.empty_weight, geom.Lambda_LE, geom.c_r, geom.c_t, geom.span,    1,         geom.engine, geom.W_F);
f35 = f35.applyLoadout(clean_loadout); % Just two sidewinders

%% Define Missions
% The flightSegment2 and planeObj classes work together to calculate fuel burned from missions with flightSegment2 requiring the aerodynamic
% data driven by planeObj. And planeObj getting fuel burn info from flightSegment
ferry = mission( [...
    flightSegment2("TAKEOFF") 
    % flightSegment2("CLIMB", 0.7) 
    % flightSegment2("CRUISE", 0.6, NaN, nm2m(400)) % 800 nm flight
    % flightSegment2("LOITER", NaN, 10000, 20) % 20 min loiter
    % flightSegment2("COMBAT", 0.8, 1000, [8 0.5]) % 8 minutes of combat, deploy 50% of payload
    % flightSegment2("CRUISE", 0.6, NaN, nm2m(400)) % 800 nm flight
    flightSegment2("LANDING") ] , ...
    ...
    clean_loadout);

[fuel_burned, W_End] = ferry.solveMission(f35);
fprintf("\nFERRY MISSION: fuel_burned = %.2f lb, Ending Weight = %.2f lb", N2lb(fuel_burned), N2lb(W_End) )

air2ground = mission( [...
    flightSegment2("TAKEOFF") 
    flightSegment2("CLIMB", 0.85) % Check this mach
    flightSegment2("CRUISE", 0.85, ft2m(30000), nm2m(400)) % 700 nm flight
    flightSegment2("LANDING") % Saying this is decent
    flightSegment2("LOITER", NaN, ft2m(10000), 10) % 10 min loiter
    flightSegment2("CLIMB", 0.85) % Check this mach
    flightSegment2("CRUISE", 0.85, NaN, nm2m(50)) % Penetrate
    flightSegment2("COMBAT", 0.85, 1000, [30/60 0]) % quick combat ***
    flightSegment2("CLIMB", 0.85) % Check this mach
    flightSegment2("CRUISE", 0.85, ft2m(30000), nm2m(400)) % 700 nm flight
    flightSegment2("LOITER", NaN, ft2m(10000), 20) % 20 min loiter
    flightSegment2("LANDING") ] , ...
    ...
    strike_loadout);

[fuel_burned, W_End] = air2ground.solveMission(f35);
fprintf("\nSTRIKE MISSION: fuel_burned = %.2f lb, Ending Weight = %.2f lb", N2lb(fuel_burned), N2lb(W_End) )

%% Run anaylisis comparisons

fprintf("The F35 has a unit cost of %.2f million dollars and a stall speed of %.2f kt (lands at %.2f kt) for MTOW", f35.calcUnitCost(), ms2kt( f35.calcStallSpeed(0, f35.MTOW) ), ms2kt( f35.calcLandingSpeed(0, f35.MTOW) ) );

[climbRate, climbAngle, climbSpeed] = f35.calcMaxClimbRate(0, f35.MTOW, 1);
fprintf("\nSealevel max climb rate = %.3f kft/min with a climb angle of %.2f deg at a speed of %.3f m/s", m2ft(climbRate) * 60 / 1000, climbAngle, climbSpeed);

[turn_rate, n] = f35.getMaxTurn(0, 0.5, f35.MTOW);
fprintf("\nSealevel, Mach 0.5 max turn rate = %.2f deg/s at a load factor of %.2f", turn_rate, n)

fprintf("\nF35 spot factor = %.3f (Projected area of %.3f m2)", f35.calcSpotFactor(0.3193), f35.calcFoldedWingProjection(0.3193) )

[maxAlt, maxAltMach, excessPower] = f35.calcMaxAlt(f35.MTOW, 1);
fprintf("\nThe F35 has a service ceiling of %.2f kf (does Mach %.2f at its ceiling with a CL of %.3f).", m2ft(maxAlt)/1000, maxAltMach, f35.calcTrimCL(maxAlt, maxAltMach, f35.MTOW))

[maxMach, maxMachAlt] = f35.calcMaxMach(f35.MTOW, 1);
fprintf("\nThe F35 has a maximum mach number of %.3f which it reaches at %.2f kf", maxMach, m2ft(maxMachAlt)/1000)

[h_maxR, M_maxR, V_maxR, L2D_maxR] = f35.findMaxRangeState(f35.MTOW);
[h_maxE, M_maxE, V_maxE, LD_maxE] = f35.findMaxEnduranceState(f35.MTOW);
fprintf("\nMax range altitude = %.2f kf at Mach %.2f with a speed of %.2f m/s and L^(1/2)/D ratio of %.2f", m2ft(h_maxR)/1000, M_maxR, V_maxR, L2D_maxR);
fprintf("\nMax endurance altitude = %.2f kf at Mach %.2f with a speed of %.2f m/s and L/D ratio of %.2f", m2ft(h_maxE)/1000, M_maxE, V_maxE, LD_maxE);

f35.buildPlots(f35.MTOW, 50)