% performance_control.m
% Performance toolbox driver that can be applied to ANY aircraft concept
% defined in concepts_tabulations.xlsx, using planeObj + flightSegment2.

%% ===================== USER CONTROLS ===============================
clear; clc; close all;
%  Choose your concept (column in concepts_tabulations.xlsx)
CN = 8;   % 1 = F18E, 2 = F18E sized, ... 8 = Concept 4, etc.

% Toggles
performance_plots = true;    % Aerodynamics / propulsion / performance grids
mission_plots     = true;    % Enable mission time-history plots from mission.solveMission
turn_plots        = true;    % Instantaneous vs sustained turn plots
legacy_plots      = true;    % Raymer-style legacy plots (L/D vs M, TOP, etc.)

% Mission / trade study parameters (generic, can be edited)
R_outbound_nm  = 700;   % nominal outbound leg
R_inbound_nm   = 700;   % nominal inbound leg (not yet used separately)
t_combat_min   = 8;     % combat duration for A2A mission
t_loiter_A2A   = 20;    % loiter for air-to-air mission
t_loiter_STRK1 = 10;    % first loiter for strike mission
t_loiter_STRK2 = 20;    % second loiter for strike mission

h_turn_ft    = 10000;   % altitude for turn plots
M_turn_guess = 0.6;     % reference Mach for instantaneous-turn estimate

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

fixed_input.F_Scaler    = 1.0;          % <<< ADD THIS LINE


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
geom.engine            = readVar('Engine Selection', CN, T);
geom.num_engine        = readVar('Number of Engines', CN, T);

% Store fold ratio inside fixed_input so planeObj can see it
fixed_input.fold_ratio = readVar('Fold Ratio', CN, T);


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
% Spot factor (carrier deck footprint)
spot_factor = plane.calcSpotFactor();   % no arguments
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

%% ================== LEGACY RAYMER-STYLE PLOTS ======================
% This block recreates the "old performance toolbox" style plots using a
% simple Raymer-style polar & engine model. Currently uses default
% F-16-ish values – TODO: wire CDo/k1/k2/TSFC from your aero/prop models.

if legacy_plots
    disp("Building legacy Raymer-style plots...");

    % ---- Constants (imperial) ----
    gamma  = 1.4;
    R_im   = 1716;        % [ft*lbf/(slug*R)]
    T_std  = 518.69;      % [R]
    rho_SL = 0.002377;    % [slug/ft^3]

    % ---- Extract basic geometry in imperial ----
    S_ref_ft2 = plane.S_wing / 0.092903;   % m^2 -> ft^2
    W_TO_lbf  = N2lb(plane.MTOW);
    W_S       = W_TO_lbf / S_ref_ft2;

    % Raymer-ish drag polar (EDIT or wire from planeObj)
    AR   = plane.AR;
    CDo  = 0.0170;       % TODO: tie to clean CD0 from aero model
    k1   = 0.1160;       % TODO: tie to induced coefficient
    k2   = -0.0063;      % tweak term if needed
    e_osw = 1/(pi*AR*k1);

    % Engine data (per-engine thrust at sea level, MIL/AB) – EDIT to match engine lookup
    % For now, approximate from sea-level kN we printed earlier:
    T_SL_mil = TA_mil / 4.4482216153;   % convert kN->N->lbf if needed
    T_SL_AB  = TA_AB  / 4.4482216153;
    n_eng    = plane.num_engine;

    % TSFC-like constant for Raymer Breguet [1/s]
    TSFC_total = 0.00019;  % turbojet/fan Raymer c (you can adjust)
    SFC_hr     = TSFC_total * 3600; % [1/hr]

    % Generic segment assumptions
    beta_segment = 0.90;   % W_segment / W_TO for performance calc
    W_segment    = beta_segment * W_TO_lbf;

    % Key altitudes / Machs
    h_perf   = 35000;                    % [ft] main performance altitude
    M_vec    = linspace(0.5, 2.0, 15);   % baseline Mach sweep
    h_loiter = 25000;                    % [ft]
    M_loiter = 0.4;
    h_cruise = 35000;
    M_cruise = 0.87;
    h_R2     = 40000;
    M_R2     = 0.87;

    % Takeoff/landing CLs and T/W
    CL_TO_ref   = 1.8;
    CL_TO_req   = 1.5;
    CLmax_land  = 2.4;
    T_W_TO      = (TA_mil / 4.4482216153) / W_TO_lbf; % rough MIL T/W at sea level

    % Runway requirement and altitudes
    Sa             = 450;    % [ft] landing allowance
    S_takeoff_req  = 4000;   % [ft]
    h_Elmendorf    = 213;
    h_Edwards      = 2311;
    h_TO_sweep     = linspace(0, 5000, 100);

    % ---- Baseline performance vs Mach at h_perf ----
    [T_perf, rho_perf, ~, P0_perf, a_perf, V_perf, q_perf, ~, theta0_perf] = ...
        atmos_and_flow(h_perf, M_vec, gamma, R_im, T_std);

    [T_mil_ray, T_AB_ray] = engine_thrust(T_SL_mil, T_SL_AB, n_eng, ...
                                          M_vec, theta0_perf, P0_perf, 1.0);

    [CL_perf, CD_perf, L_perf, D_perf, LD_perf, ~, ~] = ...
        aero_performance(W_S, beta_segment, q_perf, CDo, k1, k2, S_ref_ft2);

    PR     = D_perf .* V_perf;
    PA_mil = T_mil_ray .* V_perf;
    PA_AB  = T_AB_ray  .* V_perf;

    RC_mil = (PA_mil - PR) / W_segment;
    RC_AB  = (PA_AB  - PR) / W_segment;
    SP_req = PR / W_segment;

    V_kt       = V_perf / 1.68781;
    RC_mil_fpm = RC_mil * 60;
    RC_AB_fpm  = RC_AB  * 60;

    % ---- L/D vs Mach with max point ----
    M_LD = linspace(0.5, 2.0, 50);
    [~, rho_LD, ~, ~, a_LD, V_LD, q_LD, ~, ~] = ...
        atmos_and_flow(h_perf, M_LD, gamma, R_im, T_std);

    CL_LD = beta_segment * W_S ./ q_LD;
    CD_LD = CDo + k1.*CL_LD.^2 + k2.*CL_LD;
    L_LD  = CL_LD .* q_LD * S_ref_ft2;
    D_LD  = CD_LD .* q_LD * S_ref_ft2;
    LD_curve = L_LD ./ D_LD;

    [LD_max, idx_LDmax] = max(LD_curve);
    Mach_LD_max = M_LD(idx_LDmax);

    figure; hold on; grid on; box on;
    plot(M_LD, LD_curve, 'LineWidth', 2);
    plot(Mach_LD_max, LD_max, 'ro', 'MarkerFaceColor','r');
    xlabel('Mach'); ylabel('L/D');
    title(sprintf('L/D vs Mach (h = %.0f ft)', h_perf));
    text(Mach_LD_max, LD_max, ...
         sprintf('  Max L/D = %.2f at M=%.2f', LD_max, Mach_LD_max));

    % ---- Takeoff parameter vs altitude ----
    TOP_sweep      = zeros(size(h_TO_sweep));
    sigma_TO_sweep = zeros(size(h_TO_sweep));

    for i = 1:numel(h_TO_sweep)
        [~, rho_i, ~, ~, ~, ~, ~, ~, ~] = ...
            atmos_and_flow(h_TO_sweep(i), 0, gamma, R_im, T_std);
        sigma_TO_sweep(i) = rho_i / rho_SL;
        TOP_sweep(i)      = W_S ./ (sigma_TO_sweep(i)*CL_TO_ref*T_W_TO);
    end

    [~, rho_E, ~, ~, ~, ~, ~, ~, ~] = ...
        atmos_and_flow(h_Elmendorf, 0, gamma, R_im, T_std);
    sigma_Elmendorf = rho_E / rho_SL;
    TOP_Elmendorf   = W_S ./ (sigma_Elmendorf*CL_TO_ref*T_W_TO);

    [~, rho_ED, ~, ~, ~, ~, ~, ~, ~] = ...
        atmos_and_flow(h_Edwards, 0, gamma, R_im, T_std);
    sigma_Edwards = rho_ED / rho_SL;
    TOP_Edwards   = W_S ./ (sigma_Edwards*CL_TO_ref*T_W_TO);

    fprintf('\n==== Legacy Takeoff Part 1 – TOP ====\n');
    fprintf('TOP_Elmendorf = %.2f\n', TOP_Elmendorf);
    fprintf('TOP_Edwards   = %.2f\n', TOP_Edwards);

    figure; hold on; grid on; box on;
    plot(h_TO_sweep, TOP_sweep, 'LineWidth', 2);
    xlabel('Takeoff Altitude [ft]');
    ylabel('TOP = (W/S) / (\sigma C_{L,TO} T/W)');
    title('Takeoff Parameter vs Altitude');

    % ---- Required W/S for 4000-ft TO ----
    TOP_req_4000ft = 100;   % adjust per Fig. 5.4 if desired
    W_S_TO_req = TOP_req_4000ft * 1.0 * CL_TO_req * T_W_TO;

    fprintf('\n==== Legacy Takeoff Part 2 – Required W/S ====\n');
    fprintf('Required TOP (Fig. 5.4)    : %.1f\n', TOP_req_4000ft);
    fprintf('Required W/S for S_TO=%.0f : %.2f lb/ft^2\n', ...
            S_takeoff_req, W_S_TO_req);

    % ---- Thrust available vs required at some altitude ----
    h_TA  = h_perf;
    M_TA  = linspace(0.5, 2.0, 50);
    [~, rho_TA, ~, P0_TA, a_TA, V_TA, q_TA, ~, theta0_TA] = ...
        atmos_and_flow(h_TA, M_TA, gamma, R_im, T_std);

    [TA_dry, TA_wet] = engine_thrust(T_SL_mil, T_SL_AB, n_eng, ...
                                     M_TA, theta0_TA, P0_TA, 1.0);

    W_TA  = beta_segment * W_TO_lbf;
    CL_TA = (W_TA / S_ref_ft2) ./ q_TA;
    CD_TA = CDo + k1.*CL_TA.^2 + k2.*CL_TA;
    D_TA  = CD_TA .* q_TA * S_ref_ft2;

    figure; hold on; grid on; box on;
    plot(M_TA, TA_dry/1000, 'g-','LineWidth',2,'DisplayName','TA dry');
    plot(M_TA, TA_wet/1000, 'r-','LineWidth',2,'DisplayName','TA wet');
    plot(M_TA, D_TA /1000,  'b--','LineWidth',2,'DisplayName','Thrust req');
    xlabel('Mach number'); ylabel('Thrust [k lbf]');
    title(sprintf('Thrust Available and Required at h = %.0f ft', h_TA));
    legend('Location','best');

    % ---- Summary plots vs Mach / V ----
    figure; hold on; grid on; box on;
    plot(M_vec, D_perf/1000, '-o','DisplayName','Drag');
    plot(M_vec, T_mil_ray/1000,'-s','DisplayName','T_{MIL}');
    plot(M_vec, T_AB_ray /1000,'-^','DisplayName','T_{AB}');
    xlabel('Mach'); ylabel('Force [k lbf]');
    title(sprintf('Thrust and Drag (h = %.0f ft, \\beta = %.2f)', ...
          h_perf, beta_segment));
    legend('Location','best');

    figure; hold on; grid on; box on;
    plot(V_kt, RC_mil_fpm, '-o','DisplayName','MIL');
    plot(V_kt, RC_AB_fpm,  '-s','DisplayName','AB');
    xlabel('V [kt]'); ylabel('Rate of climb [ft/min]');
    title(sprintf('Rate of Climb vs V (h = %.0f ft, \\beta = %.2f)', ...
          h_perf, beta_segment));
    legend('Location','best');

    figure; hold on; grid on; box on;
    plot(V_kt, LD_perf, '-o');
    xlabel('V [kt]'); ylabel('L/D');
    title(sprintf('L/D vs V (h = %.0f ft, \\beta = %.2f)', ...
          h_perf, beta_segment));

    figure; hold on; grid on; box on;
    plot(V_kt, SP_req, '-o');
    xlabel('V [kt]'); ylabel('P_R / W [ft/s]');
    title(sprintf('Specific Power Required (h = %.0f ft, \\beta = %.2f)', ...
          h_perf, beta_segment));

    % ---- Simple payload–range / loiter trades (Breguet) ----
    if exist('plane','var')
        W_empty = plane.WE / 4.4482216153;  % N -> lbf
    else
        W_empty = 0.55 * W_TO_lbf;
    end

    W_payload_max = 0.18 * W_TO_lbf;
    payload_vec   = linspace(0, W_payload_max, 10);

    % range segment L/D & V
    [~, rho_R2, ~, P0_R2, a_R2, V_R2, q_R2, ~, theta0_R2] = ...
        atmos_and_flow(h_R2, M_R2, gamma, R_im, T_std);
    [T_mil_R2, ~] = engine_thrust(T_SL_mil, T_SL_AB, n_eng, ...
                                  M_R2, theta0_R2, P0_R2, 1.0); %#ok<NASGU>

    CL_R2 = beta_segment * W_S ./ q_R2;
    CD_R2 = CDo + k1.*CL_R2.^2 + k2.*CL_R2;
    L_R2  = CL_R2 .* q_R2 * S_ref_ft2;
    D_R2  = CD_R2 .* q_R2 * S_ref_ft2;
    LD_R2 = L_R2 ./ D_R2;

    V_kt_R2 = V_R2 / 1.68781;

    % loiter segment L/D
    [~, rho_loit, ~, ~, a_loit, V_loit, q_loit, ~, ~] = ...
        atmos_and_flow(h_loiter, M_loiter, gamma, R_im, T_std);
    CL_loit = beta_segment * W_S ./ q_loit;
    CD_loit = CDo + k1.*CL_loit.^2 + k2.*CL_loit;
    LD_loit = CL_loit ./ CD_loit;
    SFC_loit = SFC_hr;

    range_payload_nm_simple    = nan(size(payload_vec));
    t_loiter_payload_hr_simple = nan(size(payload_vec));

    for i = 1:numel(payload_vec)
        W_pay_i  = payload_vec(i);
        W_fuel_i = W_TO_lbf - W_empty - W_pay_i;

        if W_fuel_i <= 0
            continue;
        end

        Wi_i = W_TO_lbf;
        Wf_i = W_TO_lbf - W_fuel_i;

        range_payload_nm_simple(i) = (V_kt_R2 / SFC_hr) * LD_R2 * log(Wi_i/Wf_i);
        t_loiter_payload_hr_simple(i) = (1 / SFC_loit) * LD_loit * log(Wi_i/Wf_i);
    end

    figure; hold on; grid on; box on;
    plot(payload_vec, range_payload_nm_simple, '-o','LineWidth',2);
    xlabel('Payload [lbf]');
    ylabel('Range [nmi]');
    title('Payload–Range Trade (Breguet-style, MTOW Fixed)');

    figure; hold on; grid on; box on;
    plot(payload_vec, t_loiter_payload_hr_simple, '-o','LineWidth',2);
    xlabel('Payload [lbf]');
    ylabel('Loiter time [hr]');
    title(sprintf('Payload–Loiter Trade (h = %.0f ft, M = %.2f)', ...
          h_loiter, M_loiter));

    % ---- Simple constraint diagram T/W vs W/S ----
    W_S_vec = linspace(50, 200, 100);

    TOP_req   = TOP_req_4000ft;
    TW_takeoff = takeoff_constraint(W_S_vec, TOP_req, 1.0, CL_TO_req);

    [~, rho_land, ~, ~, ~, ~, ~, ~, ~] = ...
        atmos_and_flow(h_Elmendorf, 0, gamma, R_im, T_std);
    WS_land_max = landing_WS_limit(S_takeoff_req, Sa, rho_land, CLmax_land);

    TW_cruise = cruise_constraint(W_S_vec, h_cruise, M_cruise, ...
                                  gamma, R_im, T_std, ...
                                  CDo, k1, k2, ...
                                  T_SL_mil, T_SL_AB, n_eng, 1.0);

    % approximate service ceiling
    h_grid = linspace(0, 60000, 40);
    RC_req_service = 100/60;
    [h_service, RC_max_alt] = service_ceiling_estimate( ...
        h_grid, gamma, R_im, T_std, ...
        W_S, beta_segment, S_ref_ft2, ...
        CDo, k1, k2, ...
        T_SL_mil, T_SL_AB, n_eng, 1.0, ...
        RC_req_service); %#ok<NASGU>

    TW_ceiling = ceiling_constraint(W_S_vec, h_service, ...
                                    gamma, R_im, T_std, ...
                                    CDo, k1, k2, ...
                                    T_SL_mil, T_SL_AB, n_eng, 1.0);

    figure; hold on; grid on; box on;
    plot(W_S_vec, TW_takeoff, 'r-','LineWidth',2,'DisplayName','Takeoff');
    plot(W_S_vec, TW_cruise,  'b-','LineWidth',2,'DisplayName','Cruise');
    plot(W_S_vec, TW_ceiling, 'g-','LineWidth',2,'DisplayName','Ceiling');
    yline(T_W_TO,'w--','DisplayName','Current T/W');
    xline(W_S,   'w-.','DisplayName','Current W/S');
    xlabel('Wing loading W/S [lb/ft^2]');
    ylabel('Thrust loading T/W [-]');
    title('Constraint Diagram (Takeoff, Cruise, Ceiling)');
    legend('Location','best');

    fprintf('NOTE: Landing constraint gives W/S_max ≈ %.1f lb/ft^2.\n', WS_land_max);
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

%% ======= Legacy Raymer-style helper functions (imperial units) =====

function [T, rho, P, P0, a, V, q, theta, theta0] = ...
    atmos_and_flow(h_ft, M_vec, gamma, R_im, T_std)

if h_ft < 36152       % troposphere
    T   = 518.69 - 0.00356*h_ft;                 
    rho = 0.002377 * (T/518.69)^(-(1 + ...
          32.2/(-0.00356*1716)));                
else                  % isothermal
    T   = 389.99;                                
    rho = 0.000706 * exp(-32.2/1716/389.99 * ...
          (h_ft - 36152));                       
end

a   = sqrt(gamma*R_im*T);                        
V   = M_vec * a;                                 
q   = 0.5 * rho .* V.^2;                         

theta  = T / T_std;
theta0 = theta .* (1 + (gamma-1)/2 .* M_vec.^2);

P  = rho*R_im*T / 2116.2;                        
P0 = P .* (1 + (gamma-1)/2 .* M_vec.^2) ...
       .^(gamma/(gamma-1));                      
end

function [T_mil, T_AB] = engine_thrust(T_SL_mil, T_SL_AB, n_eng, ...
                                       M_vec, theta0, P0, TR)

R_mil = zeros(size(M_vec));
R_AB  = zeros(size(M_vec));

idx1 = theta0 <= TR;
idx2 = theta0 >  TR;

R_mil(idx1) = P0(idx1) .* (1 - 0.3 .* M_vec(idx1));
R_mil(idx2) = P0(idx2) .* (1 - 0.3 .* M_vec(idx2) ...
                           - 1.7 ./ theta0(idx2) .* (theta0(idx2)-TR));

R_AB(idx1)  = P0(idx1) .* (1 - 0.1 .* sqrt(M_vec(idx1)));
R_AB(idx2)  = P0(idx2) .* (1 - 0.1 .* sqrt(M_vec(idx2)) ...
                           - 2.2 ./ theta0(idx2) .* (theta0(idx2)-TR));

T_mil = (T_SL_mil * n_eng) .* R_mil;
T_AB  = (T_SL_AB  * n_eng) .* R_AB;
end

function [CL, CD, L, D, LD, DL, gamma_g] = ...
    aero_performance(W_S, beta, q, CDo, k1, k2, S_ref)

CL = beta * W_S ./ q;
CD = CDo + k1.*CL.^2 + k2.*CL;

L  = CL .* q * S_ref;
D  = CD .* q * S_ref;

LD      = L ./ D;
DL      = 1 ./ LD;
gamma_g = atan(DL);
end

function [h_service, RC_max_alt] = service_ceiling_estimate( ...
    h_grid, gamma, R_im, T_std, ...
    W_S, beta, S_ref, ...
    CDo, k1, k2, ...
    T_SL_mil, T_SL_AB, n_eng, TR, ...
    RC_req)

RC_max_alt = zeros(size(h_grid));

for i = 1:numel(h_grid)
    M_vec = linspace(0.3, 1.5, 40);
    [~, rho, ~, P0, ~, V, q, ~, theta0] = ...
        atmos_and_flow(h_grid(i), M_vec, gamma, R_im, T_std);

    [~, T_AB] = engine_thrust(T_SL_mil, T_SL_AB, n_eng, ...
                              M_vec, theta0, P0, TR);
    T_av = T_AB;

    CL = beta * W_S ./ q;
    CD = CDo + k1.*CL.^2 + k2.*CL;
    D  = CD .* q * S_ref;

    W   = beta * W_S * S_ref;
    PA  = T_av .* V;
    PR  = D    .* V;
    RC  = (PA - PR) / W;
    RC_max_alt(i) = max(RC);
end

idx = find(RC_max_alt >= RC_req, 1, 'last');
if isempty(idx)
    h_service = NaN;
else
    h_service = h_grid(idx);
end
end

function TW = takeoff_constraint(W_S_vec, TOP, sigma, CL_TO)
TW = W_S_vec ./ (sigma * CL_TO * TOP);
end

function WS_max = landing_WS_limit(S_L, Sa, rho_alt, CLmax)
rho_SL = 0.002377;
sigma  = rho_alt / rho_SL;
WS_max = (S_L - Sa) * sigma * CLmax / 80;
end

function TW = cruise_constraint(W_S_vec, h_ft, M, ...
                                gamma, R_im, T_std, ...
                                CDo, k1, k2, ...
                                T_SL_mil, T_SL_AB, n_eng, TR)

TW = zeros(size(W_S_vec));

for i = 1:numel(W_S_vec)
    [~, rho, ~, P0, ~, V, q, ~, theta0] = ...
        atmos_and_flow(h_ft, M, gamma, R_im, T_std);
    [T_mil, ~] = engine_thrust(T_SL_mil, T_SL_AB, n_eng, ...
                               M, theta0, P0, TR);

    W_S = W_S_vec(i);
    CL  = W_S ./ q;
    CD  = CDo + k1.*CL.^2 + k2.*CL;
    D   = CD .* q;

    TW(i) = (D * S_ref_equiv(S_L_dummy())) / W_S; %#ok<NASGU>
    % The above is a placeholder; simpler is:
    TW(i) = D / W_S;
end
end

function TW = ceiling_constraint(W_S_vec, h_ft, ...
                                 gamma, R_im, T_std, ...
                                 CDo, k1, k2, ...
                                 T_SL_mil, T_SL_AB, n_eng, TR)

M_ceiling = 0.8;
TW = zeros(size(W_S_vec));

for i = 1:numel(W_S_vec)
    [~, rho, ~, P0, ~, V, q, ~, theta0] = ...
        atmos_and_flow(h_ft, M_ceiling, gamma, R_im, T_std);
    [~, T_AB] = engine_thrust(T_SL_mil, T_SL_AB, n_eng, ...
                              M_ceiling, theta0, P0, TR);
    W_S = W_S_vec(i);
    CL  = W_S ./ q;
    CD  = CDo + k1.*CL.^2 + k2.*CL;
    D   = CD .* q;
    TW(i) = D / W_S;
end
end

% Dummy helpers to keep cruise_constraint simple (can be cleaned up)
function S = S_L_dummy(), S = 1; end
function Sref = S_ref_equiv(~), Sref = 1; end
