%{
======================================================================
 TODO / NOT-YET-IMPLEMENTED FEATURES FOR THIS SCRIPT
======================================================================
This script already covers a lot of single-point / "sanity check"
performance for a naval strike fighter: thrust/drag vs Mach, ROC and
service ceiling estimates, TOP-based takeoff sizing, a landing estimate,
max Mach estimate, Ps at a point, simple mission-level L/D checks, and a
few global metrics (stall speeds, climb, etc.).

In the *full* workflow, this script is meant to sit alongside:
  • planeObj  – holds geometry, aero, and propulsion models.
  • flightSegment2 – does segment-by-segment fuel fractions.
  • mission / sizeAircraft – runs full missions and sizing loops
    (F-18E example).

Below is what this script does *not* do by itself, and how the other
tools already help or could be hooked in.

----------------------------------------------------------------------
1) Full mission fuel bookkeeping (segment-by-segment)
----------------------------------------------------------------------
Status:
  • planeObj + flightSegment2 + mission already implement the full
    segment loop:
      – TAKEOFF, CLIMB, CRUISE, LOITER, COMBAT, LANDING
      – W_in → W_out, WF, fuel_burned, plus segment info
  • The F-18E sizing script shows how to chain segments and solve
    ferry / strike missions, then feed results into sizeAircraft.

Missing *in this script*:
  • A direct mission driver loop; here we only do Breguet-style single
    segments and "representative" mission L/D checks.

What would be needed (if you want it fully self-contained here):
  • A small mission definition (array of segment structs) and a wrapper
    that either:
      – Calls flightSegment2/planeObj/mission, or
      – Replicates the same logic with the local Breguet formulas.

----------------------------------------------------------------------
2) AR / S_wet / S_ref sweeps tied to mission closure
----------------------------------------------------------------------
Status:
  • planeObj already:
      – Builds S_wet, CD0, k1, k2 from geometry and Raymer-style
        regressions.
      – Handles loadouts (external stores) and their CD0/weight impact.
  • mission + flightSegment2 already provide a "mission closure" check
    via WTO_next, fuel_burned, and W_end.

Missing:
  • A sweep in this script over AR, S_wet (or scalar corrections), and
    S_ref that:
      – Rebuilds the polar (CD0, k1, k2) via planeObj-like logic.
      – Calls a mission solver (e.g., mission/flightSegment2) to see
        which combinations actually close the naval strike mission.

Needed:
  • A geometry/performance wrapper that:
      – For each (AR, SWET_scalar, Sref) set, builds a planeObj-style
        polar (or directly instantiates a planeObj).
      – Runs a mission object (like the F-18E ferry/strike examples).
      – Records pass/fail and key metrics for plotting design spaces.

----------------------------------------------------------------------
3) Full TOFL / LFL curves and constraint plots
----------------------------------------------------------------------
Status:
  • This script uses:
      – Raymer TOP definition for single-point TOFL at Elmendorf /
        Edwards.
      – Raymer 5.11 for a single landing field length estimate.
  • planeObj has takeoff/landing speed calculation, but not full
    TOFL/LFL vs W/S curves by itself.

Missing:
  • TOFL vs W/S, altitude, and T/W surfaces/curves for naval carriers
    and shore-based runways.
  • LFL vs W/S and field elevation curves feeding into constraint plots
    and sizing (to match what sizeAircraft does for the F-18E).

Needed:
  • Simple wrappers that:
      – Loop over W/S and sigma and map TOP → S_TO.
      – Loop over W/S and h and apply Raymer 5.11 for landing.
      – Overlay these with T/W constraint curves already computed
        here.

----------------------------------------------------------------------
4) Sustained turn performance and Ps-based envelopes
----------------------------------------------------------------------
Status:
  • planeObj already has:
      – calcExcessPower, calcMaxExcessPower, calcMaxClimbRate,
        getMaxTurn, calcMaxAlt, calcMaxMach, etc.
      – These give Ps, sustained climb, and turn metrics vs (M, h, W,
        AB%).
  • This script currently only checks Ps at a single (M, h) point and
    prints pass/fail against a Ps_req.

Missing:
  • A sustained-turn envelope (Ps ≥ 0) in the (V, h) or (n, V) plane.
  • A clean "instantaneous vs sustained" turn-rate comparison plot.

Needed:
  • A loop over M (or V) and h that calls planeObj.calcExcessPower
    (AB and MIL) and:
      – Filters Ps ≈ 0 for sustained turn.
      – Computes n, turn rate, and radius for instantaneous vs
        sustained and plots envelopes.

----------------------------------------------------------------------
5) More detailed payload trades and external stores effects
----------------------------------------------------------------------
Status:
  • planeObj.applyLoadout already propagates:
      – CD0_Payload, W_P, W_Tanks and updates CD0.
  • mission + flightSegment2 already let you:
      – Run ferry vs strike missions with different loadouts and see
        WTO_next, fuel_burned, and W_end (F-18E example).

Missing:
  • A compact payload–range / payload–loiter "frontier" plot inside
    this script for the naval strike fighter.

Needed:
  • A loop over payload cases (different loadouts / W_P / W_Tanks):
      – Build a planeObj with that loadout.
      – Run one or more mission objects or findTotalMaxRange /
        findTotalMaxEndurance.
      – Plot range vs payload and loiter vs payload for quick trades.

----------------------------------------------------------------------
6) Glide and engine-out performance
----------------------------------------------------------------------
Status:
  • The CL–CD polar and L/D logic exist (both here and in planeObj).

Missing:
  • Explicit "engine-out" / power-off glide mode:
      – Best-glide speed and L/D vs weight.
      – Glide range from a given altitude (useful for divert /
        recovery studies).

Needed:
  • A simple wrapper that sets thrust = 0 and:
      – Uses the polar to find CL for best L/D.
      – Computes corresponding V, descent angle, and glide range
        from a chosen altitude.

----------------------------------------------------------------------
7) Documentation / references for report integration
----------------------------------------------------------------------
Status:
  • The computations in this script mostly follow Raymer, but only a
    few are explicitly tagged with sources.

Missing:
  • Systematic inline references from each major equation back to
    Raymer (or other sources) to support a design report and future
    traceability.

Needed:
  • Comment tags such as:
      – % Raymer Eq. 3.21 – drag polar
      – % Raymer Fig. 5.4 – TOP vs T/W
      – % Raymer Eq. 17.23 – Breguet range
    placed next to each key calculation, plus a brief summary
    section in the write-up describing how this script, planeObj,
    flightSegment2, and mission/sizeAircraft all tie together.

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
aircraftName = "Naval Strike Fighter Concept";  % for printed output

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

% Range (Breguet) segment reference conditions
h_R2   = 40000;        % [ft]
M_R2   = 0.87;         % [-]

% Takeoff / landing CL and T/W (from aero + prop subteams)
CL_TO_ref   = 1.8;     % [-] CL in takeoff configuration (for TOP sweep)
CL_TO_req   = 1.5;     % [-] CL used for 4000-ft requirement
T_W_TO      = 0.71;    % [-] thrust-to-weight at takeoff
CLmax_land  = 2.4;     % [-] CLmax for landing configuration

% Runway allowance and required distances (Raymer 5.4/5.11)
Sa            = 450;   % [ft] added runway allowance for landing
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
TOP_req_4000ft = 100;            % dimensionless (approx; EDIT if needed)

% =====================================================================
%  USER INPUT – NAVAL STRIKE MISSION + WEIGHT BREAKDOWN  %% NEW
% ======================================================================
% High-level notional carrier-based strike mission (EDIT as needed)
R_outbound_nm = 400;    % [nmi] ship -> target
R_inbound_nm  = 400;    % [nmi] target -> ship (RTB)
R_mission_nm  = R_outbound_nm + R_inbound_nm;

t_combat_min  = 10;     % [min] on-station high-power maneuvering
t_loiter_min  = 20;     % [min] optional loiter time near carrier/target
reserve_fuel_frac = 0.05;  % 5% fuel reserve at landing (carrier recovery)

% Very rough naval-fighter weight fractions (EDIT with better data)
W_empty_frac   = 0.56;      % W_empty / W_TO (similar to F/A-18E class)
W_fuel_frac    = 0.29;      % internal + external fuel / W_TO
W_payload_frac = 1 - W_empty_frac - W_fuel_frac;

W_empty   = W_empty_frac   * W_TO;   % [lbf]
W_fuel    = W_fuel_frac    * W_TO;   % [lbf] fuel available for mission
W_payload = W_payload_frac * W_TO;   % [lbf] nominal strike payload

fprintf('\n==== Naval Strike Fighter Setup ====\n');
fprintf('Empty weight fraction   ~ %.2f (W_empty = %.0f lb)\n', ...
        W_empty_frac, W_empty);
fprintf('Fuel fraction           ~ %.2f (W_fuel  = %.0f lb)\n', ...
        W_fuel_frac,  W_fuel);
fprintf('Payload fraction        ~ %.2f (W_pay   = %.0f lb)\n', ...
        W_payload_frac, W_payload);
fprintf('Nominal strike mission  : %.0f + %.0f = %.0f nmi\n', ...
        R_outbound_nm, R_inbound_nm, R_mission_nm);

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

W_S_land = W_S;   % you can override if HW landing segment W/S differs

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

% For a mission-level check, use full fuel as "cruise-like" burn
Wi_R2  = W_TO;               % [lbf] start of mission
Wf_R2  = W_TO - W_fuel;      % [lbf] final "dry" weight (no fuel)

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
fprintf('Max range (all fuel)  : R_max_est ≈ %.1f nmi\n', R_max_est);

%% =====================================================================
%  MISSION-LEVEL REQUIRED L/D FOR NAVAL STRIKE (approx.)  %% NEW
% ======================================================================
% Treat whole mission as "Breguet-like" with effective L/D_mission.
% Required L/D such that: R_mission = (V/SFC)*(L/D)_req*ln(Wi/Wf)

LD_req_mission = (R_mission_nm * SFC) / (V_kt_R2 * log(Wi_R2 / Wf_R2));

fprintf('\n==== Mission-Level L/D Requirement (Naval Strike) ====\n');
fprintf('Required (L/D)_mission for %.0f nmi RT strike: %.2f\n', ...
        R_mission_nm, LD_req_mission);
fprintf('Available L/D at (h=%.0f ft, M=%.2f)        : %.2f\n', ...
        h_R2, M_R2, LD_R2);

if LD_R2 >= LD_req_mission
    fprintf('=> Current aero model CAN close the mission (L/D margin ≈ %.2f).\n', ...
            LD_R2 - LD_req_mission);
else
    fprintf('=> Current aero model CANNOT close the mission (L/D short by ≈ %.2f).\n', ...
            LD_req_mission - LD_R2);
end

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
CLmax_TO    = CL_TO_ref;
CLmax_Land  = CLmax_land;

% Densities at relevant altitudes
[~, rho_TO, ~, ~, ~, ~, ~, ~, ~] = ...
    atmos_and_flow(0, 0, gamma, R, T_std);         % sea level
[~, rho_clean, ~, ~, ~, ~, ~, ~, ~] = ...
    atmos_and_flow(h_perf, 0, gamma, R, T_std);    % clean cruise altitude
[~, rho_Land2, ~, ~, ~, ~, ~, ~, ~] = ...
    atmos_and_flow(h_Elmendorf, 0, gamma, R, T_std);

Vs_clean = stall_speed(W_S, CLmax_clean, rho_clean);   % [ft/s]
Vs_TO    = stall_speed(W_S, CLmax_TO,    rho_TO);
Vs_Land2 = stall_speed(W_S, CLmax_Land,  rho_Land2);

V_TO     = 1.2 * Vs_TO;                                % [ft/s] ~Raymer
V_Land   = 1.3 * Vs_Land2;                             % [ft/s] approach

fprintf('Stall speed (clean, h=%.0f ft): %.1f kt\n', ...
        h_perf, Vs_clean/1.68781);
fprintf('Stall speed (TO config, SL)   : %.1f kt\n', Vs_TO/1.68781);
fprintf('Stall speed (Landing, Elm)    : %.1f kt\n', Vs_Land2/1.68781);
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
Ps_req = 300;   % [ft/s] example Ps requirement
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
[T_loit, rho_loit2, ~, P0_loit, a_loit2, V_loit2, q_loit2, ~, theta0_loit] = ...
    atmos_and_flow(h_loiter, M_loiter, gamma, R, T_std);

CL_loit = beta_segment * W_S ./ q_loit2;
CD_loit = CDo + k1.*CL_loit.^2 + k2.*CL_loit;
LD_loit = CL_loit ./ CD_loit;

% Assume same SFC as cruise (EDIT if different loiter TSFC)
SFC_loit = SFC;  % [lbm/hr/lbf]

% Toy fuel fraction for loiter segment (EDIT with mission data)
Wi_loit = 0.85 * W_TO;
Wf_loit = 0.80 * W_TO;

t_loiter_hr = (1/SFC_loit) * LD_loit * log(Wi_loit/Wf_loit); % [hr]
fprintf('\nApproximate loiter time at h=%.0f ft, M=%.2f: t_loiter ≈ %.2f hr\n', ...
        h_loiter, M_loiter, t_loiter_hr);

fprintf('============================================================\n\n');

%% =====================================================================
%  TURN PERFORMANCE – Instantaneous (Naval Fighter)  %% NEW
% ======================================================================
% Simple instantaneous turn rate / radius at a maneuver altitude.
% Uses structural n_max and CLmax_maneuver.

h_turn = 15000;       % [ft] representative mid-altitude fight
n_max_struct = 7.5;   % [-] structural / pilot limit
CLmax_maneuver = 1.8; % [-] high-lift maneuvering CLmax

V_turn = linspace(200, 700, 40);  % [kt] maneuver speed range
V_turn_ft = V_turn * 1.68781;     % [ft/s]

[~, rho_turn, ~, ~, ~, ~, ~, ~, ~] = ...
    atmos_and_flow(h_turn, 0, gamma, R, T_std);

W_turn = beta_segment * W_S * S_ref;   % [lbf]
q_turn = 0.5 * rho_turn .* V_turn_ft.^2;

n_CLmax = CLmax_maneuver .* q_turn * S_ref ./ W_turn;
n_inst  = min(n_CLmax, n_max_struct * ones(size(n_CLmax)));
n_inst(n_inst < 1) = NaN;  % ignore below level-flight

g_ft = 32.174;  % [ft/s^2]

R_turn = V_turn_ft.^2 ./ (g_ft .* sqrt(max(n_inst.^2 - 1, 0)));  % [ft]
omega_turn = g_ft .* sqrt(max(n_inst.^2 - 1, 0)) ./ V_turn_ft;   % [rad/s]
omega_turn_deg = omega_turn * 180/pi;                            % [deg/s]

figure; hold on; grid on; box on;
plot(V_turn, omega_turn_deg, 'LineWidth',2);
xlabel('V [kt]');
ylabel('Instantaneous turn rate [deg/s]');
title(sprintf('Instantaneous Turn Performance (h = %.0f ft)', h_turn));

figure; hold on; grid on; box on;
plot(V_turn, R_turn/6076.12, 'LineWidth',2);
xlabel('V [kt]');
ylabel('Turn radius [nmi]');
title(sprintf('Instantaneous Turn Radius (h = %.0f ft)', h_turn));

%% =====================================================================
%  PAYLOAD PERFORMANCE TRADES – Range & Loiter vs Payload  %% NEW
% ======================================================================

% Sweep payload from 0 up to a "max naval load" (edit as needed)
W_payload_max = 0.18 * W_TO;  % 18% of MTOW as max strike payload (example)
payload_vec   = linspace(0, W_payload_max, 10);  % [lbf]

range_payload_nm       = nan(size(payload_vec));
t_loiter_payload_hr    = nan(size(payload_vec));

for i = 1:numel(payload_vec)
    W_pay_i = payload_vec(i);

    % Keep MTOW fixed (carrier catapult limit).
    % Increasing payload eats into fuel, empty weight held fixed.
    W_fuel_i = W_TO - W_empty - W_pay_i;

    if W_fuel_i <= 0
        % Infeasible (no fuel left)
        range_payload_nm(i)    = NaN;
        t_loiter_payload_hr(i) = NaN;
        continue;
    end

    Wi_i = W_TO;                % start of mission
    Wf_i = W_TO - W_fuel_i;     % "dry" weight (no mission fuel left)

    % Range with current L/D at (h_R2, M_R2)
    range_payload_nm(i) = (V_kt_R2 / SFC) * LD_R2 * log(Wi_i / Wf_i);

    % Loiter: assume same SFC and L/D_loit, all fuel available for loiter
    t_loiter_payload_hr(i) = (1 / SFC_loit) * LD_loit * log(Wi_i / Wf_i);
end

figure; hold on; grid on; box on;
plot(payload_vec, range_payload_nm, '-o','LineWidth',2);
xlabel('Payload [lbf]');
ylabel('Range [nmi]');
title('Payload–Range Trade (Naval Carrier MTOW Fixed)');

figure; hold on; grid on; box on;
plot(payload_vec, t_loiter_payload_hr, '-o','LineWidth',2);
xlabel('Payload [lbf]');
ylabel('Loiter time [hr]');
title(sprintf('Payload–Loiter Trade (h = %.0f ft, M = %.2f)', ...
      h_loiter, M_loiter));

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
%  OPTIONAL: Integration with planeObj / flightSegment2 (TEMPLATE ONLY)
% ======================================================================
% This section is commented out and just shows how you *could* call
% your class-based tools if you already have a planeObj and mission
% segments defined in SI units.
%
% Example (pseudo-code):
%
% % ---- create or fetch your planeObj (SI units) ----
% % fixed_input = ...; engine = ...;
% % WE_N = lb2N(W_empty);    % etc.
% % fighter = planeObj(fixed_input, "Hellstinger", WE_N, Lambda_LE_deg, ...
% %                    c_r_m, c_t_m, span_m, num_engine, engine, W_Fixed_N);
%
% % ---- build a mission from flightSegment2 objects ----
% % segs = [
% %   flightSegment2("TAKEOFF", NaN, NaN, NaN)
% %   flightSegment2("CLIMB",   0.8, ft2m(30000), NaN)
% %   flightSegment2("CRUISE",  NaN, NaN, R_outbound_nm*1852)
% %   flightSegment2("COMBAT",  0.8, ft2m(15000), [t_combat_min, 0.5])
% %   flightSegment2("CRUISE",  NaN, NaN, R_inbound_nm*1852)
% %   flightSegment2("LOITER",  NaN, NaN, t_loiter_min)
% %   flightSegment2("LANDING", NaN, NaN, NaN)
% % ];
% %
% % W_in = fighter.MTOW;
% % for k = 1:numel(segs)
% %     [W_out, WF_seg, fuel_seg, info_seg(k)] = segs(k).queryWF(W_in, fighter);
% %     W_in = W_out;
% % end
% % W_final = W_in;
% % fprintf('Class-based mission closure: W_final / W_TO = %.3f\n', W_final / fighter.MTOW);
%
% % ---- full performance envelope plots from planeObj ----
% % fighter.buildPlots(fighter.MTOW, 40);
%
% Keeping this here makes it easy to migrate the Raymer-style script
% into your class-based framework when you're ready.

%% =====================================================================
%  LOCAL FUNCTIONS (same as before)
% =====================================================================

% atmos_and_flow, engine_thrust, aero_performance, stall_speed,
% max_mach_estimate, service_ceiling_estimate, specific_excess_power,
% takeoff_constraint, landing_WS_limit, cruise_constraint, ceiling_constraint

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

function Vs = stall_speed(W_S, CLmax, rho)
% W/S = q * CL => Vs = sqrt(2*(W/S)/(rho*CL))
Vs = sqrt(2 * W_S ./ (rho * CLmax));  % [ft/s]
end

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

    [~, T_AB] = engine_thrust(T_SL_mil, T_SL_AB, n_eng, ...
                              M_vec, theta0, P0, TR);
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

function TW = takeoff_constraint(W_S_vec, TOP, sigma, CL_TO)
TW = W_S_vec ./ (sigma * CL_TO * TOP);
end

function WS_max = landing_WS_limit(S_L, Sa, rho_alt, CLmax)
rho_SL = 0.002377;               % must match main script
sigma  = rho_alt / rho_SL;

WS_max = (S_L - Sa) * sigma * CLmax / 80;
end

function TW = cruise_constraint(W_S_vec, h_ft, M, ...
                                gamma, R, T_std, ...
                                CDo, k1, k2, ...
                                T_SL_mil, T_SL_AB, n_eng, TR)

TW = zeros(size(W_S_vec));
for i = 1:numel(W_S_vec)
    [~, rho, ~, P0, ~, V, q, ~, theta0] = ...
        atmos_and_flow(h_ft, M, gamma, R, T_std);

    [T_mil, ~] = engine_thrust(T_SL_mil, T_SL_AB, n_eng, ...
                               M, theta0, P0, TR);   % MIL for cruise

    W_S = W_S_vec(i);
    CL  = W_S ./ q;                % beta≈1 for sizing
    CD  = CDo + k1.*CL.^2 + k2.*CL;
    D   = CD .* q;                 % per unit area [lb/ft^2]
    TW(i) = D / W_S;               % (D/S) / (W/S) = D/W
end
end

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
