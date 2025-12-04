% Concepts_Performance_Analysis.m
% Performance toolbox driver that can be applied to ANY aircraft concept
% defined in concepts_tabulations.xlsx, using planeObj + flightSegment2.
%
% ASSUMES the following utility functions are on the MATLAB path
% (same as sizing code):
%   lb2N, N2lb, ft2m, m2ft, nm2m, m2nm, kt2mps, ms2kt
%
% This script does NOT redefine any of those to avoid conflicts.

%% ===================== USER CONTROLS ===============================
clear;clc;close all;
%  Choose your concept (column in concepts_tabulations.xlsx)
CN = 8;   % 1 = F18E, 2 = F18E sized, ... 8 = Concept 4, etc.

% Toggles
performance_plots = true;    % Aerodynamics / propulsion / performance grids
mission_plots     = true;    % Enable mission time-history plots from mission.solveMission
turn_plots        = true;    % Instantaneous vs sustained turn plots

% Mission / trade study parameters (generic, can be edited)
R_outbound_nm   = 700;   % nominal outbound leg
R_inbound_nm    = 700;   % nominal inbound leg
t_combat_min    = 8;     % combat duration for A2A mission
t_loiter_A2A    = 20;    % loiter for air-to-air mission
t_loiter_STRK1  = 10;    % first loiter for strike mission
t_loiter_STRK2  = 20;    % second loiter for strike mission

h_turn_ft       = 10000; % altitude for turn plots
M_turn_guess    = 0.6;   % reference Mach for instantaneous-turn estimate

%% ================== INITIALIZATION / UTILITIES =====================

build_atmosphere_lookup(-5000, ft2m(120000), 500); % Refresh atmosphere lookup
matlabSetup();                                      % Plot defaults, etc.

g0 = 9.805; % m/s^2

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

% ---- Fixed-input struct (Raymer regression / tuners) ----
fixed_input = struct();

fixed_input.L_fuselage = readVar('Fuselage Length [m]', CN, T); % m
fixed_input.A_max      = readVar('Max Fuselage Area [m2]', CN, T); % m^2
fixed_input.g_limit    = readVar('G Limit', CN, T);             % G limit
fixed_input.KLOC       = readVar('KLOC', CN, T);                % kilo-lines of code
fixed_input.fold_ratio = readVar('Fold Ratio', CN, T);          % for wing folding / spot factor

% These are concept-invariant tuners (same as sizing script)
fixed_input.max_alpha   = 10;            % deg (landing CL limit proxy)
fixed_input.type        = "Jet fighter"; % Raymer regression type

fixed_input.MTOW_Scalar = 60/50;   % Raymer fighter MTOW correction
fixed_input.SWET_Scalar = 3;       % Wetted-area regression correction
fixed_input.CDW_Scalar  = 9/4;     % Wave-drag correction
fixed_input.K1_Scalar   = 1.3;     % Induced-drag correction
fixed_input.F_Scaler    = 1.3;     % Fuselage lift factor scaler (needed by planeObj)

% ---- Geometry / weight (from Excel) ----
geom.empty_weight = lb2N(readVar('Empty Weight [lb]', CN, T));  % N
geom.W_F          = lb2N(readVar('Fixed Weight [lb]', CN, T));  % N (avionics, etc.)
geom.span         = readVar('Wing Span [m]', CN, T);            % m
geom.Lambda_LE    = readVar('LE Sweep [deg]', CN, T);           % deg
geom.c_r          = readVar('Root Chord [m]', CN, T);           % m
geom.c_t          = readVar('Tip Chord [m]', CN, T);            % m
geom.engine       = readVar('Engine Selection', CN, T);         % engine code (string)
geom.num_engine   = readVar('Number of Engines', CN, T);        % #

%% ====================== BUILD PLANE OBJECT =========================

disp("Building plane object...");

% Constructor signature consistent with your current planeObj
% (no tail_input in this performance driver)
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

h_cruise_m = ft2m(30000);
h_loiter_m = ft2m(10000);
h_combat_m = ft2m(1000);  % low-level combat altitude

M_cruise1   = 0.7;
M_cruise2   = 0.85;        % used in strike mission
M_loiter    = 0.7;
M_climb_A2A = 0.7;
M_climb_STRK = 0.85;
M_combat    = 0.85;

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
      flightSegment2("COMBAT",  0.8,    h_combat_m, [t_combat_min 0.5]) ... % drop 50% payload
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
      flightSegment2("COMBAT",  M_combat, h_combat_m, [30/60 0]) ... % 30 sec combat
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

% Spot factor (carrier deck footprint) – now uses plane.fixed_input.fold_ratio
spot_factor = plane.calcSpotFactor();
fprintf("  Spot factor (relative to F/A-18 ref) ~ %.3f\n", spot_factor);

% Max military & AB thrust at sea level
[TA_mil, ~, ~, ~] = plane.calcProp(0, 0, 0); % M=0, h=0, AB=0
[TA_AB,  ~, ~, ~] = plane.calcProp(0, 0, 1); % AB=1
fprintf("  Sea-level thrust (MIL/AB): %.1f / %.1f kN\n", ...
        TA_mil/1000, TA_AB/1000);

% Max Mach (use "superclean" scalers like sizing code)
fixed_input_superclean           = fixed_input;
fixed_input_superclean.SWET_Scalar = 2;
fixed_input_superclean.CDW_Scalar  = 7/4;
fixed_input_superclean.K1_Scalar   = 1;

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
[climbRate, ~, ~] = plane.calcMaxClimbRate(0, plane.mid_mission_weight, 1);
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
    disp("Running missions with plotting enabled (mission_plots style)...");

    % Air-to-air mission
    [~, ~, ~, fuel_remaining_A2A] = air2air_700.solveMission(plane, true);
    fprintf("  700nm Air-to-Air mission fuel remaining ~ %.0f lb\n", ...
            N2lb(fuel_remaining_A2A));

    % Strike mission
    [~, ~, ~, fuel_remaining_STRK] = air2ground_700.solveMission(plane, true);
    fprintf("  700nm Strike mission fuel remaining ~ %.0f lb\n", ...
            N2lb(fuel_remaining_STRK));

    % Ferry mission (optional, no plots to avoid extra figs)
    [~, ~, ~, fuel_remaining_FERRY] = ferry_700.solveMission(plane, false);
    fprintf("  700nm Ferry mission fuel remaining ~ %.0f lb\n", ...
            N2lb(fuel_remaining_FERRY));
end

%% =========== INSTANTANEOUS vs SUSTAINED TURN PLOTS ==================

if turn_plots
    disp("Building instantaneous vs sustained turn plots...");

    h_turn_m = ft2m(h_turn_ft);
    W_turn   = plane.mid_mission_weight;

    % Instantaneous-turn estimate (approximate)
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

%% ========== ADDITIONAL 1D PERFORMANCE PLOTS (LEGACY STYLE) ==========
% These re-create the old HW-style 1D plots:
%   • L/D vs Mach with annotated max
%   • Thrust (MIL/AB) and Drag vs Mach at a fixed altitude
%   • Rate of climb vs airspeed (MIL vs AB)
%
% They use planeObj + your atmosphere utilities instead of the old
% Raymer-specific functions.

if performance_plots
    disp("Building additional legacy-style 1D performance plots...");

    % Representative "performance altitude" like the original script
    h_perf_ft = 30000;             % [ft]
    h_perf_m  = ft2m(h_perf_ft);   % [m]

    % Use a representative weight: mid-mission is a good default
    W_perf = plane.mid_mission_weight;   % [N]

    % Mach range for 1D sweeps (within plane.mach_range)
    M_vec = linspace( ...
        max(0.2, plane.mach_range(1)), ...
        min(1.8, plane.mach_range(2)), 40);

    % Preallocate
    q_vec   = zeros(size(M_vec));
    a_vec   = zeros(size(M_vec));
    rho_vec = zeros(size(M_vec));
    V_vec   = zeros(size(M_vec));

    T_mil = zeros(size(M_vec));
    T_AB  = zeros(size(M_vec));
    D_vec = zeros(size(M_vec));
    LD_vec = zeros(size(M_vec));

    % ---- Sweep Mach at fixed altitude, compute thrust/drag/L/D ----
    for i = 1:numel(M_vec)
        M = M_vec(i);

        % Freestream properties
        [q_i, ~, ~, ~] = metricFreestream(h_perf_m, M);  % dynamic pressure [Pa]
        [~, a_i, ~, rho_i, ~] = queryAtmosphere(h_perf_m, [0 1 0 1 0]);

        q_vec(i)   = q_i;
        a_vec(i)   = a_i;
        rho_vec(i) = rho_i;
        V_vec(i)   = M * a_i;  % [m/s]

        % Trim CL to hold level flight at this W, h, M
        CL_trim = plane.calcTrimCL(h_perf_m, M, W_perf);

        % Drag coefficient and drag
        [CD_i, ~, ~, ~] = plane.calcCD(CL_trim, M);
        D_vec(i) = CD_i * q_i * plane.S_ref;  % [N]

        % L/D (L = W in trimmed level flight)
        LD_vec(i) = W_perf / D_vec(i);

        % Thrust available (MIL and AB)
        [T_mil(i), ~, ~, ~] = plane.calcProp(M, h_perf_m, 0);  % MIL
        [T_AB(i),  ~, ~, ~] = plane.calcProp(M, h_perf_m, 1);  % AB
    end

    % ================= L/D vs Mach, with max annotated ==============
    [LD_max, idx_LDmax] = max(LD_vec);
    M_LDmax = M_vec(idx_LDmax);

    figure; hold on; grid on; box on;
    plot(M_vec, LD_vec, 'LineWidth', 2);
    plot(M_LDmax, LD_max, 'ro', 'MarkerFaceColor','r');
    xlabel('Mach');
    ylabel('L/D');
    title(sprintf('L/D vs Mach (h = %.0f ft)', h_perf_ft));
    text(M_LDmax, LD_max, ...
         sprintf('  Max L/D = %.1f at M = %.2f', LD_max, M_LDmax), ...
         'VerticalAlignment','bottom');

    % ============ Thrust (MIL/AB) and Drag vs Mach ==================
    figure; hold on; grid on; box on;
    plot(M_vec, D_vec/1000,  'b-', 'LineWidth', 2, 'DisplayName','Drag');
    plot(M_vec, T_mil/1000, 'g-', 'LineWidth', 2, 'DisplayName','T_{MIL}');
    plot(M_vec, T_AB/1000,  'r-', 'LineWidth', 2, 'DisplayName','T_{AB}');
    xlabel('Mach');
    ylabel('Force [kN]');
    title(sprintf('Thrust and Drag vs Mach (h = %.0f ft)', h_perf_ft));
    legend('Location','best');

    % ================= Rate of climb vs airspeed ====================
    % RC = (T - D)*V / W, plane.calcProp + our D_vec
    V_kt = ms2kt(V_vec);  % [kt]

    RC_mil = (T_mil - D_vec) .* V_vec ./ W_perf;  % [m/s]
    RC_AB  = (T_AB  - D_vec) .* V_vec ./ W_perf;  % [m/s]

    RC_mil_fpm = m2ft(RC_mil) * 60;  % [ft/min]
    RC_AB_fpm  = m2ft(RC_AB)  * 60;  % [ft/min]

    figure; hold on; grid on; box on;
    plot(V_kt, RC_mil_fpm, 'b-', 'LineWidth', 2, 'DisplayName','MIL');
    plot(V_kt, RC_AB_fpm,  'r-', 'LineWidth', 2, 'DisplayName','AB');
    xlabel('V [kt]');
    ylabel('Rate of climb [ft/min]');
    title(sprintf('Rate of Climb vs V (h = %.0f ft, W = mid-mission)', h_perf_ft));
    legend('Location','best');
end


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

    % Handle <missing> objects gracefully
    if ismissing(value)
        error('Value for "%s" in column %d is missing in concepts_tabulations.xlsx.', ...
              varName, CN);
    end
end
