%% =====================================================================
%  Performance & Mission Analysis – Generic Jet Fighter (F-16A default)
%  NOTE: Edit the parameter blocks below to reuse this script for
%        different aircraft and missions. Comments/Javadocs courtesy
%        of daddy chatgpt.
% ======================================================================

%{
======================================================================
 TODO / NOT-YET-IMPLEMENTED FEATURES FOR FULL PERFORMANCE TOOLBOX
======================================================================
This script implements a large portion of the required performance
analysis (cruise, climb, thrust vs drag, TOP, landing estimate, 
service ceiling estimate, Ps at a point, etc.). 

The following items are still missing or only partially implemented.
They will require additional models, inputs, or mission data to do 
properly. Use this as a roadmap for future extensions.

----------------------------------------------------------------------
1) Mission-level "required" L/D and AR / S_wet / S_ref bounds
----------------------------------------------------------------------
 • Minimum L/D that completes the *full mission*:
   - CURRENT: script computes available L/D (L/D vs Mach, max L/D).
   - MISSING: required (L/D)_mission that guarantees the mission 
     fuel fraction is feasible.
   - NEEDED:
       - Full mission profile (all segments: TO, climb, cruise,
         combat, loiter, return, reserves, etc.).
       - Assumed or computed segment fuel fractions (Raymer-style).
       - A way to back out the minimum effective L/D that still 
         closes the fuel fraction budget.

 • Range of AR / S_wet ratios that still complete the mission:
   - CURRENT: AR is fixed, S_wet not explicitly modeled.
   - MISSING: parametric sweep of AR and S_wet, with performance
     re-evaluation (drag polar changes, weight changes, etc.).
   - NEEDED:
       - Geometric / empirical model for wetted area S_wet as a
         function of wing planform, fuselage, tail, etc.
       - Method to update CD0 (and possibly k1, k2) when AR or 
         S_wet / S_ref changes.
       - Mission closure logic (fuel fraction check) for each 
         (AR, S_wet/S_ref) combination.

 • S_wet / S_ref ratio bounds that still complete the mission:
   - CURRENT: S_wet / S_ref not explicitly tracked.
   - MISSING: mapping from geometry/weights to S_wet/S_ref and 
     checking mission completion as above.
   - NEEDED: same items as AR/S_wet, plus a geometry/weights model 
     to relate S_wet/S_ref to empty weight and CD0.

----------------------------------------------------------------------
2) Full TOFL and LFL curves (beyond single-point estimates)
----------------------------------------------------------------------
 • Takeoff Field Length (TOFL) vs W/S, altitude, or T/W:
   - CURRENT: single-point estimates from Raymer Fig. 5.4 for 
     specific TOP values and airfields.
   - MISSING: continuous TOFL curves (e.g., TOFL vs W/S or TOFL vs 
     TOP) for plotting and trade studies.
   - NEEDED:
       - Either:
         (a) an analytical TOFL model (Raymer Ch. 5), or
         (b) a digitized / tabulated version of Fig. 5.4 for several
             TOP values.
       - Clear assumptions about runway condition (dry, paved) and
         rotation / lift-off criteria.

 • Landing Field Length (LFL) curves:
   - CURRENT: single Raymer 5.11 estimate at one altitude / W/S.
   - MISSING: LFL vs W/S, vs altitude, and possibly vs CLmax_land.
   - NEEDED:
       - Same Raymer 5.11 relation applied across a grid of W/S and/or
         altitude values.
       - Optional: correction factors for runway surface conditions.

----------------------------------------------------------------------
3) Detailed turn performance & Ps-based constraints
----------------------------------------------------------------------
 • Instantaneous & Sustained turn performance:
   - CURRENT: Ps at one (M, h) is computed, but not integrated into 
     a full turn-rate model.
   - MISSING:
       - Instantaneous turn rate and radius as functions of speed, 
         n_max, CLmax.
       - Sustained turn rate/radius vs speed and altitude using Ps>=0 
         (or Ps_req).
       - Time to complete 1 turn (360 deg) for both instantaneous and 
         sustained.
   - NEEDED:
       - Chosen max load factor n_max (structural / pilot).
       - CLmax for turn configuration (clean or maneuvering).
       - Ps requirement(s) for sustained turn (e.g., Ps>=0 or Ps>=Ps_req).
       - Functions to compute omega_turn = V/R and R_turn from n and V.

 • Ps-based constraint analysis:
   - CURRENT: Ps is computed at one point for a simple check.
   - MISSING:
       - Ps(M, h) maps over a grid for constraint plotting.
       - Ps-based lines on the T/W vs W/S constraint diagram 
         (e.g., lines where Ps = 0 or Ps = Ps_req).
   - NEEDED:
       - Ps(M, h, W/S, T/W) function generalized with n as a parameter.
       - Loop over W/S and T/W to find contours where Ps equals a 
         specified requirement.

----------------------------------------------------------------------
4) Multi-surface takeoff/landing performance
----------------------------------------------------------------------
 • TOFL and LFL on different surfaces:
   - CURRENT: only a nominal dry, paved condition implied.
   - MISSING: adjustments for wet, icy, grass, sand, or improvised 
     surfaces.
   - NEEDED:
       - Friction coefficients or correction factors for each surface
         type (from Raymer or another reference).
       - Functions that scale TOFL and LFL from the dry/paved baseline
         to each surface condition.

----------------------------------------------------------------------
5) Payload performance trades
----------------------------------------------------------------------
 • Range, loiter, climb, turn performance vs payload:
   - CURRENT: payload is not explicitly varied; W_TO is fixed.
   - MISSING:
       - Payload-range diagrams (range vs payload).
       - Loiter time vs payload.
       - Turn/climb capability vs payload.
   - NEEDED:
       - Weight breakdown: W_empty, W_fuel, W_payload.
       - Rules for how added payload replaces fuel, or increases 
         gross weight.
       - Recalculation of W/S and T/W for each payload case.
       - Re-run Breguet range/loiter, Ps, turn, climb performance 
         for each case.

 • Impact on empty weight estimate:
   - CURRENT: no built-in empty-weight estimation.
   - NEEDED:
       - Empirical weight equations (Raymer Part II) to relate 
         geometry, AR, S_wet, engine choice, and payload to empty
         weight.
       - Coupling between empty-weight changes and performance
         (through W/S and T/W).

----------------------------------------------------------------------
6) Mission-level constraint & "completion" checks
----------------------------------------------------------------------
 • Mission closure / "does this concept complete the mission?":
   - CURRENT: individual segments (cruise, loiter) are analyzed, but
     a full mission fuel-balance check is not implemented.
   - MISSING:
       - A mission analysis driver that steps through all segments,
         applies fuel fractions (or integrates fuel burn via TSFC and
         thrust), and checks that final weight is acceptable given
         reserves.
       - A formal "pass/fail" flag for whether a given (W/S, T/W,
         AR, S_wet/S_ref, payload) design completes the mission.
   - NEEDED:
       - Mission segment definitions (altitude, Mach, duration or
         distance, load factors, etc.).
       - Fuel fraction or fuel-burn models per segment.
       - Reserve and diversion policies.

----------------------------------------------------------------------
7) Glide performance & drag polar extensions
----------------------------------------------------------------------
 • Glide performance beyond best L/D:
   - CURRENT: L/D and glide angle can be computed from existing 
     CL, CD; best L/D speed is implicit.
   - MISSING:
       - Glide polar (descent rate vs airspeed).
       - Glide range from a given altitude for power-off conditions.
   - NEEDED:
       - Explicit "power-off" mode (T=0) and chosen weight W.
       - Calculation of vertical speed = V * sin(gamma_g) and range 
         = h / tan(|gamma_g|).

----------------------------------------------------------------------
8) Documentation & data source references (Raymer)
----------------------------------------------------------------------
 • Many of the missing items are tied to:
   - Raymer "Aircraft Design: A Conceptual Approach"
     - Ch. 3–5 for performance, TO/landing, constraint plots.
     - Ch. 16–18 for weights and mission fuel fractions.
   - You should decide:
     - Which exact Raymer equations/figures you want to use for TOFL,
       LFL, Ps requirements, payload-range, etc.
     - How detailed your mission model needs to be for this class.

======================================================================
%}


clear; clc; close all;

% =====================================================================
%  USER INPUT – CONSTANTS (RARELY CHANGED)
% ======================================================================
gamma  = 1.4;      % ratio of specific heats [-]
R      = 1716;     % gas constant [ft·lbf/(slug·R)]
T_std  = 518.69;   % standard sea-level temperature [R]
TR     = 1.0;      % "break" parameter in engine model (piecewise curves)
rho_SL = 0.002377; % standard sea-level density [slug/ft^3]

% =====================================================================
%  USER INPUT – AIRCRAFT GEOMETRY & AERODYNAMICS  %% EDIT PER AIRCRAFT
% ======================================================================
aircraftName = "F-16A Block 10";  % just for printed output

S_ref  = 300;        % wing reference area [ft^2]
W_S    = 104.59;     % baseline design wing loading W/S [lb/ft^2]
AR     = 3.0;        % aspect ratio [-]

CDo    = 0.0170;     % parasite drag coefficient [-]
k1     = 0.1160;     % induced drag coefficient 1 [-]
k2     = -0.0063;    % induced drag coefficient 2 [-]

e_osw  = 1/(pi*AR*k1);  % Oswald efficiency inferred from k1

% =====================================================================
%  USER INPUT – ENGINE DATA (PER ENGINE)          %% EDIT PER AIRCRAFT
% ======================================================================
T_SL_mil = 15000;    % sea-level dry/MIL thrust [lbf]
T_SL_AB  = 23770;    % sea-level wet/AB thrust  [lbf]
n_eng    = 1;        % number of engines

% TSFC for range (Raymer-style); can be changed per mission if needed
TSFC_total = 0.00019;  % [lbm/s] total fuel flow at sea-level dry power

% =====================================================================
%  USER INPUT – MISSION / SEGMENT DEFINITIONS     %% EDIT PER AIRCRAFT
% ======================================================================
% Global weight fraction used in most segments
beta_segment = 0.90;   % W_segment / W_TO for current performance calc

% Takeoff gross weight (for range/Breguet, etc.)
W_TO = 28992;          % [lbf] gross takeoff weight

% Loiter segment
h_loiter = 25000;      % [ft]
M_loiter = 0.40;       % [-]

% Cruise segment (for W/S optimum)
h_cruise = 35000;      % [ft]
M_cruise = 0.87;       % [-]
e_cruise = 0.914;      % Oswald factor used in cruise-range optimum
CD0_cruise = CDo;      % CD0 for cruise; replace with regression if you like

% Range (Breguet) segment
h_R2   = 40000;        % [ft]
M_R2   = 0.87;         % [-]
Wi_R2  = 0.90 * W_TO;  % [lbf] initial weight in range segment (EDIT)
Wf_R2  = 0.80 * W_TO;  % [lbf] final   weight in range segment (EDIT)

% Takeoff / landing CL and T/W (from aero + prop subteams)
CL_TO_ref   = 1.8;     % [-] CL in takeoff configuration (for TOP sweep)
CL_TO_req   = 1.5;     % [-] CL used for 4000-ft requirement
T_W_TO      = 0.71;    % [-] thrust-to-weight at takeoff
CLmax_land  = 2.4;     % [-] CLmax for landing configuration

% Runway allowance and required distances (Raymer 5.4/5.11)
Sa          = 450;     % [ft] added runway allowance for landing
S_takeoff_req = 4000;  % [ft] desired TO distance at sea level (req case)

% Field elevations for bases (ft)
h_Elmendorf = 213;     % Elmendorf AFB
h_Edwards   = 2311;    % Edwards AFB

% Effective performance altitude & Mach sweep
h_perf = 35000;                  % [ft] main performance altitude
M_vec  = linspace(0.5, 2.0, 15); % Mach sweep for base performance

% Takeoff parameter vs altitude sweep
h_TO_sweep = linspace(0, 5000, 100); % [ft]

% Thrust-available vs Mach sweep (can reuse h_perf or set separately)
h_TA = 35000;                     % [ft]
M_TA = linspace(0.5, 2.0, 50);    % Mach sweep

% TOP that corresponds to 4000-ft takeoff (1-engine jet, Raymer Fig. 5.4)
TOP_req_4000ft = 100;            % dimensionless (approx; EDIT if re-read chart)

%% =====================================================================
%  BASELINE PERFORMANCE @ h_perf (thrust, drag, ROC, etc.)
% ======================================================================
[T_perf, rho_perf, ~, P0_perf, a_perf, V_perf, q_perf, ~, theta0_perf] = ...
    atmos_and_flow(h_perf, M_vec, gamma, R, T_std);

[T_mil, T_AB] = engine_thrust(T_SL_mil, T_SL_AB, n_eng, ...
                              M_vec, theta0_perf, P0_perf, TR);

[CL_perf, CD_perf, L_perf, D_perf, LD_perf, ~, ~] = ...
    aero_performance(W_S, beta_segment, q_perf, CDo, k1, k2, S_ref);

W_segment = beta_segment * W_S * S_ref;   % weight in this segment [lbf]

PR     = D_perf .* V_perf;               % power required [ft·lbf/s]
PA_mil = T_mil   .* V_perf;              % power available (MIL)
PA_AB  = T_AB    .* V_perf;              % power available (AB)

RC_mil = (PA_mil - PR) / W_segment;      % [ft/s]
RC_AB  = (PA_AB  - PR) / W_segment;      % [ft/s]
SP_req = PR / W_segment;                 % [ft/s]

V_kt       = V_perf / 1.68781;           % [kt]
RC_mil_fpm = RC_mil * 60;                % [ft/min]
RC_AB_fpm  = RC_AB  * 60;                % [ft/min]

%% =====================================================================
%  ENDURANCE – Loiter W/S Optimum
% ======================================================================
[~, rho_loiter, ~, ~, a_loiter, V_loiter, q_loiter, ~, ~] = ...
    atmos_and_flow(h_loiter, M_loiter, gamma, R, T_std);

W_S_loiter = q_loiter .* sqrt(pi * AR * e_osw * CDo);

fprintf('[%s] Loiter W/S optimum:  W_S_loiter = %.3f lb/ft^2\n', ...
        aircraftName, W_S_loiter);

%% =====================================================================
%  LANDING – Preliminary Landing Distance (Raymer 5.11)
% ======================================================================
[~, rho_land, ~, ~, ~, ~, ~, ~, ~] = ...
    atmos_and_flow(h_Elmendorf, 0, gamma, R, T_std);  % Mach ~ 0

sigma_land = rho_land / rho_SL;

W_S_land = W_S;   % you can override if HW1 landing segment W/S differs

S_landing = 80 * W_S_land * (1/(sigma_land*CLmax_land)) + Sa;

fprintf('Landing distance estimate (Elmendorf): S_landing = %.1f ft\n', ...
        S_landing);

%% =====================================================================
%  L/D vs Mach – Max L/D and Mach location
% ======================================================================
M_LD = linspace(0.5, 2.0, 50);
[~, rho_LD, ~, ~, a_LD, V_LD, q_LD, ~, ~] = ...
    atmos_and_flow(h_perf, M_LD, gamma, R, T_std);

CL_LD = beta_segment * W_S ./ q_LD;
CD_LD = CDo + k1.*CL_LD.^2 + k2.*CL_LD;

L_LD  = CL_LD .* q_LD * S_ref;
D_LD  = CD_LD .* q_LD * S_ref;
LD_curve = L_LD ./ D_LD;

[LD_max, idx_LDmax] = max(LD_curve);
Mach_LD_max = M_LD(idx_LDmax);

fprintf('\n---- L/D vs Mach ----\n');
fprintf('Max L/D        = %.3f\n', LD_max);
fprintf('Mach at L/Dmax = %.3f\n', Mach_LD_max);

figure; hold on; grid on; box on;
plot(M_LD, LD_curve, 'LineWidth', 2);
plot(Mach_LD_max, LD_max, 'ro', 'MarkerFaceColor','r');
xlabel('Mach'); ylabel('L/D');
title(sprintf('L/D vs Mach (h = %.0f ft)', h_perf));
text(Mach_LD_max, LD_max, ...
     sprintf('  Max L/D = %.2f at M=%.2f', LD_max, Mach_LD_max));

%% =====================================================================
%  RANGE – Part 1: Cruise W/S Optimum (Raymer 5.14)
% ======================================================================
[~, rho_cruise, ~, ~, a_cruise, V_cruise, q_cruise, ~, ~] = ...
    atmos_and_flow(h_cruise, M_cruise, gamma, R, T_std);

W_S_cruise_opt = q_cruise * sqrt(pi * AR * e_cruise * CD0_cruise / 3);

fprintf('\n==== Cruise W/S optimum (Range Part 1) ====\n');
fprintf('q_cruise           = %.3f lb/ft^2\n', q_cruise);
fprintf('W/S_cruise_optimum = %.3f lb/ft^2\n', W_S_cruise_opt);
fprintf('h = %.0f ft, M = %.2f\n', h_cruise, M_cruise);

%% =====================================================================
%  RANGE – Part 2: Breguet Jet Range Estimate (Raymer 17.23)
% ======================================================================
[~, rho_R2, ~, P0_R2, a_R2, V_R2, q_R2, ~, theta0_R2] = ...
    atmos_and_flow(h_R2, M_R2, gamma, R, T_std);

[T_mil_R2, ~] = engine_thrust(T_SL_mil, T_SL_AB, n_eng, ...
                              M_R2, theta0_R2, P0_R2, TR);

T_dry_alt = T_mil_R2;           % available dry thrust at altitude

% TSFC_total [lbm/s] / T_SL_mil [lbf] -> [lbm/s/lbf] -> [lbm/hr/lbf]
SFC = (TSFC_total / T_SL_mil) * 3600;

CL_R2 = beta_segment * W_S ./ q_R2;
CD_R2 = CDo + k1.*CL_R2.^2 + k2.*CL_R2;
L_R2  = CL_R2 .* q_R2 * S_ref;
D_R2  = CD_R2 .* q_R2 * S_ref;
LD_R2 = L_R2 ./ D_R2;

V_kt_R2 = V_R2 / 1.68781;          % [kt] = nmi/hr

R_max_est = (V_kt_R2 / SFC) * LD_R2 * log(Wi_R2/Wf_R2);  % [nmi]

fprintf('\n==== Range Part 2 (Breguet Jet) ====\n');
fprintf('Dry thrust at %.0f ft: T_dry_alt = %.1f lbf\n', h_R2, T_dry_alt);
fprintf('L/D in segment        : %.2f\n', LD_R2);
fprintf('Range estimate        : R_max_est = %.1f nmi\n', R_max_est);

%% =====================================================================
%  TAKEOFF – Part 1: TOP vs Altitude, Elmendorf & Edwards
% ======================================================================
TOP_sweep = zeros(size(h_TO_sweep));
sigma_TO_sweep = zeros(size(h_TO_sweep));

for i = 1:numel(h_TO_sweep)
    [~, rho_i, ~, ~, ~, ~, ~, ~, ~] = ...
        atmos_and_flow(h_TO_sweep(i), 0, gamma, R, T_std);
    sigma_TO_sweep(i) = rho_i / rho_SL;
    TOP_sweep(i)      = W_S ./ (sigma_TO_sweep(i)*CL_TO_ref*T_W_TO);
end

% TOP at the two airfields
[~, rho_E, ~, ~, ~, ~, ~, ~, ~] = ...
    atmos_and_flow(h_Elmendorf, 0, gamma, R, T_std);
sigma_Elmendorf = rho_E / rho_SL;
TOP_Elmendorf   = W_S ./ (sigma_Elmendorf*CL_TO_ref*T_W_TO);

[~, rho_ED, ~, ~, ~, ~, ~, ~, ~] = ...
    atmos_and_flow(h_Edwards, 0, gamma, R, T_std);
sigma_Edwards = rho_ED / rho_SL;
TOP_Edwards   = W_S ./ (sigma_Edwards*CL_TO_ref*T_W_TO);

% Takeoff distances from Raymer Fig. 5.4 (1-engine jet, over 50 ft)
S_takeoff_Elmendorf = 3300;   % [ft] approx for TOP_Elmendorf ≈ 82
S_takeoff_Edwards   = 3500;   % [ft] approx for TOP_Edwards   ≈ 88

fprintf('\n==== Takeoff Part 1 – TOP ====\n');
fprintf('TOP_Elmendorf = %.2f  -> S_TO ≈ %.0f ft\n', ...
        TOP_Elmendorf, S_takeoff_Elmendorf);
fprintf('TOP_Edwards   = %.2f  -> S_TO ≈ %.0f ft\n', ...
        TOP_Edwards,   S_takeoff_Edwards);

figure; hold on; grid on; box on;
plot(h_TO_sweep, TOP_sweep, 'LineWidth', 2);
xlabel('Takeoff Altitude [ft]');
ylabel('TOP = (W/S) / (\sigma C_{L,TO} T/W)');
title('Takeoff Parameter vs Altitude');

%% =====================================================================
%  TAKEOFF – Part 2: Required W/S for 4000-ft Takeoff
% ======================================================================
sigma_TO = 1.0;   % sea-level density ratio

W_S_TO_req = TOP_req_4000ft * sigma_TO * CL_TO_req * T_W_TO;

fprintf('\n==== Takeoff Part 2 – Required W/S ====\n');
fprintf('Required TOP (from Fig. 5.4)    : %.1f\n', TOP_req_4000ft);
fprintf('Required W/S for S_TO = %.0f ft : W_S_TO_req = %.2f lb/ft^2\n', ...
        S_takeoff_req, W_S_TO_req);

%% =====================================================================
%  THRUST AVAILABLE & REQUIRED vs Mach at h_TA
% ======================================================================
[~, rho_TA, ~, P0_TA, a_TA, V_TA, q_TA, ~, theta0_TA] = ...
    atmos_and_flow(h_TA, M_TA, gamma, R, T_std);

[TA_dry, TA_wet] = engine_thrust(T_SL_mil, T_SL_AB, n_eng, ...
                                 M_TA, theta0_TA, P0_TA, TR);

W_TA = beta_segment * W_S * S_ref;
CL_TA = (W_TA / S_ref) ./ q_TA;
CD_TA = CDo + k1.*CL_TA.^2 + k2.*CL_TA;
D_TA  = CD_TA .* q_TA * S_ref;

fprintf('\n==== Thrust Available / Required at %.0f ft ====\n', h_TA);
fprintf('TA_dry(M=1.0) = %.1f lbf\n', interp1(M_TA, TA_dry, 1.0));
fprintf('TA_wet(M=1.0) = %.1f lbf\n', interp1(M_TA, TA_wet, 1.0));
fprintf('Drag  (M=1.0) = %.1f lbf\n', interp1(M_TA, D_TA,  1.0));

figure; hold on; grid on; box on;
plot(M_TA, TA_dry/1000, 'g-', 'LineWidth', 2, 'DisplayName','TA dry');
plot(M_TA, TA_wet/1000, 'r-', 'LineWidth', 2, 'DisplayName','TA wet');
plot(M_TA, D_TA/1000,  'b--','LineWidth', 2, 'DisplayName','Thrust required');
xlabel('Mach number'); ylabel('Thrust [k lbf]');
title(sprintf('Thrust Available and Required at h = %.0f ft', h_TA));
legend('Location','best');

%% =====================================================================
%  SUMMARY PLOTS vs Mach / Airspeed from BASELINE PERFORMANCE
% ======================================================================
figure; hold on; grid on; box on;
plot(M_vec, D_perf/1000, '-o','DisplayName','Drag');
plot(M_vec, T_mil/1000,'-s','DisplayName','T_{MIL}');
plot(M_vec, T_AB/1000, '-^','DisplayName','T_{AB}');
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

%% =====================================================================
%  HIGH-LEVEL GLOBAL METRICS & ENVELOPE
% ======================================================================

fprintf('\n================ GLOBAL PERFORMANCE METRICS ================\n');

% ---------- 1) Stall and takeoff speeds ----------
% Assume CLmax values for configs (EDIT with your aero numbers)
CLmax_clean = 1.4;      % [-] example
CLmax_TO    = CL_TO_ref;   % can reuse takeoff CL
CLmax_Land  = CLmax_land;

% Densities at relevant altitudes
[~, rho_TO, ~, ~, ~, ~, ~, ~, ~] = ...
    atmos_and_flow(0, 0, gamma, R, T_std);         % sea level
[~, rho_clean, ~, ~, ~, ~, ~, ~, ~] = ...
    atmos_and_flow(h_perf, 0, gamma, R, T_std);    % clean cruise altitude
[~, rho_Land, ~, ~, ~, ~, ~, ~, ~] = ...
    atmos_and_flow(h_Elmendorf, 0, gamma, R, T_std);

Vs_clean = stall_speed(W_S, CLmax_clean, rho_clean);   % [ft/s]
Vs_TO    = stall_speed(W_S, CLmax_TO,    rho_TO);
Vs_Land  = stall_speed(W_S, CLmax_Land,  rho_Land);

V_TO     = 1.2 * Vs_TO;                                % [ft/s] ~Raymer
V_Land   = 1.3 * Vs_Land;                              % [ft/s] approach

fprintf('Stall speed (clean, h=%.0f ft): %.1f kt\n', ...
        h_perf, Vs_clean/1.68781);
fprintf('Stall speed (TO config, SL)   : %.1f kt\n', Vs_TO/1.68781);
fprintf('Stall speed (Landing, Elm)    : %.1f kt\n', Vs_Land/1.68781);
fprintf('Takeoff speed estimate (SL)   : %.1f kt\n', V_TO/1.68781);
fprintf('Landing approach speed (Elm)  : %.1f kt\n', V_Land/1.68781);

% ---------- 2) Max Mach achievable at h_perf ----------
[Mach_max_est, M_grid, D_grid, T_grid] = ...
    max_mach_estimate(h_perf, gamma, R, T_std, ...
                      W_S, beta_segment, S_ref, ...
                      CDo, k1, k2, ...
                      T_SL_mil, T_SL_AB, n_eng, TR);

fprintf('\nEstimated max Mach at h = %.0f ft (AB thrust): M_max ≈ %.2f\n', ...
        h_perf, Mach_max_est);

% (Optional) plot D and T_AB vs Mach for that search
figure; hold on; grid on; box on;
plot(M_grid, D_grid/1000, 'b-', 'LineWidth', 2, 'DisplayName','Drag');
plot(M_grid, T_grid/1000, 'r-', 'LineWidth', 2, 'DisplayName','T_{AB}');
xlabel('Mach'); ylabel('Force [k lbf]');
title(sprintf('Max Mach Estimate at h = %.0f ft', h_perf));
legend('Location','best');

% ---------- 3) Service ceiling estimate ----------
RC_req_service = 100/60;   % [ft/s] typical service ceiling ROC = 100 ft/min
h_grid = linspace(0, 60000, 40);

[h_service, RC_max_alt] = service_ceiling_estimate( ...
    h_grid, gamma, R, T_std, ...
    W_S, beta_segment, S_ref, ...
    CDo, k1, k2, ...
    T_SL_mil, T_SL_AB, n_eng, TR, ...
    RC_req_service);

fprintf('\nService ceiling estimate (RC >= 100 ft/min): h_service ≈ %.0f ft\n', ...
        h_service);

% ---------- 4) Specific excess power check ----------
Ps_req = 300;   % [ft/s] example Ps requirement (EDIT with spec)
M_ps   = 0.9;   % Mach for Ps requirement
h_ps   = 20000; % altitude for Ps requirement

[Ps_val] = specific_excess_power(M_ps, h_ps, gamma, R, T_std, ...
                                 W_S, beta_segment, S_ref, ...
                                 CDo, k1, k2, ...
                                 T_SL_mil, T_SL_AB, n_eng, TR);

fprintf('\nSpecific excess power at M=%.2f, h=%.0f ft: Ps = %.1f ft/s\n', ...
        M_ps, h_ps, Ps_val);
if Ps_val >= Ps_req
    fprintf('=> Ps requirement (%.1f ft/s) satisfied.\n', Ps_req);
else
    fprintf('=> Ps requirement (%.1f ft/s) NOT satisfied.\n', Ps_req);
end

% ---------- 5) Loiter endurance estimate (Breguet endurance) ----------
% Simple single-segment loiter at (h_loiter, M_loiter)
[T_loit, rho_loit, ~, P0_loit, a_loit, V_loit, q_loit, ~, theta0_loit] = ...
    atmos_and_flow(h_loiter, M_loiter, gamma, R, T_std);

CL_loit = beta_segment * W_S ./ q_loit;
CD_loit = CDo + k1.*CL_loit.^2 + k2.*CL_loit;
LD_loit = CL_loit ./ CD_loit;

% Assume same SFC as cruise (EDIT if different loiter TSFC)
SFC_loit = SFC;  % [lbm/hr/lbf]

% toy fuel fraction for loiter segment (EDIT with mission data)
Wi_loit = 0.85 * W_TO;
Wf_loit = 0.80 * W_TO;

t_loiter_hr = (1/SFC_loit) * LD_loit * log(Wi_loit/Wf_loit); % [hr]
fprintf('\nApproximate loiter time at h=%.0f ft, M=%.2f: t_loiter ≈ %.2f hr\n', ...
        h_loiter, M_loiter, t_loiter_hr);

fprintf('============================================================\n\n');


%% =====================================================================
%  CONSTRAINT & ENVELOPE HELPERS (T/W vs W/S)
% ======================================================================

W_S_vec = linspace(50, 200, 100);   % [lb/ft^2] range of wing loading to study

% ---- Takeoff constraint (TOP-based) ----
TW_takeoff = takeoff_constraint(W_S_vec, TOP_req_4000ft, ...
                                1.0, CL_TO_req);  % sigma=1 at sea level

% ---- Landing constraint (upper bound on W/S) ----
WS_land_max = landing_WS_limit(S_takeoff_req, Sa, rho_SL, CLmax_land);

% ---- Cruise thrust constraint at (h_cruise, M_cruise) ----
TW_cruise = cruise_constraint(W_S_vec, h_cruise, M_cruise, ...
                              gamma, R, T_std, ...
                              CDo, k1, k2, ...
                              T_SL_mil, T_SL_AB, n_eng, TR);

% ---- Ceiling constraint (Ps≈0 at service ceiling altitude) ----
TW_ceiling = ceiling_constraint(W_S_vec, h_service, ...
                                gamma, R, T_std, ...
                                CDo, k1, k2, ...
                                T_SL_mil, T_SL_AB, n_eng, TR);

% ---- Plot constraint diagram (simple) ----
figure; hold on; grid on; box on;
plot(W_S_vec, TW_takeoff, 'r-', 'LineWidth', 2, 'DisplayName','Takeoff');
plot(W_S_vec, TW_cruise, 'b-', 'LineWidth', 2, 'DisplayName','Cruise');
plot(W_S_vec, TW_ceiling,'g-', 'LineWidth', 2, 'DisplayName','Ceiling');
yline(T_W_TO, 'w--','DisplayName','Current T/W');
xline(W_S,    'w-.','DisplayName','Current W/S');

xlabel('Wing loading W/S [lb/ft^2]');
ylabel('Thrust loading T/W [-]');
title('Constraint Diagram (Example)');
legend('Location','best');

fprintf('NOTE: Landing constraint gives W/S_max ≈ %.1f lb/ft^2 (upper bound).\n', ...
        WS_land_max);


%% =====================================================================
%  LOCAL FUNCTIONS
% =====================================================================

%{
/**
 * atmos_and_flow
 * Computes a simple standard-atmosphere model and basic flow properties
 * for a given altitude and Mach number (or Mach vector).
 *
 * @param h_ft   Geopotential altitude [ft]
 * @param M_vec  Mach number(s) (scalar or vector)
 * @param gamma  Ratio of specific heats [-]
 * @param R      Gas constant [ft·lbf/(slug·R)]
 * @param T_std  Standard sea-level temperature [R]
 *
 * @return T      Static temperature [R]
 * @return rho    Density [slug/ft^3]
 * @return P      Static pressure ratio p/p_SL [-]
 * @return P0     Stagnation pressure ratio p0/p0_SL [-]
 * @return a      Speed of sound [ft/s]
 * @return V      True airspeed [ft/s]
 * @return q      Dynamic pressure [lb/ft^2]
 * @return theta  Temperature ratio T/T_std [-]
 * @return theta0 Stagnation temperature ratio T0/T_std [-]
 */
%}
function [T, rho, P, P0, a, V, q, theta, theta0] = ...
    atmos_and_flow(h_ft, M_vec, gamma, R, T_std)

if h_ft < 36152       % troposphere
    T   = 518.69 - 0.00356*h_ft;                 % [R]
    rho = 0.002377 * (T/518.69)^(-(1 + ...
          32.2/(-0.00356*1716)));                % [slug/ft^3]
else                  % isothermal
    T   = 389.99;                                % [R]
    rho = 0.000706 * exp(-32.2/1716/389.99 * ...
          (h_ft - 36152));                       % [slug/ft^3]
end

a   = sqrt(gamma*R*T);                           % [ft/s]
V   = M_vec * a;                                 % [ft/s]
q   = 0.5 * rho .* V.^2;                         % [lb/ft^2]

theta  = T / T_std;
theta0 = theta .* (1 + (gamma-1)/2 .* M_vec.^2);

P  = rho*R*T / 2116.2;                           % p / p_SL
P0 = P .* (1 + (gamma-1)/2 .* M_vec.^2) ...
       .^(gamma/(gamma-1));                      % p0 / p0_SL
end

%{
/**
 * engine_thrust
 * Computes dry (MIL) and wet (AB) thrust available as a function of
 * Mach number and altitude using Raymer-style piecewise curve fits.
 *
 * @param T_SL_mil Sea-level dry/MIL thrust per engine [lbf]
 * @param T_SL_AB  Sea-level wet/AB thrust per engine [lbf]
 * @param n_eng    Number of engines [-]
 * @param M_vec    Mach number(s) (scalar or vector)
 * @param theta0   Stagnation temperature ratio T0/T_std [-]
 * @param P0       Stagnation pressure ratio p0/p0_SL [-]
 * @param TR       Break parameter for the curve [-]
 *
 * @return T_mil   MIL thrust available [lbf]
 * @return T_AB    AB thrust available  [lbf]
 */
%}
function [T_mil, T_AB] = engine_thrust(T_SL_mil, T_SL_AB, n_eng, ...
                                       M_vec, theta0, P0, TR)

R_mil = zeros(size(M_vec));
R_AB  = zeros(size(M_vec));

idx1 = theta0 <= TR;
idx2 = theta0 >  TR;

% Dry / MIL thrust ratio
R_mil(idx1) = P0(idx1) .* (1 - 0.3 .* M_vec(idx1));
R_mil(idx2) = P0(idx2) .* (1 - 0.3 .* M_vec(idx2) ...
                           - 1.7 ./ theta0(idx2) .* (theta0(idx2)-TR));

% Afterburner thrust ratio
R_AB(idx1)  = P0(idx1) .* (1 - 0.1 .* sqrt(M_vec(idx1)));
R_AB(idx2)  = P0(idx2) .* (1 - 0.1 .* sqrt(M_vec(idx2)) ...
                           - 2.2 ./ theta0(idx2) .* (theta0(idx2)-TR));

T_mil = (T_SL_mil * n_eng) .* R_mil;
T_AB  = (T_SL_AB  * n_eng) .* R_AB;
end

%{
/**
 * aero_performance
 * Computes CL, CD, lift, drag, and glide-related quantities for a
 * given wing loading, weight fraction, and set of dynamic pressures.
 *
 * @param W_S   Wing loading W/S [lb/ft^2]
 * @param beta  Weight fraction W_segment / W_TO [-]
 * @param q     Dynamic pressure [lb/ft^2] (scalar or vector)
 * @param CDo   Parasite drag coefficient [-]
 * @param k1    Induced drag coefficient 1 [-]
 * @param k2    Induced drag coefficient 2 [-]
 * @param S_ref Wing reference area [ft^2]
 *
 * @return CL      Lift coefficient [-]
 * @return CD      Drag coefficient [-]
 * @return L       Lift [lbf]
 * @return D       Drag [lbf]
 * @return LD      Lift-to-drag ratio L/D [-]
 * @return DL      Drag-to-lift ratio D/L [-]
 * @return gamma_g Glide angle [rad]
 */
%}
function [CL, CD, L, D, LD, DL, gamma_g] = ...
    aero_performance(W_S, beta, q, CDo, k1, k2, S_ref)

CL = beta * W_S ./ q;                       % CL = (W_i/S)/q
CD = CDo + k1.*CL.^2 + k2.*CL;

L  = CL .* q * S_ref;                       % [lbf]
D  = CD .* q * S_ref;                       % [lbf]

LD      = L ./ D;
DL      = 1 ./ LD;
gamma_g = atan(DL);
end

%{
/**
 * stall_speed
 * Computes stall speed for a given wing loading, CLmax, and density.
 *
 * @param W_S    Wing loading W/S [lb/ft^2]
 * @param CLmax  Maximum lift coefficient in the configuration [-]
 * @param rho    Air density [slug/ft^3]
 * @return Vs    Stall speed [ft/s]
 */
%}
function Vs = stall_speed(W_S, CLmax, rho)
g = 32.174;  % [ft/s^2]
% W/S = q * CL => Vs = sqrt(2*(W/S)/(rho*CL))
Vs = sqrt(2 * W_S ./ (rho * CLmax));  % [ft/s]
end

%{
/**
 * max_mach_estimate
 * Estimates maximum Mach at a given altitude where AB thrust equals drag.
 * Scans a Mach grid and finds last Mach where T_AB >= D.
 */
%}
function [Mach_max, M_scan, D_scan, T_scan] = max_mach_estimate( ...
    h_ft, gamma, R, T_std, ...
    W_S, beta, S_ref, ...
    CDo, k1, k2, ...
    T_SL_mil, T_SL_AB, n_eng, TR)

M_scan = linspace(0.2, 2.5, 80);
[~, rho, ~, P0, ~, V, q, ~, theta0] = ...
    atmos_and_flow(h_ft, M_scan, gamma, R, T_std);

[~, T_AB] = engine_thrust(T_SL_mil, T_SL_AB, n_eng, ...
                          M_scan, theta0, P0, TR);

CL = beta * W_S ./ q;
CD = CDo + k1.*CL.^2 + k2.*CL;
D  = CD .* q * S_ref;

idx = find(T_AB >= D, 1, 'last');
if isempty(idx)
    Mach_max = NaN;
else
    Mach_max = M_scan(idx);
end

D_scan = D;
T_scan = T_AB;
end

%{
/**
 * service_ceiling_estimate
 * Estimates service ceiling by scanning altitudes and finding the
 * highest altitude where maximum rate of climb >= RC_req.
 *
 * @param h_grid   Vector of candidate altitudes [ft]
 * @param RC_req   Required ROC [ft/s] (e.g. 100 ft/min = 100/60)
 */
%}
function [h_service, RC_max_alt] = service_ceiling_estimate( ...
    h_grid, gamma, R, T_std, ...
    W_S, beta, S_ref, ...
    CDo, k1, k2, ...
    T_SL_mil, T_SL_AB, n_eng, TR, ...
    RC_req)

RC_max_alt = zeros(size(h_grid));

for i = 1:numel(h_grid)
    M_vec = linspace(0.3, 1.5, 40);
    [~, rho, ~, P0, ~, V, q, ~, theta0] = ...
        atmos_and_flow(h_grid(i), M_vec, gamma, R, T_std);

    [T_mil, T_AB] = engine_thrust(T_SL_mil, T_SL_AB, n_eng, ...
                                  M_vec, theta0, P0, TR);
    % use AB for ceiling
    T_av = T_AB;

    CL = beta * W_S ./ q;
    CD = CDo + k1.*CL.^2 + k2.*CL;
    D  = CD .* q * S_ref;

    W   = beta * W_S * S_ref;
    PA  = T_av .* V;
    PR  = D    .* V;
    RC  = (PA - PR) / W;            % [ft/s]
    RC_max_alt(i) = max(RC);
end

idx = find(RC_max_alt >= RC_req, 1, 'last');
if isempty(idx)
    h_service = NaN;
else
    h_service = h_grid(idx);
end
end

%{
/**
 * specific_excess_power
 * Computes specific excess power Ps = V * (T/W - D/W) at given M, h.
 */
%}
function Ps = specific_excess_power(M, h_ft, gamma, R, T_std, ...
                                    W_S, beta, S_ref, ...
                                    CDo, k1, k2, ...
                                    T_SL_mil, T_SL_AB, n_eng, TR)

[~, rho, ~, P0, ~, V, q, ~, theta0] = ...
    atmos_and_flow(h_ft, M, gamma, R, T_std);

[~, T_AB] = engine_thrust(T_SL_mil, T_SL_AB, n_eng, ...
                          M, theta0, P0, TR);   % use AB for Ps

CL = beta * W_S ./ q;
CD = CDo + k1.*CL.^2 + k2.*CL;
D  = CD .* q * S_ref;

W  = beta * W_S * S_ref;

Ps = V .* (T_AB./W - D./W);   % [ft/s]
end

%{
/**
 * takeoff_constraint
 * Takeoff constraint line from TOP definition:
 *     TOP = (W/S) / (sigma * CL_TO * (T/W))
 *  =>  T/W = (W/S) / (sigma * CL_TO * TOP)
 */
%}
function TW = takeoff_constraint(W_S_vec, TOP, sigma, CL_TO)
TW = W_S_vec ./ (sigma * CL_TO * TOP);
end

%{
/**
 * landing_WS_limit
 * Landing field length constraint from Raymer eq. 5.11:
 *   S_L = 80 * (W/S) / (sigma * CLmax) + Sa
 *  => W/S_max = (S_L - Sa) * sigma * CLmax / 80
 */
%}
function WS_max = landing_WS_limit(S_L, Sa, rho_alt, CLmax)
rho_SL = 0.002377;               % must match main script
sigma  = rho_alt / rho_SL;

WS_max = (S_L - Sa) * sigma * CLmax / 80;
end

%{
/**
 * cruise_constraint
 * Simple cruise thrust constraint: T/W >= D/W at given (h, M).
 * Returns T/W as a function of W/S.
 */
%}
function TW = cruise_constraint(W_S_vec, h_ft, M, ...
                                gamma, R, T_std, ...
                                CDo, k1, k2, ...
                                T_SL_mil, T_SL_AB, n_eng, TR)

TW = zeros(size(W_S_vec));
for i = 1:numel(W_S_vec)
    [~, rho, ~, P0, ~, V, q, ~, theta0] = ...
        atmos_and_flow(h_ft, M, gamma, R, T_std);

    [T_mil, ~] = engine_thrust(T_SL_mil, T_SL_AB, n_eng, ...
                               M, theta0, P0, TR);   % use MIL for cruise

    W_S = W_S_vec(i);
    CL  = W_S ./ q;                % here beta≈1 for sizing
    CD  = CDo + k1.*CL.^2 + k2.*CL;
    D   = CD .* q;                 % per unit area [lb/ft^2]
    TW(i) = D / W_S;               % (D/S) / (W/S) = D/W
end
end

%{
/**
 * ceiling_constraint
 * Approximates a ceiling constraint as T/W >= D/W at given ceiling
 * altitude; more refined versions could enforce Ps ≈ 0 or RC_min.
 */
%}
function TW = ceiling_constraint(W_S_vec, h_ft, ...
                                 gamma, R, T_std, ...
                                 CDo, k1, k2, ...
                                 T_SL_mil, T_SL_AB, n_eng, TR)

M_ceiling = 0.8;   % assumed Mach at ceiling (EDIT if needed)
TW = zeros(size(W_S_vec));

for i = 1:numel(W_S_vec)
    [~, rho, ~, P0, ~, V, q, ~, theta0] = ...
        atmos_and_flow(h_ft, M_ceiling, gamma, R, T_std);
    [~, T_AB] = engine_thrust(T_SL_mil, T_SL_AB, n_eng, ...
                              M_ceiling, theta0, P0, TR);
    W_S = W_S_vec(i);
    CL  = W_S ./ q;          % beta≈1
    CD  = CDo + k1.*CL.^2 + k2.*CL;
    D   = CD .* q;           % per area
    TW(i) = D / W_S;        % D/W as before
end
end
