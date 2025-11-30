%% GOAL: Compare calculated F18E Super Hornet specs calculated from is general geometry, engine, and weight to the detailed performance specs seen in the NATOPS to check confidence in analyisis method
    % Note on the structure of the code here: Note that none of the functions called in this script have hard number embedded in them
    % anymore. The analysis should work just the same for a 747, F16, UAS, or pretty much anything with a jet engine and wings. You can
    % adjust the main geometry inputs to control wing & fuselage dimensions. You can add additional stores and engines by adding rows to the
    % two lookup tables engine_lookup and stores_lookup. EVERY function takes input and gives outputs in metric with weights always being in
    % Newtons instread of kg.

    % This script demonsrates most of the code functionaity (besides optimizaton) and sets geoemtry for the F18. You can use it a reference
    % on how to build planeObj variables and get useful analysis outputs.
    
%% Build atmo table -> Does not need to always be run as it is saved in atmosphere_lookup.mat
build_atmosphere_lookup(-5000, ft2m(120000), 500);

%% Initial Setup
matlabSetup(); % Clears and sets plot defaults

%% Set Geometry Inputs - All FA-18E Super Hornet
fixed_input.L_fuselage = 17.54; % m -> FA18 fuselage length
fixed_input.A_max = 4.5; % m2 -> trying to get the right FA18 wave drag. This was tuned to get M1.6
fixed_input.g_limit = 7; % G -> FA18 limit
fixed_input.max_alpha = 12; % deg -> Guess
fixed_input.type = "Jet fighter"; % Which empty weight coefficents to take from Raymer. In weight_regression_lookup
fixed_input.KLOC = 15000; % in kilo-lines of code
    
% Some scalar corrections
fixed_input.MTOW_Scalar = 66/50; % Since the Raymer fighter jet corrections is 16k lb lower than the F18
fixed_input.SWET_Scalar = 243/152; % Shifting SWET historical regression to match VSP
fixed_input.CDW_Scalar = 7/4; % Wave drag estimate is typically too low

geom.empty_weight = lb2N(28450); % Gotta be Newtons m8. This drives MTOW using historical relations which eventually informs the amount of fuel which can be carried
geom.Lambda_LE = 29.3; % deg - Leading Edge Sweep
geom.c_r = 5.07; % m - Root Chord
geom.c_t = 1.686; % m - Tip Chordf1
geom.span = 12.05; % m - Wing Span
geom.W_F = lb2N(2000); % N - Fixed Weight (Avionics)
geom.engine = "F414"; % engine: A string code which you can see in engine_lookup.xslx. More info in engine_getData

%% Define Loadouts
% When applied to a plane they set extra payload weight, can add to potential fuel volume (if a tank), and add to CD0
clean_loadout = buildLoadout(["AIM-9X", "AIM-9X"]);
strike_loadout = buildLoadout(["AIM-9X", "FPU-12", "AIM-120", "AIM-120", "FPU-12", "AIM-9X"]);

%% Make the f18 object
%                                     empty_weight,       Lambda_LE,     c_r,       c_t,    span,    num_engine,      engine,      W_F
f18 = planeObj(fixed_input, "FA18", geom.empty_weight, geom.Lambda_LE, geom.c_r, geom.c_t, geom.span,    2,         geom.engine, geom.W_F);
f18 = f18.applyLoadout(clean_loadout); % Just two sidewinders

%% Define Missions
% The flightSegment2 and planeObj classes work together to calculate fuel burned from missions with flightSegment2 requiring the aerodynamic
% data driven by planeObj. And planeObj getting fuel burn info from flightSegment
ferry = mission( [...
    flightSegment2("TAKEOFF") 
    flightSegment2("CLIMB", 0.7) 
    flightSegment2("CRUISE", NaN, NaN, nm2m(1500)) % 800 nm flight
    % flightSegment2("LOITER", NaN, 10000, 20) % 20 min loiter
    % flightSegment2("COMBAT", 0.8, 1000, [8 0.5]) % 8 minutes of combat, deploy 50% of payload
    flightSegment2("CRUISE", NaN, NaN, nm2m(1500)) % 800 nm flight
    flightSegment2("LANDING") ] , ...
    ...
    clean_loadout);

% 5 cruise segments * 10 divisions * 93 function calls * 50 max internal function calls

air2ground = mission( [...
    flightSegment2("TAKEOFF") 
    flightSegment2("CLIMB", 0.85) % Check this mach
    flightSegment2("CRUISE", 0.85, ft2m(30000), nm2m(700)) % 700 nm flight
    flightSegment2("LANDING") % Saying this is decent
    flightSegment2("LOITER", NaN, ft2m(10000), 10) % 10 min loiter
    flightSegment2("CLIMB", 0.85) % Check this mach
    flightSegment2("CRUISE", 0.85, NaN, nm2m(50)) % Penetrate
    flightSegment2("COMBAT", 0.85, 1000, [30/60 0]) % quick combat ***
    flightSegment2("CLIMB", 0.85) % Check this mach
    flightSegment2("CRUISE", 0.85, ft2m(30000), nm2m(700)) % 700 nm flight
    flightSegment2("LOITER", NaN, ft2m(10000), 20) % 20 min loiter
    flightSegment2("LANDING") ] , ...
    ...
    strike_loadout);

%% Run Aircraft Sizing

% f18 = sizeAircraft(f18, [ferry], @constraints_rfp, true, 3);
% W0_diff(f18, [ferry])

%% Solving missions

[WTO_Next, fuel_burned, W_End] = ferry.solveMission(f18, false);
fprintf("\nFERRY MISSION: fuel_burned = %.2f lb, Ending Weight = %.2f lb, Next = %.2f lb", N2lb(fuel_burned), N2lb(W_End), N2lb(WTO_Next))

[WTO_Next, fuel_burned, W_End] = air2ground.solveMission(f18, false);
fprintf("\nSTRIKE MISSION: fuel_burned = %.2f lb, Ending Weight = %.2f lb, Next = %.2f lb", N2lb(fuel_burned), N2lb(W_End), N2lb(WTO_Next))

%% Run anaylisis comparisons

fprintf("\nThe F18 has a unit cost of %.2f million dollars and a stall speed of %.2f kt (lands at %.2f kt) for MTOW", f18.calcUnitCost(), ms2kt( f18.calcStallSpeed(0, f18.MTOW) ), ms2kt( f18.calcLandingSpeed(0, f18.MTOW) ) );

[climbRate, climbAngle, climbSpeed] = f18.calcMaxClimbRate(0, f18.MTOW, 1);
fprintf("\nSealevel max climb rate = %.3f kft/min with a climb angle of %.2f deg at a speed of %.3f m/s", m2ft(climbRate) * 60 / 1000, climbAngle, climbSpeed);

[turn_rate, n] = f18.getMaxTurn(0, 0.5, f18.MTOW);
fprintf("\nSealevel, Mach 0.5 max turn rate = %.2f deg/s at a load factor of %.2f", turn_rate, n)

fprintf("\nF18 spot factor = %.3f (Projected area of %.3f m2)", f18.calcSpotFactor(0.3193), f18.calcFoldedWingProjection(0.3193) )

[maxAlt, maxAltMach, excessPower] = f18.calcMaxAlt(f18.MTOW, 1);
fprintf("\nThe F18 has a service ceiling of %.2f kf (does Mach %.2f at its ceiling with a CL of %.3f).", m2ft(maxAlt)/1000, maxAltMach, f18.calcTrimCL(maxAlt, maxAltMach, f18.MTOW))

[maxMach, maxMachAlt] = f18.calcMaxMach(f18.MTOW, 1);
fprintf("\nThe F18 has a maximum mach number of %.3f which it reaches at %.2f kf", maxMach, m2ft(maxMachAlt)/1000)

[h_maxR, M_maxR, V_maxR, L2D_maxR] = f18.findMaxRangeState(f18.MTOW);
[h_maxE, M_maxE, V_maxE, LD_maxE] = f18.findMaxEnduranceState(f18.MTOW);
fprintf("\nMax range altitude = %.2f kf at Mach %.2f with a speed of %.2f m/s and L^(1/2)/D ratio of %.2f", m2ft(h_maxR)/1000, M_maxR, V_maxR, L2D_maxR);
fprintf("\nMax endurance altitude = %.2f kf at Mach %.2f with a speed of %.2f m/s and L/D ratio of %.2f", m2ft(h_maxE)/1000, M_maxE, V_maxE, LD_maxE);


fprintf("\nAssuming starting at MTOW and burning to empty, the F18E has a max range of %.2f nm", m2nm(f18.findTotalMaxRange(f18.MTOW, 20)))
f18.buildPlots(f18.MTOW, 20)