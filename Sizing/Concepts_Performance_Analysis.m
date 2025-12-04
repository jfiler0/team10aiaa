% Concepts_Performance_Analysis.m
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
R_outbound_nm  = 700;   % nominal outbound leg
R_inbound_nm   = 700;   % nominal inbound leg
t_combat_min   = 8;     % combat duration for A2A mission
t_loiter_A2A   = 20;    % loiter for air-to-air mission [min]
t_loiter_STRK1 = 10;    % first loiter for strike mission [min]
t_loiter_STRK2 = 20;    % second loiter for strike mission [min]

h_turn_ft    = 10000;   % altitude for turn plots
M_turn_guess = 0.6;     % reference Mach for instantaneous-turn estimate

% Altitude for "legacy-style" slices (thrust/drag vs Mach, ROC vs V, etc.)
h_perf_ft = 15000;      % you can change this to taste

%% ================== INITIALIZATION / UTILITIES =====================

build_atmosphere_lookup(-5000, ft2m(120000), 500); % Refresh atmosphere lookup
matlabSetup();                                      % Plot defaults, etc.

% Local unit converters that are NOT global toolbox functions
kt2mps = @(kt) kt * 0.514444;   % knots -> m/s
ms2kt  = @(ms) ms / 0.514444;   % m/s -> knots

lb2N = @(lb) lb * 4.4482216153;
N2lb = @(N) N / 4.4482216153;
nm2m = @(nm) nm * 1852;
m2nm = @(m) m / 1852;

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
fixed_input.F_Scaler    = 1.3;  % fuselage-lift scaler used in planeObj

% "Superclean" set used only for max Mach (record run)
fixed_input_superclean = fixed_input;
fixed_input_superclean.SWET_Scalar = 2;
fixed_input_superclean.CDW_Scalar  = 7/4;
fixed_input_superclean.K1_Scalar   = 1;

%% =================== DEFINE GENERIC LOADOUTS =======================

clean_loadout  = buildLoadout(["AIM-9X", "AIM-9X"]);
ferry_loadout  = buildLoadout(["AIM-9X", "FPU-12", "FPU-12", "FPU-12", "AIM-9X"]);
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

% Fixed-input values that come from Excel
fixed_input.L_fuselage = readVar('Fuselage Length [m]', CN, T);
fixed_input.A_max      = readVar('Max Fuselage Area [m2]', CN, T);
fixed_input.g_limit    = readVar('G Limit', CN, T);
fixed_input.KLOC       = readVar('KLOC', CN, T);

fold_ratio             = readVar('Fold Ratio', CN, T);
fixed_input.fold_ratio = fold_ratio;  % used by calcSpotFactor

% Geometry struct
geom.empty_weight = lb2N(readVar('Empty Weight [lb]', CN, T));
geom.W_F          = lb2N(readVar('Fixed Weight [lb]', CN, T));
geom.span         = readVar('Wing Span [m]', CN, T);
geom.Lambda_LE    = readVar('LE Sweep [deg]', CN, T);
geom.c_r          = readVar('Root Chord [m]', CN, T);
geom.c_t          = readVar('Tip Chord [m]', CN, T);
geom.engine       = readVar('Engine Selection', CN, T);
geom.num_engine   = readVar('Number of Engines', CN, T);

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
spot_factor = plane.calcSpotFactor();   % uses fixed_input.fold_ratio internally
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

% Max total max-range / endurance
[range_m, fuel_range_N] = plane.findTotalMaxRange(plane.MTOW, 20);
[time_s,  fuel_end_N]   = plane.findTotalMaxEndurance(plane.MTOW, 20);

fprintf("  Max range ~ %.0f nm, fuel burned ~ %.0f lb\n", ...
        m2nm(range_m), N2lb(fuel_range_N));
fprintf("  Max endurance ~ %.1f hr, fuel burned ~ %.0f lb\n", ...
        time_s/3600, N2lb(fuel_end_N));

% Max L/D at mid-mission weight
[~, ~, ~, LDmax] = plane.findMaxEnduranceState(plane.mid_mission_weight);
fprintf("  Max L/D ~ %.1f\n", LDmax);

%% ========== ADDITIONAL 1D PERFORMANCE SLICES (LEGACY-STYLE) ========

disp("Building additional 1D performance slices (legacy-style)...");

h_perf_m = ft2m(h_perf_ft);
W_perf   = plane.mid_mission_weight;

M_slice = linspace(0.2, min(plane.mach_range(2), 2.0), 40);
V_slice = zeros(size(M_slice));
D_slice = zeros(size(M_slice));
TA_mil_slice = zeros(size(M_slice));
TA_AB_slice  = zeros(size(M_slice));
LD_slice     = zeros(size(M_slice));
RC_mil_slice = zeros(size(M_slice));
RC_AB_slice  = zeros(size(M_slice));
SP_req_slice = zeros(size(M_slice));  % specific power required

for i = 1:numel(M_slice)
    Mi = M_slice(i);
    [~, a_i, ~, rho_i, ~] = queryAtmosphere(h_perf_m, [0 1 0 1 0]);
    V_i = Mi * a_i;
    q_i = 0.5 * rho_i * V_i^2;

    V_slice(i) = V_i;

    % Trim CL and drag at this state
    CL_i = plane.calcTrimCL(h_perf_m, Mi, W_perf);
    [CD_i, ~, ~, ~] = plane.calcCD(CL_i, Mi);
    D_i = CD_i * q_i * plane.S_ref;
    D_slice(i) = D_i;

    % Thrust available (MIL and AB)
    [TA_mil_i, ~, ~, ~] = plane.calcProp(Mi, h_perf_m, 0);
    [TA_AB_i,  ~, ~, ~] = plane.calcProp(Mi, h_perf_m, 1);
    TA_mil_slice(i) = TA_mil_i;
    TA_AB_slice(i)  = TA_AB_i;

    % L/D (using W = L in trim)
    LD_slice(i) = W_perf / max(D_i, eps);

    % Specific excess power (m/s) from planeObj
    Ps_mil = plane.calcExcessPower(h_perf_m, Mi, W_perf, 0);
    Ps_AB  = plane.calcExcessPower(h_perf_m, Mi, W_perf, 1);

    % Treat Ps as climb rate for plotting [ft/min]
    RC_mil_slice(i) = Ps_mil * 196.850394;  % m/s -> ft/min
    RC_AB_slice(i)  = Ps_AB  * 196.850394;

    % Specific power required = D*V / W (units of velocity)
    SP_req_slice(i) = (D_i * V_i) / W_perf;  % [m/s]
end

V_kt_slice = ms2kt(V_slice);

% 1) Thrust available vs drag vs Mach (kN)
figure; hold on; grid on; box on;
plot(M_slice, D_slice/1000,      'b-', 'LineWidth',2, 'DisplayName','Drag');
plot(M_slice, TA_mil_slice/1000, 'g-', 'LineWidth',2, 'DisplayName','T_{MIL}');
plot(M_slice, TA_AB_slice/1000,  'r-', 'LineWidth',2, 'DisplayName','T_{AB}');
xlabel('Mach'); ylabel('Force [kN]');
title(sprintf('Thrust Available and Drag at h = %.0f ft', h_perf_ft));
legend('Location','best');

% 2) Rate of climb vs airspeed (MIL vs AB)
figure; hold on; grid on; box on;
plot(V_kt_slice, RC_mil_slice, '-o', 'LineWidth',2, 'DisplayName','MIL');
plot(V_kt_slice, RC_AB_slice,  '-s', 'LineWidth',2, 'DisplayName','AB');
xlabel('V [kt]'); ylabel('Rate of climb [ft/min]');
title(sprintf('Rate of Climb vs V (h = %.0f ft)', h_perf_ft));
legend('Location','best');

% 3) L/D vs Mach
figure; hold on; grid on; box on;
plot(M_slice, LD_slice, 'LineWidth',2);
xlabel('Mach'); ylabel('L/D');
title(sprintf('L/D vs Mach (h = %.0f ft)', h_perf_ft));

% 4) L/D vs airspeed
figure; hold on; grid on; box on;
plot(V_kt_slice, LD_slice, 'LineWidth',2);
xlabel('V [kt]'); ylabel('L/D');
title(sprintf('L/D vs V (h = %.0f ft)', h_perf_ft));

% 5) Specific power required vs airspeed
figure; hold on; grid on; box on;
plot(V_kt_slice, SP_req_slice, 'LineWidth',2);
xlabel('V [kt]');
ylabel('Specific power required [m/s]');
title(sprintf('Specific Power Required vs V (h = %.0f ft)', h_perf_ft));

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

    % Ferry mission
    [~, ~, ~, fuel_remaining_FERRY] = ferry_700.solveMission(plane, false);
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

%% =================== PAYLOAD–RANGE & LOITER TRADES ===================

disp("Building payload–range and payload–loiter trades (Breguet-style)...");

% Basic weights
W_TO   = plane.MTOW;              % N
W_P0   = plane.W_P;               % baseline payload in current loadout
W_Tanks = 0;
if isprop(plane, "W_Tanks")
    W_Tanks = plane.W_Tanks;
end
W_struct_base = plane.WE + plane.W_F + W_Tanks + W_P0;  % everything non-fuel

% ------------------- Cruise design point (for range) -------------------
h_R2_ft = 30000;           % cruise altitude for range trade
M_R2    = 0.85;

h_R2_m = ft2m(h_R2_ft);
[~, a_R2, ~, rho_R2, ~] = queryAtmosphere(h_R2_m, [0 1 0 1 0]);

V_R2 = M_R2 * a_R2;
q_R2 = 0.5 * rho_R2 * V_R2^2;

% Aero at cruise
CL_R2 = W_TO / (q_R2 * plane.S_ref);
[CD_R2, ~, ~, ~] = plane.calcCD(CL_R2, M_R2);
D_R2   = CD_R2 * q_R2 * plane.S_ref;
LD_R2  = W_TO / max(D_R2, eps);   % L/D in cruise

% Propulsion at cruise (MIL)
[~, TSFC_R2, ~, ~] = plane.calcProp(M_R2, h_R2_m, 0);   % TSFC [kg/(N*s)]
c_R2 = TSFC_R2 * g0;   % "c" in 1/s for Breguet (weight-based)

% -------------------- Loiter design point (for endurance) --------------
h_loit_ft = 10000;
M_loit    = 0.7;

h_loit_m = ft2m(h_loit_ft);
[~, a_loit, ~, rho_loit, ~] = queryAtmosphere(h_loit_m, [0 1 0 1 0]);

V_loit = M_loit * a_loit;
q_loit = 0.5 * rho_loit * V_loit^2;

CL_loit = W_TO / (q_loit * plane.S_ref);
[CD_loit, ~, ~, ~] = plane.calcCD(CL_loit, M_loit);
D_loit   = CD_loit * q_loit * plane.S_ref;
LD_loit  = W_TO / max(D_loit, eps);   % L/D in loiter

[~, TSFC_loit, ~, ~] = plane.calcProp(M_loit, h_loit_m, 0);
c_loit = TSFC_loit * g0;   % 1/s

% ------------------------ Payload sweep -------------------------------
W_payload_max_frac = 0.18;   % max extra payload as fraction of MTOW
payload_vec_lb = linspace(0, W_payload_max_frac * N2lb(W_TO), 10);

range_nm_vec   = nan(size(payload_vec_lb));
t_loit_hr_vec  = nan(size(payload_vec_lb));

for i = 1:numel(payload_vec_lb)
    W_pay_extra_lb = payload_vec_lb(i);
    W_pay_extra_N  = lb2N(W_pay_extra_lb);

    % New "structural" weight with extra payload, MTOW held fixed
    W_struct_i = W_struct_base + W_pay_extra_N;

    if W_struct_i >= W_TO
        % No room left for fuel: infeasible
        range_nm_vec(i)  = NaN;
        t_loit_hr_vec(i) = NaN;
        continue;
    end

    W_fuel_i = W_TO - W_struct_i;   % N of fuel available

    Wi = W_TO;           % start of mission [N]
    Wf = W_struct_i;     % end-of-fuel weight [N]

    % Breguet jet range:  R = V/c * (L/D) * ln(Wi/Wf)
    R_i_m = (V_R2 / c_R2) * LD_R2 * log(Wi / Wf);
    range_nm_vec(i) = m2nm(R_i_m);

    % Breguet endurance: t = (1/c) * (L/D) * ln(Wi/Wf)
    t_i_s = (1 / c_loit) * LD_loit * log(Wi / Wf);
    t_loit_hr_vec(i) = t_i_s / 3600;
end

% ----------------------------- Plots ----------------------------------

figure; hold on; grid on; box on;
plot(payload_vec_lb, range_nm_vec, '-o', 'LineWidth', 2);
xlabel('Extra payload [lb]');
ylabel('Range [nmi]');
title(sprintf('Payload–Range Trade (h = %.0f ft, M = %.2f)', ...
      h_R2_ft, M_R2));

figure; hold on; grid on; box on;
plot(payload_vec_lb, t_loit_hr_vec, '-o', 'LineWidth', 2);
xlabel('Extra payload [lb]');
ylabel('Loiter time [hr]');
title(sprintf('Payload–Loiter Trade (h = %.0f ft, M = %.2f)', ...
      h_loit_ft, M_loit));

%% ========== TAKEOFF PARAMETER (TOP) & LANDING DISTANCE ===============

disp("Estimating TOP and landing distance (Raymer-style)...");

% Basic weights and wing loading
W_TO_N   = plane.MTOW;            % [N]
W_TO_lbf = N2lb(W_TO_N);          % [lbf]
S_wing_m2 = plane.S_wing;         % [m^2]
S_wing_ft2 = (m2ft(1))^2 * S_wing_m2;

W_S_lbf_ft2 = W_TO_lbf / S_wing_ft2;   % [lb/ft^2]

% Takeoff T/W (use sea-level AB thrust)
[TA_SL_AB, ~, ~, ~] = plane.calcProp(0, 0, 1);   % [N]
T_W_TO = TA_SL_AB / W_TO_N;                       % [-]

% Atmosphere at sea level for reference density
[~, ~, ~, rho_SL, ~] = queryAtmosphere(0, [0 0 0 1 0]);

% ---------- 1) TOP vs altitude sweep ----------
h_TO_sweep_ft = linspace(0, 8000, 25);
TOP_sweep     = zeros(size(h_TO_sweep_ft));

for i = 1:numel(h_TO_sweep_ft)
    h_i_m = ft2m(h_TO_sweep_ft(i));

    % Local density and density ratio
    [~, ~, ~, rho_i, ~] = queryAtmosphere(h_i_m, [0 0 0 1 0]);
    sigma_i = rho_i / rho_SL;

    % Takeoff speed from plane model (assumed ~1.2 * Vs in its internals)
    V_TO_i = plane.calcTakeoffSpeed(h_i_m, W_TO_N);  % [m/s]
    Vs_i   = V_TO_i / 1.2;                           % [m/s], approx

    % Recover effective CL_max,TO from stall relation:
    % Vs^2 = 2W / (rho S CL_max)
    CL_TO_i = 2 * W_TO_N / (rho_i * S_wing_m2 * Vs_i^2);

    % Raymer-style TOP definition:
    %   TOP = (W/S) / (sigma * CL_TO * T/W)
    TOP_sweep(i) = W_S_lbf_ft2 / (sigma_i * CL_TO_i * T_W_TO);
end

figure; hold on; grid on; box on;
plot(h_TO_sweep_ft, TOP_sweep, 'LineWidth', 2);
xlabel('Takeoff altitude [ft]');
ylabel('TOP = (W/S) / (\sigma C_{L,TO} T/W)');
title('Takeoff Parameter vs Altitude (using plane.calcTakeoffSpeed)');

% ---------- 2) Simple landing-distance estimate (Raymer 5.11) ---------
% Use "flapped" CLmax at low Mach as landing CLmax.
[~, CLmax_flapped, ~] = plane.calcCL(0.2);  % M ~ 0.2, flaps down
CLmax_land = CLmax_flapped;

% Choose a representative landing field (e.g. Elmendorf-ish)
h_land_ft = 100;                      % [ft]
h_land_m  = ft2m(h_land_ft);

[~, ~, ~, rho_land, ~] = queryAtmosphere(h_land_m, [0 0 0 1 0]);
sigma_land = rho_land / rho_SL;

% Safety distance for rollout / flare (Raymer uses ~1000 ft)
Sa = 1000;   % [ft]

% Raymer Eq. 5.11 (approx):
%   S_land = 80 * (W/S) * (1 / (sigma * CLmax_land)) + Sa
S_landing_ft = 80 * W_S_lbf_ft2 * (1 / (sigma_land * CLmax_land)) + Sa;

fprintf('\n---- Takeoff & Landing Summary ----\n');
fprintf('W/S (MTOW)               : %.1f lb/ft^2\n', W_S_lbf_ft2);
fprintf('T/W at takeoff (AB)      : %.3f\n', T_W_TO);
fprintf('TOP at sea level         : %.1f\n', TOP_sweep(1));
fprintf('Landing distance estimate: S_land ≈ %.0f ft (h = %.0f ft)\n\n', ...
        S_landing_ft, h_land_ft);



%% Done


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
