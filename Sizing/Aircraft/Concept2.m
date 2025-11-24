% This contains the data for Concept 2. Geometry values are arbitrarily
% gathered from OpenVSP and normalized about the fuselage object length,
% which is set to 50ft. 
    
%% Build atmo table -> Does not need to always be run as it is saved in atmosphere_lookup.mat
% build_atmosphere_lookup(-5000, ft2m(120000), 500);

%% Initial Setup
matlabSetup(); % Clears and sets plot defaults


%% Set Geometry Inputs - Concept 2\

VSP_L_fus = 14.8; % nondimensional length of fuselage in VSP
Corr_factor = 50/VSP_L_fus; % Mapping nondimensional length to feet of known value, arbitrarily set to max fuselage length

fixed_input.L_fuselage = ft2m((14.8)*Corr_factor); % m -> fuselage length - put VSP value into inner parentheses
fixed_input.A_max = 4.5; % m2 -> trying to get the right FA18 wave drag. This was tuned to get M1.6
fixed_input.g_limit = 7; % G -> RFP limit
fixed_input.max_alpha = 12; % deg -> Guess
fixed_input.type = "Jet fighter"; % Which empty weight coefficents to take from Raymer. In weight_regression_lookup
fixed_input.KLOC = 15000; % in kilo-lines of code

fixed_input.MTOW_Scalar = 66/50; % Since the Raymer fighter jet corrections is 16k lb lower than the F18
fixed_input.SWET_Scalar = 243/152; % Shifting SWET historical regression to match VSP
fixed_input.CDW_Scalar = 7.5/4.5; % Wave drag estimate is typically too low

geom.empty_weight = lb2N(28450); % Gotta be Newtons m8. This drives MTOW using historical relations which eventually informs the amount of fuel which can be carried
geom.Lambda_LE = 16; % deg - Leading Edge Sweep
geom.c_r = ft2m((3.7)*Corr_factor); % m - Root Chord. Need to add complex wing geometry weighted average
geom.c_t = ft2m((1.458)*Corr_factor); % m - Tip Chordf1
geom.span = ft2m((2*(5.25+1.2))*Corr_factor); % m - Wing Span
geom.W_F = lb2N(2000); % N - Fixed Weight (Avionics)
geom.engine = "F414"; % engine: A string code which you can see in engine_lookup.xslx. More info in engine_getData

%% Define Loadouts
% When applied to a plane they set extra payload weight, can add to potential fuel volume (if a tank), and add to CD0
clean_loadout = buildLoadout(["AIM-9X", "AIM-9X"]);
strike_loadout = buildLoadout(["AIM-9X", "FPU-12", "AIM-120", "AIM-120", "FPU-12", "AIM-9X"]);

%% Make the f18 object
%                                     empty_weight,       Lambda_LE,     c_r,       c_t,    span,    num_engine,      engine,      W_F
conc2 = planeObj(fixed_input, "Concept2", geom.empty_weight, geom.Lambda_LE, geom.c_r, geom.c_t, geom.span,    2,         geom.engine, geom.W_F);
conc2 = conc2.applyLoadout(clean_loadout); % Just two sidewinders

%% Define Missions
% The flightSegment2 and planeObj classes work together to calculate fuel burned from missions with flightSegment2 requiring the aerodynamic
% data driven by planeObj. And planeObj getting fuel burn info from flightSegment
ferry = mission( [...
    flightSegment2("TAKEOFF") 
    flightSegment2("CLIMB", 0.7) 
    flightSegment2("CRUISE", 0.6, NaN, nm2m(1000)) % 800 nm flight
    flightSegment2("LOITER", NaN, 10000, 20) % 20 min loiter
    flightSegment2("COMBAT", 0.8, 1000, [8 0.5]) % 8 minutes of combat, deploy 50% of payload
    flightSegment2("CRUISE", 0.6, NaN, nm2m(1000)) % 800 nm flight
    flightSegment2("LANDING") ] , ...
    ...
    clean_loadout);

[fuel_burned, W_End] = ferry.solveMission(conc2);
fprintf("\nFERRY MISSION: fuel_burned = %.2f lb, Ending Weight = %.2f lb", N2lb(fuel_burned), N2lb(W_End) )

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

[fuel_burned, W_End] = air2ground.solveMission(conc2);
fprintf("\nSTRIKE MISSION: fuel_burned = %.2f lb, Ending Weight = %.2f lb", N2lb(fuel_burned), N2lb(W_End) )

%% Run anaylisis comparisons

fprintf("The F18 has a unit cost of %.2f million dollars and a stall speed of %.2f kt (lands at %.2f kt) for MTOW", conc2.calcUnitCost(), ms2kt( conc2.calcStallSpeed(0, conc2.MTOW) ), ms2kt( conc2.calcLandingSpeed(0, conc2.MTOW) ) );

[climbRate, climbAngle, climbSpeed] = conc2.calcMaxClimbRate(0, conc2.MTOW, 1);
fprintf("\nSealevel max climb rate = %.3f kft/min with a climb angle of %.2f deg at a speed of %.3f m/s", m2ft(climbRate) * 60 / 1000, climbAngle, climbSpeed);

[turn_rate, n] = conc2.getMaxTurn(0, 0.5, conc2.MTOW);
fprintf("\nSealevel, Mach 0.5 max turn rate = %.2f deg/s at a load factor of %.2f", turn_rate, n)

fprintf("\nF18 spot factor = %.3f (Projected area of %.3f m2)", conc2.calcSpotFactor(0.3193), conc2.calcFoldedWingProjection(0.3193) )

[maxAlt, maxAltMach, excessPower] = conc2.calcMaxAlt(conc2.MTOW, 1);
fprintf("\nThe F18 has a service ceiling of %.2f kf (does Mach %.2f at its ceiling with a CL of %.3f).", m2ft(maxAlt)/1000, maxAltMach, conc2.calcTrimCL(maxAlt, maxAltMach, conc2.MTOW))

[maxMach, maxMachAlt] = conc2.calcMaxMach(conc2.MTOW, 1);
fprintf("\nThe F18 has a maximum mach number of %.3f which it reaches at %.2f kf", maxMach, m2ft(maxMachAlt)/1000)

[h_maxR, M_maxR, V_maxR, L2D_maxR] = conc2.findMaxRangeState(conc2.MTOW);
[h_maxE, M_maxE, V_maxE, LD_maxE] = conc2.findMaxEnduranceState(conc2.MTOW);
fprintf("\nMax range altitude = %.2f kf at Mach %.2f with a speed of %.2f m/s and L^(1/2)/D ratio of %.2f", m2ft(h_maxR)/1000, M_maxR, V_maxR, L2D_maxR);
fprintf("\nMax endurance altitude = %.2f kf at Mach %.2f with a speed of %.2f m/s and L/D ratio of %.2f", m2ft(h_maxE)/1000, M_maxE, V_maxE, LD_maxE);

conc2.buildPlots(conc2.MTOW, 50)