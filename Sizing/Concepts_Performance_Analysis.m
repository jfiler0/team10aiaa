% performance_control.m
% Performance toolbox driver that can be applied to ANY aircraft concept
% defined in concepts_tabulations.xlsx, using planeObj + flightSegment2.

%% ===================== USER CONTROLS ===============================

%  Choose your concept (column in concepts_tabulations.xlsx)
CN = 8;   % 1 = F18E, 2 = F18E sized, ... 8 = Concept 4, etc.

% Toggles
performance_plots = true;    % Aerodynamics / propulsion / performance grids
mission_plots     = true;    % Enable mission time-history plots from mission.solveMission
turn_plots        = true;    % Instantaneous vs sustained turn plots

% Mission / trade study parameters (generic, can be edited)
R_outbound_nm = 700;   % nominal outbound leg
R_inbound_nm  = 700;   % nominal inbound leg
t_combat_min  = 8;     % combat duration for A2A mission
t_loiter_A2A  = 20;    % loiter for air-to-air mission
t_loiter_STRK1 = 10;   % first loiter for strike mission
t_loiter_STRK2 = 20;   % second loiter for strike mission

h_turn_ft     = 10000; % altitude for turn plots
M_turn_guess  = 0.6;   % reference Mach for instantaneous-turn estimate

%% ================== INITIALIZATION / UTILITIES =====================

build_atmosphere_lookup(-5000, ft2m(120000), 500); % Refresh atmosphere lookup
matlabSetup();                                      % Plot defaults, etc.

lb2N   = @(lb) lb * 4.4482216153;
N2lb   = @(N) N / 4.4482216153;
ft2m   = @(ft) ft * 0.3048;
m2ft   = @(m) m / 0.3048;
nm2m   = @(nm) nm * 1852;
m2nm   = @(m) m / 1852;
kt2mps = @(kt) kt * 0.514444;
ms2kt  = @(ms) ms / 0.514444;

g0 = 9.805; % m/s^2

%% ======================== FIXED INPUTS =============================

fixed_input = struct();

fixed_input.max_alpha   = 15;            % deg, guess for max AoA (landing CL)
fixed_input.type        = "Jet fighter"; % Raymer regression type

% Tuned to match F/A-18 behaviour (same as sizing script)
fixed_input.MTOW_Scalar = 60/50;
fixed_input.SWET_Scalar = 3;
fixed_input.CDW_Scalar  = 9/4;
fixed_input.K1_Scalar   = 1.3;

%% "Superclean" set used only for max Mach (record run)
fixed_input_superclean = fixed_input;
fixed_input_superclean.SWET_Scalar = 2;
fixed_input_superclean.CDW_Scalar  = 7/4;
fixed_input_superclean.K1_Scalar   = 1;

%% =================== DEFINE GENERIC LOADOUTS =======================

clean_loadout = buildLoadout(["AIM-9X", "AIM-9X"]);
ferry_loadout = buildLoadout(["AIM-9X", "FPU-12", "FPU-12", "FPU-12", "AIM-9X"]);
strike_loadout = buildLoadout(["AIM-9X", "FPU-12", "MK-83", "MK-83", "MK-83", ...
                               "MK-83", "FPU-12", "AIM-9X"]);
air2air_loadout = buildLoadout( ...
    ["AIM-9X", "AIM-120", "AIM-120", "AIM-120", ...
     "FPU-12", "AIM-120", "AIM-120", "AIM-120", "AIM-9X"]);

%% ===================== READ CONCEPT FROM EXCEL =====================

disp("Reading Input Geometry...");

thisFile = matlab.desktop.editor.getActiveFilename;
[currentFolder, ~, ~] = fileparts(thisFile);
excelPath = fullfile(currentFolder, "concepts_tabulations.xlsx");
T = readcell(excelPath);

name = readVar('Deliverable', CN, T);
disp("Loaded geometry for: " + name);

fixed_input.L_fuselage = readVar('Fuselage Length [m]', CN, T);
fixed_input.A_max      = readVar('Max Fuselage Area [m2]', CN, T);
fixed_input.g_limit    = readVar('G Limit', CN, T);
fixed_input.KLOC       = readVar('KLOC', CN, T);

geom.empty_weight = lb2N(readVar('Empty Weight [lb]', CN, T));
geom.W_F          = lb2N(readVar('Fixed Weight [lb]', CN, T));
geom.span         = readVar('Wing Span [m]', CN, T);
geom.Lambda_LE    = readVar('LE Sweep [deg]', CN, T);
geom.c_r          = readVar('Root Chord [m]', CN, T);
geom.c_t          = readVar('Tip Chord [m]', CN, T);
geom.engine       = readVar('Engine Selection', CN, T);
geom.num_engine   = readVar('Number of Engines', CN, T);
fold_ratio        = readVar('Fold Ratio', CN, T);

%% ====================== BUILD PLANE OBJECT =========================

disp("Building plane object...");

plane = planeObj(fixed_input, ...
                 name, ...
                 geom.empty_weight, ...
                 geom.Lambda_LE, ...
                 geom.c_r, ...
                 geom.c_t, ...
                 geom.span, ...
                 geom.num_engine, ...
                 geom.engine, ...
                 geom.W_F);

% Start in a clean loadout configuration (just 2x AIM-9X)
plane = plane.applyLoadout(clean_loadout);

disp("  MTOW [lb] = " + N2lb(plane.MTOW));
disp("  AR        = " + plane.AR);
disp("  S_wing    = " + plane.S_wing + " m^2");

%% ====================== DEFINE MISSIONS (LIKE SIZING) ==============

% Recreate your standard 700 nm missions so mission.solveMission can
% produce the same plots as the original script.

h_cruise_m = ft2m(30000);
h_loiter_m = ft2m(10000);
h_combat_m = ft2m(1000);  % low-level combat altitude

M_cruise1  = 0.7;
M_cruise2  = 0.85;        % used in strike mission
M_loiter   = 0.7;
M_climb_A2A = 0.7;
M_climb_STRK = 0.85;
M_combat   = 0.85;

R_700_m = nm2m(R_outbound_nm);
R_50_m  = nm2m(50);

% 700 nm ferry mission
ferry_700 = mission( ...
    [ ...
      flightSegment2("TAKEOFF") ...
      flightSegment2("CLIMB",  M_cruise1) ...
      flightSegment2("CRUISE", NaN,    NaN,   R_700_m) ...
      flightSegment2("LOITER", NaN,    h_loiter_m, 10) ... % 10 min loiter
      flightSegment2("CRUISE", NaN,    NaN,   R_700_m) ...
      flightSegment2("LANDING") ...
    ], ...
    ferry_loadout, "700nm Ferry");

% 700 nm air-to-air mission
air2air_700 = mission( ...
    [ ...
      flightSegment2("TAKEOFF") ...
      flightSegment2("CLIMB",   M_climb_A2A) ...
      flightSegment2("CRUISE",  NaN,    NaN,   R_700_m) ...
      flightSegment2("LOITER",  NaN,    h_loiter_m, t_loiter_A2A) ...
      flightSegment2("COMBAT",  0.8,    h_combat_m, [t_combat_min 0.5]) ... % 8 min combat, drop 50% payload
      flightSegment2("CRUISE",  NaN,    NaN,   R_700_m) ...
      flightSegment2("LANDING") ...
    ], ...
    air2air_loadout, "700nm Air 2 Air");

% 700 nm strike mission
air2ground_700 = mission( ...
    [ ...
      flightSegment2("TAKEOFF") ...
      flightSegment2("CLIMB",   M_climb_STRK) ...
      flightSegment2("CRUISE",  NaN,    NaN,   R_700_m) ...
      flightSegment2("LANDING") ...
      flightSegment2("LOITER",  NaN,    h_loiter_m, t_loiter_STRK1) ...
      flightSegment2("CLIMB",   M_climb_STRK) ...
      flightSegment2("CRUISE",  M_cruise2, NaN,   R_50_m) ...     % penetrate
      flightSegment2("COMBAT",  M_combat, h_combat_m, [30/60 0]) ... % 30 sec combat, drop 0% payload for now
      flightSegment2("CLIMB",   M_climb_STRK) ...
      flightSegment2("CRUISE",  NaN,    NaN,   R_700_m) ...
      flightSegment2("LOITER",  NaN,    h_loiter_m, t_loiter_STRK2) ...
      flightSegment2("LANDING") ...
    ], ...
    strike_loadout, "700nm Strike");

%% ====================== GLOBAL PERFORMANCE =========================

disp("Computing basic performance metrics...");

% Unit cost (millions)
unit_cost = plane.calcUnitCost();   % millions per aircraft
fprintf("  Unit cost ~ %.2f million per aircraft\n", unit_cost);

% Spot factor (carrier deck footprint)
spot_factor = plane.calcSpotFactor(fold_ratio);
fprintf("  Spot factor (relative to F/A-18 ref) ~ %.3f\n", spot_factor);

% Max military & AB thrust at sea level
[TA_mil, ~, ~, ~] = plane.calcProp(0, 0, 0); % M=0, h=0, AB=0
[TA_AB,  ~, ~, ~] = plane.calcProp(0, 0, 1); % AB=1
fprintf("  Sea-level thrust (MIL/AB): %.1f / %.1f kN\n", ...
        TA_mil/1000, TA_AB/1000);

% Max Mach (use superclean scalers)
plane_sc = plane;
plane_sc.fixed_input = fixed_input_superclean;
plane_sc = plane_sc.updateDerivedVariables();

[maxMach, ~] = plane_sc.calcMaxMach(plane_sc.WE, 1);
fprintf("  Max Mach (superclean) ~ %.2f\n", maxMach);

% Back to baseline scalers
plane.fixed_input = fixed_input;
plane = plane.updateDerivedVariables();

% Landing speed (kt) at MTOW
V_land_mps = plane.calcLandingSpeed(0, plane.MTOW);
V_land_kt  = ms2kt(V_land_mps);
fprintf("  Landing speed ~ %.1f kt\n", V_land_kt);

% Service ceiling at mid-mission weight
[maxAlt_m, ~, ~] = plane.calcMaxAlt(plane.mid_mission_weight, 1);
fprintf("  Service ceiling ~ %.1f kft\n", m2ft(maxAlt_m)/1000);

% Max climb rate at mid-mission weight (sea level, AB)
[climbRate, climbAngle, climbSpeed] = plane.calcMaxClimbRate(0, plane.mid_mission_weight, 1); %#ok<ASGLU>
fprintf("  Max climb rate ~ %.1f m/s (%.0f ft/min)\n", ...
        climbRate, m2ft(climbRate)*60);

% Max instantaneous & sustained turn rate at sea level
[turn_rate_inst, M_inst] = plane.getMaxTurnAtAlt(0, plane.mid_mission_weight);
[turn_rate_sus, M_sus]  = plane.getMaxSustainedTurnAtAlt(0, plane.mid_mission_weight, 1);

fprintf("  Max instantaneous turn ~ %.2f deg/s @ M=%.2f\n", turn_rate_inst, M_inst);
fprintf("  Max sustained turn     ~ %.2f deg/s @ M=%.2f\n", turn_rate_sus, M_sus);

% Max total max-range / endurance (single-aircraft, no specific mission)
[range_m, fuel_range_N] = plane.findTotalMaxRange(plane.MTOW, 20);
[time_s,  fuel_end_N]   = plane.findTotalMaxEndurance(plane.MTOW, 20);

fprintf("  Max range ~ %.0f nm, fuel burned ~ %.0f lb\n", ...
        m2nm(range_m), N2lb(fuel_range_N));
fprintf("  Max endurance ~ %.1f hr, fuel burned ~ %.0f lb\n", ...
        time_s/3600, N2lb(fuel_end_N));

% Max L/D at mid-mission weight
[~, ~, ~, LDmax] = plane.findMaxEnduranceState(plane.mid_mission_weight);
fprintf("  Max L/D ~ %.1f\n", LDmax);

%% ===================== PERFORMANCE PLOTS (GRIDS) ===================

if performance_plots
    disp("Building performance grids via buildPerformancePlots...");
    % third argument = number of Mach samples, can increase for resolution
    buildPerformancePlots(plane, plane.MTOW, 30);
end

%% ====================== MISSION PLOTS (ORIGINAL STYLE) =============

if mission_plots
    disp("Running missions with plotting enabled (original mission_plots style)...");

    % Air-to-air mission
    [~, ~, ~, fuel_remaining_A2A] = air2air_700.solveMission(plane, true);
    fprintf("  700nm Air-to-Air mission fuel remaining ~ %.0f lb\n", ...
            N2lb(fuel_remaining_A2A));

    % Strike mission
    [~, ~, ~, fuel_remaining_STRK] = air2ground_700.solveMission(plane, true);
    fprintf("  700nm Strike mission fuel remaining ~ %.0f lb\n", ...
            N2lb(fuel_remaining_STRK));

    % Ferry mission (optional, usually simpler)
    [~, ~, ~, fuel_remaining_FERRY] = ferry_700.solveMission(plane, false); % no plots if you want fewer figs
    fprintf("  700nm Ferry mission fuel remaining ~ %.0f lb\n", ...
            N2lb(fuel_remaining_FERRY));
end

%% =========== INSTANTANEOUS vs SUSTAINED TURN PLOTS ==================

if turn_plots
    disp("Building instantaneous vs sustained turn plots...");

    h_turn_m = ft2m(h_turn_ft);
    W_turn   = plane.mid_mission_weight;

    % Instantaneous-turn estimate (Raymer-ish)
    V_turn_kt   = linspace(200, 700, 40);
    V_turn_mps  = kt2mps(V_turn_kt);
    omega_inst  = nan(size(V_turn_kt));

    [~, a_turn, ~, rho_turn, ~] = queryAtmosphere(h_turn_m, [0 1 0 1 0]);
    q_from_V = @(V) 0.5 * rho_turn * V.^2;

    [CL_max_clean, ~, ~] = plane.calcCL(M_turn_guess);

    for i = 1:numel(V_turn_mps)
        q_i = q_from_V(V_turn_mps(i));
        CL_i = min(W_turn ./ (q_i * plane.S_ref), CL_max_clean);
        if CL_i <= 0
            omega_inst(i) = NaN;
        else
            % Simple instantaneous turn rate estimate
            n_i = CL_i * q_i * plane.S_ref / W_turn;
            omega_inst(i) = rad2deg(n_i * g0 / V_turn_mps(i)); % deg/s
        end
    end

    % Sustained turn from planeObj
    V_sus_kt  = linspace(200, 700, 25);
    omega_sus = nan(size(V_sus_kt));

    for i = 1:numel(V_sus_kt)
        V_ms = kt2mps(V_sus_kt(i));
        M_i  = V_ms / a_turn;

        [turn_rate_deg, ~] = plane.getSustainedTurn(h_turn_m, M_i, W_turn, 1);
        omega_sus(i) = turn_rate_deg;
    end

    figure; hold on; grid on; box on;
    plot(V_turn_kt, omega_inst, 'LineWidth',2, 'DisplayName','Instantaneous (approx)');
    plot(V_sus_kt,  omega_sus, '--','LineWidth',2, 'DisplayName','Sustained (planeObj, AB)');
    xlabel('V [kt]');
    ylabel('Turn rate [deg/s]');
    title(sprintf('Instantaneous vs Sustained Turn (h = %.0f ft)', h_turn_ft));
    legend('Location','best');
end

disp("Performance analysis complete.");

%% =================== LOCAL HELPER FUNCTIONS ========================

function value = readVar(varName, CN, T)
    % Run through first column to look for variable matching varName,
    % read value from column CN+1 (since column 1 is labels).
    varIndex = find(strcmp({T{:, 1}}, varName));
    if isempty(varIndex)
        error('Variable %s not found in the table.', varName);
    end
    value = T{varIndex, CN + 1};

    % If string-like and numeric, cast to double
    if ischar(value) || isstring(value)
        vNum = str2double(value);
        if ~isnan(vNum)
            value = vNum;
        end
    end
end
