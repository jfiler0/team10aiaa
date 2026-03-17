%% Nicolai Chapter 20 Refined Weight Estimate
% Combined from the equations/screenshots you provided
% Default setup is for a USN strike fighter / attack aircraft
%
% Included:
%   Military / fighter / transport equations:
%     20.1b, 20.3a, 20.3b, 20.5, 20.7, 20.8-20.16, 20.22-20.30,
%     20.31-20.68
%   Light utility aircraft equations:
%     20.69-20.81
%
% Notes:
% - All weights are in lb
% - All lengths are in ft unless otherwise noted
% - Angles entered in degrees are converted internally to radians
% - Avionics and landing retardation devices are handled as the text indicates

clear; clc;
format compact;

%% =========================================================
%  USER SWITCHES
%  =========================================================

run_military_block      = true;   % USN strike fighter / attack / transport equations
run_light_utility_block = false;   % KEEP OFF; light utility aircraft equations

%% =========================================================
%  UNIT CONVERSIONS
%  =========================================================
ft2m = @(x) x*0.3048;
m2ft = @(x) x/0.3048;
deg2rad_local = @(x) x*pi/180;

%% =========================================================
%  COMMON INPUTS
%  =========================================================

% Overall aircraft
W_TO = 55000;          % takeoff weight [lb]
N    = 9.0*1.5;        % ultimate load factor. Usually max designed g's with 1.5 FS
M0   = 1.1;            % max Mach number at sea level
q    = 800;            % max dynamic pressure [lb/ft^2]

% Crew / occupants
N_CR   = 1;            % number of crew
N_PIL  = 1;            % number of pilots
N_PASS = 0;            % passengers
N_ATT  = 0;            % attendants
N_TRO  = 0;            % troops
N_BU   = 0;            % crew bunks
N_FDS  = 0;            % flight deck stations

% Fuselage basic geometry
L = 50;                % fuselage length [ft]
H = 9;                 % maximum fuselage height [ft]

% Electronics / avionics
% W_AU comes from a section in the book on light aicraft which doesn't
% apply to us. However, the code will break if it's not initialized
W_AU=0; 
W_TRON = 2500;   % installed avionics, Eq. (20.81)

% Engine data
N_E   = 2;             % number of engines
W_ENG = 3500;          % bare engine weight per engine [lb]

% Pressurization / cabin
P_c  = 0;              % ultimate cabin pressure [lb/in^2]
V_PR = 0;              % pressurized/occupied volume [ft^3]

%% =========================================================
%  MILITARY / FIGHTER / TRANSPORT BLOCK
%  =========================================================
if run_military_block

    fprintf('\n=========================================================\n');
    fprintf(' MILITARY / FIGHTER / TRANSPORT BLOCK\n');
    fprintf('=========================================================\n');

    %% ------------------------------------------------------
    %  INPUTS: STRUCTURE
    %  ------------------------------------------------------

    % Wing (USN fighter Eq. 20.1b)
    K_PIV     = 1.0;           % variable-sweep structural factor. 1.0 fixed wing, 1.175 variable sweep
    t_c       = 0.08;          % max wing thickness ratio
    Lambda_LE = 20;            % leading edge sweep [deg]
    AR        = 4.0;           % wing aspect ratio
    lambda    = 0.5;           % wing taper ratio
    S_w       = 1600;  % wing area [ft^2]

    % Horizontal tail
    S_HT      = 300;  % horizontal tail planform area [ft^2]
    t_R_HT    = 0.5;           % HT root thickness [ft]
    cbar_wing = 5.0;           % wing MAC [ft]
    L_t       = 15.0;          % tail moment arm [ft]
    b_HT      = 12;       % horizontal tail span [ft]

    % Vertical tail
    hT_hV     = 0.0;           % h_T/h_V, 1 for T-tail, 0 fuselage mounted HT
    S_VT      = 150;  % vertical tail area [ft^2]
    S_r       = 0.3*S_VT;      % rudder area [ft^2]. If unknown, use S_r=0.3*S_v
    AR_VT     = 1.5;           % VT aspect ratio
    lambda_V  = 0.4;           % VT taper ratio
    Lambda_VT = 35;            % VT quarter-chord sweep [deg]

    % Fuselage
    K_INL = 1.25;              % Inlets on fuselage structural factor. 1.25 for fuselage inlets, 1.0 otherwise (wing root, etc)

    %% ------------------------------------------------------
    %  INPUTS: PROPULSION / SUBSYSTEMS
    %  ------------------------------------------------------

    % Air induction
    N_i   = 2;         % number of inlets
    A_i   = 4.5;       % capture area per inlet [ft^2]
    L_d   = 8.0;       % subsonic duct length per inlet [ft]
    L_r   = 3.0;       % ramp length forward of throat per inlet [ft]
    P_2   = 35;        % max static pressure at compressor face [psia]
    K_GEO = 1.33;       % duct shape factor. 1.33 if two or more flat sides, 1.0 if round or only 1 flat side
    M_D   = M0;        % design Mach number

    if M_D < 3.0
        K_TE = 1.0; % K_TE is the temperature correction factor
    elseif M_D <= 6.0
        K_TE = (M_D + 2.0)/5.0;
    else
        K_TE = (M_D + 2.0)/5.0;
    end

    if M_D < 1.4
        K_M = 1.0; % K_M is the duct material factor
    else
        K_M = 1.5;
    end

    % Fuel system
    F_GW = 3000;       % total wing fuel [gal]
    F_GF = 1500;       % total fuselage fuel [gal]

    % Engine controls
    L_f   = L;         % fuselage length [ft]
    K_ECO = 1.080;     % 0.686 non-A/B, 1.080 afterburning
    b     = sqrt(AR*S_w);   % wing span [ft]

    % Starting systems
    % W_ENG already defined above

    % Propeller systems
    N_p   = 0;         % number of propellers
    N_BL  = 0;         % blades per propeller
    d_p   = 0;         % propeller diameter [ft]
    HP    = 0;         % shaft horsepower
    K_p   = 24.00;     % propeller-engine coefficient

    %% ------------------------------------------------------
    %  INPUTS: CONTROLS / INSTRUMENTS / ELECTRICAL / FURNISHINGS / ACAI
    %  ------------------------------------------------------

    K_SC   = 138.18;   % USAF fighter with horizontal tail
    S_TOT  = 0;        % total surface control area [ft^2], bomber only

    K_SEA  = 149.12;   % ejection seat coefficient
    K_LAV  = 1.11;     % lavatory coefficient
    K_BUF  = 5.68;     % food provision coefficient
    K_CBC  = 0.0646;   % baggage/cargo handling coefficient
    K_ACAI = 108.64;   % ACAI coefficient
    M_E    = M0;       % equivalent max Mach at sea level

    %% ------------------------------------------------------
    %  MODES / SELECTIONS
    %  ------------------------------------------------------

    % Air induction selections
    use_internal_ducts          = true;
    use_variable_ramps          = false;
    use_half_round_fixed_spike  = false;
    use_full_round_spike        = false;
    use_trans_expand_spike      = false;
    use_external_turbojet_duct  = false;
    use_external_turbofan_duct  = false;

    % Engine controls mode
    % 1 = body / wing-root mounted jet
    % 2 = wing-mounted turbojet / turbofan
    % 3 = wing-mounted turboprop
    % 4 = wing-mounted reciprocating
    engine_control_mode = 1;

    % Starting system mode
    % 1 = one/two jet engines cartridge/pneumatic (F-18E uses this)
    % 2 = one/two jet engines electrical
    % 3 = four+ jet engines pneumatic
    % 4 = turboprop pneumatic
    % 5 = reciprocating electric
    start_mode = 1;

    % Propeller controls mode
    % 0 = none / jet aircraft
    % 1 = turboprop
    % 2 = reciprocating
    prop_ctrl_mode = 0;

    % Surface controls mode
    % 1 = USAF fighter
    % 2 = USN fighter/attack
    % 3 = executive/commercial transport
    % 4 = cargo/troop transport
    % 5 = bomber
    surface_ctrl_mode = 2;

    % Engine instrument mode
    % 1 = turbine
    % 2 = reciprocating
    engine_instr_mode = 1;

    % Electrical mode
    % 1 = USAF fighter
    % 2 = USN fighter/attack
    % 3 = bomber
    % 4 = transport
    electrical_mode = 2;

    % Furnishings mode
    % 1 = fighter/attack
    % 2 = bomber/observation
    % 3 = executive/commercial
    % 4 = military passenger
    % 5 = military troop-cargo
    furnishings_mode = 1;

    % ACAI mode
    % 1 = fighter high-sub/supersonic
    % 2 = fighter subsonic
    % 3 = bomber/military transport
    % 4 = executive/commercial
    acai_mode = 1;

    %% ------------------------------------------------------
    %  ANGLE CONVERSIONS
    %  ------------------------------------------------------
    Lambda_LE_rad = deg2rad_local(Lambda_LE);
    Lambda_VT_rad = deg2rad_local(Lambda_VT);

    %% ------------------------------------------------------
    %  STRUCTURE
    %  ------------------------------------------------------

    % Eq. (20.1b) Wing - USN fighter
    W_wing = 19.29 * ...
        ( (K_PIV*N*W_TO/t_c) * ...
        ( (tan(Lambda_LE_rad) - (2*(1-lambda)/(AR*(1+lambda))))^2 + 1.0 ) ...
        * 1e-6 )^0.464 * ...
        ((1+lambda)*AR)^0.70 * ...
        S_w^0.58;

    % Eq. (20.3a) Horizontal tail
    gamma_HT = (W_TO*N)^0.813 * ...
               (S_HT)^0.584 * ...
               (b_HT/t_R_HT)^0.033 * ...
               (cbar_wing/L_t)^0.28;
    W_HT = 0.0034 * gamma_HT^0.915;

    % Eq. (20.3b) Vertical tail
    gamma_VT = (1 + hT_hV)^0.5 * ...
               (W_TO*N)^0.363 * ...
               (S_VT)^1.089 * ...
               M0^0.601 * ...
               (L_t)^(-0.726) * ...
               (1 + S_r/S_VT)^0.217 * ...
               (AR_VT)^0.337 * ...
               (1 + lambda_V)^0.363 * ...
               (cos(Lambda_VT_rad))^(-0.484);
    W_VT = 0.19 * gamma_VT^1.014;

    % Eq. (20.5) Fuselage - USN
    W_fuselage = 11.03 * ...
        (K_INL)^1.23 * ...
        (q*1e-2)^0.245 * ...
        (W_TO*1e-3)^0.98 * ...
        (L/H)^0.61;

    % Eq. (20.7) Landing gear - USN
    W_landing_gear = 129.1 * (W_TO*1e-3)^0.66;

    %% ------------------------------------------------------
    %  AIR INDUCTION / FUEL / ENGINE CONTROLS
    %  ------------------------------------------------------

    % Eq. (20.8)
    W_duct_provisions = 0.32 * (N_i) * (L_d) * (A_i)^0.65 * (P_2)^0.6;

    % Eq. (20.9)
    W_internal_duct = 1.735 * ...
        ( (N_i)*(L_d)*(A_i)^0.5*(P_2)*(K_GEO)*(K_M) )^0.7331;

    % Eq. (20.10)
    W_variable_ramps = 4.079 * ...
        ( (N_i)*(L_r)*(A_i)^0.5*(K_TE) )^1.201;

    % Eq. (20.11)
    W_HFS = 12.53 * (N_i) * (A_i);

    % Eq. (20.12)
    W_full_round_spike = 15.65 * (N_i) * (A_i);

    % Eq. (20.13)
    W_TES = 51.8 * (N_i) * (A_i);

    % Eq. (20.14)
    W_external_turbojet_duct = 3.00 * (N_i) * ...
        ( (A_i)^0.5 * (L_d) * (P_2) )^0.731;

    % Eq. (20.15)
    W_DTF = 7.435 * (N_i) * ...
        ( (L_d) * (A_i)^0.5 * (P_2) )^0.731;

    % Eq. (20.16)
    W_self_sealing_cells = 41.6 * (((F_GW + F_GF)*1e-2)^0.818);
    % Eq. (20.18)
    W_cell_supports=7.91*((F_GW+F_GF)*1e-2)^0.854;
    % Eq. (20.19)
    W_in_flight_refuel=13.64*((F_GW+F_GF)*1e-2)^0.392;
    % Eq. (20.20)
    W_fuel_dump=7.38*((F_GW+F_GF)*1e-2)^0.458;
    % no CG control system by pumping fuel (this is more of a big airliner
    % thing)
    W_fuel_system=W_self_sealing_cells+W_cell_supports+W_in_flight_refuel+W_fuel_dump;

    % Select air induction total
    W_air_induction = 0;
    if use_internal_ducts
        W_air_induction = W_air_induction + W_duct_provisions + W_internal_duct;
    end
    if use_variable_ramps
        W_air_induction = W_air_induction + W_variable_ramps;
    end
    if use_half_round_fixed_spike
        W_air_induction = W_air_induction + W_HFS;
    end
    if use_full_round_spike
        W_air_induction = W_air_induction + W_full_round_spike;
    end
    if use_trans_expand_spike
        W_air_induction = W_air_induction + W_TES;
    end
    if use_external_turbojet_duct
        W_air_induction = W_air_induction + W_external_turbojet_duct;
    end
    if use_external_turbofan_duct
        W_air_induction = W_air_induction + W_DTF;
    end

    % Eq. (20.22)
    W_engine_controls_body = K_ECO * (L_f*N_E)^0.792;

    % Eq. (20.23)
    W_engine_controls_wing_jet = 88.46 * (((L_f + b)*N_E*1e-2)^0.294);

    % Eq. (20.24)
    W_engine_controls_turboprop = 56.84 * (((L_f + b)*N_E*1e-2)^0.514);

    % Eq. (20.25)
    W_wing_mounted_recip = 60.27 * (((L_f + b)*N_E*1e-2)^0.724);

    switch engine_control_mode
        case 1
            W_engine_controls = W_engine_controls_body;
            engine_control_label = 'Body / wing-root mounted jet';
        case 2
            W_engine_controls = W_engine_controls_wing_jet;
            engine_control_label = 'Wing-mounted turbojet / turbofan';
        case 3
            W_engine_controls = W_engine_controls_turboprop;
            engine_control_label = 'Wing-mounted turboprop';
        case 4
            W_engine_controls = W_wing_mounted_recip;
            engine_control_label = 'Wing-mounted reciprocating';
        otherwise
            error('Invalid engine_control_mode.');
    end

    %% ------------------------------------------------------
    %  STARTING SYSTEMS
    %  ------------------------------------------------------

    % Eq. (20.26)
    W_start_jet_cart = 9.33 * ((N_E*W_ENG*1e-3)^1.078);

    % Eq. (20.27)
    W_start_jet_electric = 38.93 * ((N_E*W_ENG*1e-3)^0.918);

    % Eq. (20.28)
    W_start_4jet_pneumatic = 49.19 * ((N_E*W_ENG*1e-3)^0.541);

    % Eq. (20.29)
    W_start_turboprop = 12.05 * ((N_E*W_ENG*1e-3)^1.458);

    % Eq. (20.30)
    W_start_recip_electric = 50.38 * ((N_E*W_ENG*1e-3)^0.459);

    switch start_mode
        case 1
            W_start_system = W_start_jet_cart;
            label_start = 'Jet Cartridge/Pneumatic';
        case 2
            W_start_system = W_start_jet_electric;
            label_start = 'Jet Electric';
        case 3
            W_start_system = W_start_4jet_pneumatic;
            label_start = '4+ Jet Pneumatic';
        case 4
            W_start_system = W_start_turboprop;
            label_start = 'Turboprop Pneumatic';
        case 5
            W_start_system = W_start_recip_electric;
            label_start = 'Reciprocating Electric';
        otherwise
            error('Invalid start_mode.');
    end

    %% ------------------------------------------------------
    %  PROPELLER SYSTEMS
    %  ------------------------------------------------------

    % Eq. (20.31)
    W_propellers = K_p * N_p * (N_BL)^0.391 * (d_p * HP * 1e-3)^0.782;

    % Eq. (20.32)
    W_prop_ctrl_turboprop = 0.322 * (N_BL)^0.589 * (N_p * d_p * HP * 1e-3)^1.178;

    % Eq. (20.33)
    W_prop_ctrl_recip = 4.552 * (N_BL)^0.379 * (N_p * d_p * HP * 1e-3)^0.759;

    switch prop_ctrl_mode
        case 0
            W_prop_ctrl = 0;
            label_prop_ctrl = 'None (jet aircraft)';
        case 1
            W_prop_ctrl = W_prop_ctrl_turboprop;
            label_prop_ctrl = 'Turboprop';
        case 2
            W_prop_ctrl = W_prop_ctrl_recip;
            label_prop_ctrl = 'Reciprocating';
        otherwise
            error('Invalid prop_ctrl_mode.');
    end

    %% ------------------------------------------------------
    %  SURFACE CONTROLS / HYDRAULICS / PNEUMATICS
    %  ------------------------------------------------------

    % Eq. (20.34)
    W_surface_ctrl_USAF = K_SC * (W_TO * 1e-3)^0.581;

    % Eq. (20.35)
    W_surface_ctrl_USN = 23.77 * (W_TO * 1e-3)^1.10;

    % Eq. (20.36)
    W_surface_ctrl_exec_comm = 56.01 * (W_TO * q * 1e-5)^0.576;

    % Eq. (20.37)
    W_surface_ctrl_cargo = 15.96 * (W_TO * q * 1e-5)^0.815;

    % Eq. (20.38)
    W_surface_ctrl_bomber = 1.049 * (S_TOT * q * 1e-3)^1.21;

    switch surface_ctrl_mode
        case 1
            W_surface_controls = W_surface_ctrl_USAF;
            label_surface = 'USAF fighter';
        case 2
            W_surface_controls = W_surface_ctrl_USN;
            label_surface = 'USN fighter/attack';
        case 3
            W_surface_controls = W_surface_ctrl_exec_comm;
            label_surface = 'Executive/commercial transport';
        case 4
            W_surface_controls = W_surface_ctrl_cargo;
            label_surface = 'Cargo/troop transport';
        case 5
            W_surface_controls = W_surface_ctrl_bomber;
            label_surface = 'Bomber';
        otherwise
            error('Invalid surface_ctrl_mode.');
    end

    %% ------------------------------------------------------
    %  INSTRUMENTS
    %  ------------------------------------------------------

    % Eq. (20.39)
    W_flight_instr = N_PIL * (15.0 + 0.032 * (W_TO * 1e-3));

    % Eq. (20.40)
    W_engine_instr_turbine = N_E * (4.80 + 0.006 * (W_TO * 1e-3));

    % Eq. (20.41)
    W_engine_instr_recip = N_E * (7.40 + 0.046 * (W_TO * 1e-3));

    % Eq. (20.42)
    W_misc_instr = 0.15 * (W_TO * 1e-3);

    switch engine_instr_mode
        case 1
            W_engine_instr = W_engine_instr_turbine;
            label_instr = 'Turbine';
        case 2
            W_engine_instr = W_engine_instr_recip;
            label_instr = 'Reciprocating';
        otherwise
            error('Invalid engine_instr_mode.');
    end

    W_instruments_total = W_flight_instr + W_engine_instr + W_misc_instr;

    %% ------------------------------------------------------
    %  ELECTRICAL SYSTEM
    %  ------------------------------------------------------

    % Eq. (20.43)
    W_electrical_USAF = 426.17 * ((W_fuel_system * W_TRON) * 1e-3)^0.510;

    % Eq. (20.44)
    W_electrical_USN = 346.98 * ((W_fuel_system * W_TRON) * 1e-3)^0.509;

    % Eq. (20.45)
    W_electrical_bomber = 185.46 * ((W_fuel_system * W_TRON) * 1e-3)^1.286;

    % Eq. (20.46)
    W_electrical_transport = 1162.66 * ((W_fuel_system * W_TRON) * 1e-3)^0.506;

    switch electrical_mode
        case 1
            W_electrical = W_electrical_USAF;
            label_electrical = 'USAF fighter';
        case 2
            W_electrical = W_electrical_USN;
            label_electrical = 'USN fighter/attack';
        case 3
            W_electrical = W_electrical_bomber;
            label_electrical = 'Bomber';
        case 4
            W_electrical = W_electrical_transport;
            label_electrical = 'Transport';
        otherwise
            error('Invalid electrical_mode.');
    end

    %% ------------------------------------------------------
    %  FURNISHINGS
    %  ------------------------------------------------------

    % Eq. (20.47)
    W_ejection_seats_fighter = 22.89 * (N_CR * q * 1e-2)^0.743;

    % Eq. (20.48)
    W_misc_emergency_fighter = 106.61 * (N_CR * W_TO * 1e-5)^0.585;

    % Eq. (20.49)
    W_fixed_seats_bomber = 83.23 * (N_CR)^0.726;

    % Eq. (20.50)
    W_ejection_seats_bomber = K_SEA * (N_CR)^1.20;

    % Eq. (20.51)
    W_oxygen_bomber = 16.89 * (N_CR)^1.494;

    % Eq. (20.52)
    W_crew_bunks = 12.18 * (N_BU)^1.085;

    % Eq. (20.53)
    W_flight_deck_seats = 54.99 * (N_FDS);

    % Eq. (20.54)
    W_passenger_seats = 32.03 * (N_PASS);

    % Eq. (20.55)
    W_troop_seats = 11.17 * (N_TRO);

    % Eq. (20.56)
    W_lav_exec = K_LAV * (N_PASS)^1.33;

    % Eq. (20.57)
    W_lav_military = 1.11 * (N_PASS)^1.33;

    % Eq. (20.58)
    W_food = K_BUF * (N_PASS)^1.12;

    % Eq. (20.59)
    W_oxygen_transport = 7.00 * (N_CR + N_PASS + N_ATT)^0.702;

    % Eq. (20.60)
    W_cabin_windows = 109.33 * (N_PASS * (1 + P_c) * 1e-2)^0.505;

    % Eq. (20.61)
    W_baggage_cargo = K_CBC * (N_PASS)^1.456;

    % Eq. (20.62)
    W_misc_furn_exec = 0.771 * (W_TO * 1e-3);

    % Eq. (20.63)
    W_misc_furn_mil_pass = 0.771 * (W_TO * 1e-3);

    % Eq. (20.64)
    W_misc_furn_mil_troop = 0.618 * (W_TO * 1e-3)^0.839;

    switch furnishings_mode
        case 1
            W_furnishings = W_ejection_seats_fighter + W_misc_emergency_fighter;
            label_furn = 'Fighter/attack';
        case 2
            W_furnishings = W_fixed_seats_bomber + W_ejection_seats_bomber + ...
                            W_oxygen_bomber + W_crew_bunks;
            label_furn = 'Bomber/observation';
        case 3
            W_furnishings = W_flight_deck_seats + W_passenger_seats + ...
                            W_lav_exec + W_food + W_oxygen_transport + ...
                            W_cabin_windows + W_baggage_cargo + W_misc_furn_exec;
            label_furn = 'Executive/commercial';
        case 4
            W_furnishings = W_flight_deck_seats + W_passenger_seats + ...
                            W_lav_military + W_oxygen_transport + ...
                            W_baggage_cargo + W_misc_furn_mil_pass;
            label_furn = 'Military passenger';
        case 5
            W_furnishings = W_flight_deck_seats + W_troop_seats + ...
                            W_lav_military + W_oxygen_transport + ...
                            W_baggage_cargo + W_misc_furn_mil_troop;
            label_furn = 'Military troop-cargo';
        otherwise
            error('Invalid furnishings_mode.');
    end

    %% ------------------------------------------------------
    %  AIR CONDITIONING / ANTI-ICING
    %  ------------------------------------------------------

    % Eq. (20.65)
    W_acai_fighter_hi = 210.66 * ((W_TRON * 200 * N_CR) * 1e-3)^0.735;

    % Eq. (20.66)
    W_acai_fighter_sub = K_ACAI * ((W_TRON * 200 * N_CR) * 1e-3)^0.538;

    % Eq. (20.67)
    W_acai_bomber_transport = K_ACAI * (V_PR * 1e-2)^0.242;

    % Eq. (20.68)
    W_acai_exec_comm = 469.30 * (V_PR * (N_CR + N_ATT + N_PASS) * 1e-4)^0.419;

    switch acai_mode
        case 1
            W_air_conditioning = W_acai_fighter_hi;
            label_acai = 'Fighter high-sub/supersonic';
        case 2
            W_air_conditioning = W_acai_fighter_sub;
            label_acai = 'Fighter subsonic';
        case 3
            W_air_conditioning = W_acai_bomber_transport;
            label_acai = 'Bomber/military transport';
        case 4
            W_air_conditioning = W_acai_exec_comm;
            label_acai = 'Executive/commercial';
        otherwise
            error('Invalid acai_mode.');
    end

    %% ------------------------------------------------------
    %  AVIONICS / LANDING RETARDATION DEVICES
    %  ------------------------------------------------------

    % Avionics: use installed avionics weight
    W_avionics = W_TRON;

    % Landing retardation devices: chapter references, set manually if desired
    W_landing_retardation = 250; % estimate comes from Nicolai Figure 10.10

    %% ------------------------------------------------------
    %  TOTAL MILITARY BLOCK
    %  ------------------------------------------------------
    W_total_military = W_wing + W_HT + W_VT + W_fuselage + ...
                       W_landing_gear + W_air_induction + W_fuel_system + ...
                       W_engine_controls + W_start_system + W_propellers + ...
                       W_prop_ctrl + W_surface_controls + W_instruments_total + ...
                       W_electrical + W_furnishings + W_air_conditioning + ...
                       W_avionics + W_landing_retardation;

    %% ------------------------------------------------------
    %  DISPLAY MILITARY BLOCK
    %  ------------------------------------------------------
    fprintf('\n--- Structure ---\n');
    fprintf('Wing Weight                  = %10.2f lb\n', W_wing);
    fprintf('Horizontal Tail Weight       = %10.2f lb\n', W_HT);
    fprintf('Vertical Tail Weight         = %10.2f lb\n', W_VT);
    fprintf('Fuselage Weight              = %10.2f lb\n', W_fuselage);
    fprintf('Landing Gear Weight          = %10.2f lb\n', W_landing_gear);

    fprintf('\n--- Air Induction / Propulsion Subs ---\n');
    fprintf('Air Induction Total          = %10.2f lb\n', W_air_induction);
    fprintf('Fuel System Weight           = %10.2f lb\n', W_fuel_system);
    fprintf('Engine Controls              = %10.2f lb  (%s)\n', W_engine_controls, engine_control_label);
    fprintf('Starting System              = %10.2f lb  (%s)\n', W_start_system, label_start);
    fprintf('Propellers                   = %10.2f lb\n', W_propellers);
    fprintf('Propeller Controls           = %10.2f lb  (%s)\n', W_prop_ctrl, label_prop_ctrl);

    fprintf('\n--- Controls / Instruments / Electrical ---\n');
    fprintf('Surface Controls             = %10.2f lb  (%s)\n', W_surface_controls, label_surface);
    fprintf('Instruments Total            = %10.2f lb\n', W_instruments_total);
    fprintf('Electrical System            = %10.2f lb  (%s)\n', W_electrical, label_electrical);

    fprintf('\n--- Furnishings / ACAI / Avionics ---\n');
    fprintf('Furnishings                  = %10.2f lb  (%s)\n', W_furnishings, label_furn);
    fprintf('Air Conditioning / Anti-Ice  = %10.2f lb  (%s)\n', W_air_conditioning, label_acai);
    fprintf('Avionics                     = %10.2f lb\n', W_avionics);
    fprintf('Landing Retardation Devices  = %10.2f lb\n', W_landing_retardation);

    fprintf('\n--- Total Military Block ---\n');
    fprintf('Total Weight                 = %10.2f lb\n', W_total_military);

    Component_military = {
        'Wing'
        'Horizontal Tail'
        'Vertical Tail'
        'Fuselage'
        'Landing Gear'
        'Air Induction'
        'Fuel System'
        'Engine Controls'
        'Starting System'
        'Propellers'
        'Propeller Controls'
        'Surface Controls'
        'Instruments'
        'Electrical System'
        'Furnishings'
        'Air Conditioning / Anti-Icing'
        'Avionics'
        'Landing Retardation Devices'
        'Total'
        };

    Weight_military_lb = [
        W_wing
        W_HT
        W_VT
        W_fuselage
        W_landing_gear
        W_air_induction
        W_fuel_system
        W_engine_controls
        W_start_system
        W_propellers
        W_prop_ctrl
        W_surface_controls
        W_instruments_total
        W_electrical
        W_furnishings
        W_air_conditioning
        W_avionics
        W_landing_retardation
        W_total_military
        ];

    T_military = table(Component_military, Weight_military_lb);
    disp(T_military);
end

%% =========================================================
%  LIGHT UTILITY AIRCRAFT BLOCK
%  =========================================================
if run_light_utility_block

    fprintf('\n=========================================================\n');
    fprintf(' LIGHT UTILITY AIRCRAFT BLOCK\n');
    fprintf('=========================================================\n');

    %% ------------------------------------------------------
    %  INPUTS
    %  ------------------------------------------------------
    Lambda_c4 = 0;      % wing quarter-chord sweep [deg]
    V_e       = 0;      % equivalent max airspeed at sea level [kt]

    W_fuse    = 0;      % fuselage max width [ft]
    D_fuse    = 0;      % fuselage max depth [ft]

    S_H       = 0;      % horizontal tail area [ft^2]
    ell_T     = 0;      % distance from wing 1/4 MAC to tail 1/4 MAC [ft]
    b_H       = 0;      % horizontal tail span [ft]
    t_HR_in   = 0;      % horizontal tail max root thickness [in]

    S_V       = 0;      % vertical tail area [ft^2]
    b_V       = 0;      % vertical tail span [ft]
    t_VR_in   = 0;      % vertical tail max root thickness [in]

    L_LG      = 0;      % main landing gear strut length [in]
    W_LAND    = 0;      % landing weight [lb]
    N_LAND    = 0;      % ultimate load factor at landing weight

    F_G       = 0;      % total fuel [gal]
    Int       = 0;      % fraction of integral tanks
    N_T       = 0;      % number of separate fuel tanks

    % Reuse W_AU for Eq. (20.81)
    % Reuse N_CR, N_PASS, q, P_c, M_E

    % 1 = powered, 2 = unpowered
    surface_ctrl_light_mode = 1;

    %% ------------------------------------------------------
    %  ANGLES
    %  ------------------------------------------------------
    Lambda_c4_rad = deg2rad_local(Lambda_c4);

    %% ------------------------------------------------------
    %  STRUCTURE
    %  ------------------------------------------------------

    % Eq. (20.69)
    W_wing_light = 96.948 * ...
        ( (W_TO*N)/1e5 )^0.65 * ...
        ( AR / cos(Lambda_c4_rad) )^0.57 * ...
        ( S_w/100 )^0.61 * ...
        ( (1 + lambda)/(2*t_c) )^0.36 * ...
        ( 1 + V_e/500 )^0.5;
    W_wing_light = W_wing_light^0.993;

    % Eq. (20.70)
    W_fuselage_light = 200 * ...
        ( ((W_TO*N)/1e5)^0.286 * ...
          (L/10)^0.857 * ...
          ((W_fuse + D_fuse)/10) * ...
          (V_e/100)^0.338 )^1.1;

    % Eq. (20.71)
    W_HT_light = 127 * ...
        ( ((W_TO*N)/1e5)^0.87 * ...
          (S_H/100)^1.2 * ...
          (ell_T/10)^0.483 * ...
          (b_H/t_HR_in)^0.5 )^0.458;

    % Eq. (20.72)
    W_VT_light = 98.5 * ...
        ( ((W_TO*N)/1e5)^0.87 * ...
          (S_V/100)^1.2 * ...
          (b_V/t_VR_in)^0.5 );

    % Eq. (20.73)
    W_LG_light = 0.054 * ...
        (L_LG)^0.501 * ...
        (W_LAND * N_LAND)^0.684;

    %% ------------------------------------------------------
    %  PROPULSION
    %  ------------------------------------------------------

    % Eq. (20.74)
    W_propulsion_installed_light = 2.575 * (W_ENG)^0.922 * N_E;

    % Eq. (20.75)
    W_fuel_system_light = 2.49 * ...
        ( (F_G)^0.6 * ...
          (1/(1 + Int))^0.3 * ...
          (N_T)^0.2 * ...
          (N_E)^0.13 )^1.21;

    %% ------------------------------------------------------
    %  SURFACE CONTROLS
    %  ------------------------------------------------------

    % Eq. (20.76)
    W_surface_powered_light = 1.08 * (W_TO)^0.7;

    % Eq. (20.77)
    W_surface_unpowered_light = 1.066 * (W_TO)^0.626;

    switch surface_ctrl_light_mode
        case 1
            W_surface_controls_light = W_surface_powered_light;
            label_surface_light = 'Powered';
        case 2
            W_surface_controls_light = W_surface_unpowered_light;
            label_surface_light = 'Unpowered';
        otherwise
            error('Invalid surface_ctrl_light_mode.');
    end

    %% ------------------------------------------------------
    %  AVIONICS / ELECTRICAL
    %  ------------------------------------------------------

    % Eq. (20.81)
    W_TRON_light = 2.117 * (W_AU)^0.933;

    % Eq. (20.78)
    W_electrical_light = 426 * ((W_fuel_system_light + W_TRON_light)/1000)^0.51;

    %% ------------------------------------------------------
    %  FURNISHINGS
    %  ------------------------------------------------------

    % Eq. (20.79)
    W_crew_seats_light = 34.5 * (N_CR) * (q)^0.25;

    % Uses Eq. (20.54), Eq. (20.62), Eq. (20.60)
    W_passenger_seats_light = 32.03 * (N_PASS);
    W_misc_furn_light       = 0.771 * (W_TO * 1e-3);
    W_cabin_windows_light   = 109.33 * (N_PASS * (1 + P_c) * 1e-2)^0.505;

    W_furnishings_light = W_crew_seats_light + ...
                          W_passenger_seats_light + ...
                          W_misc_furn_light + ...
                          W_cabin_windows_light;

    %% ------------------------------------------------------
    %  AIR CONDITIONING / ANTI-ICING
    %  ------------------------------------------------------

    % Eq. (20.80)
    W_acai_light = 0.265 * ...
        (W_TO)^0.52 * ...
        (N_CR + N_PASS)^0.68 * ...
        (W_TRON_light)^0.17 * ...
        (M_E)^0.08;

    %% ------------------------------------------------------
    %  TOTAL LIGHT UTILITY BLOCK
    %  ------------------------------------------------------
    W_total_light_utility = W_wing_light + W_fuselage_light + W_HT_light + ...
                            W_VT_light + W_LG_light + W_propulsion_installed_light + ...
                            W_fuel_system_light + W_surface_controls_light + ...
                            W_electrical_light + W_furnishings_light + ...
                            W_acai_light + W_TRON_light;

    %% ------------------------------------------------------
    %  DISPLAY LIGHT UTILITY BLOCK
    %  ------------------------------------------------------
    fprintf('\n--- Structure ---\n');
    fprintf('Wing Weight                  = %10.2f lb\n', W_wing_light);
    fprintf('Fuselage Weight              = %10.2f lb\n', W_fuselage_light);
    fprintf('Horizontal Tail Weight       = %10.2f lb\n', W_HT_light);
    fprintf('Vertical Tail Weight         = %10.2f lb\n', W_VT_light);
    fprintf('Landing Gear Weight          = %10.2f lb\n', W_LG_light);

    fprintf('\n--- Propulsion ---\n');
    fprintf('Installed Propulsion Weight  = %10.2f lb\n', W_propulsion_installed_light);
    fprintf('Fuel System Weight           = %10.2f lb\n', W_fuel_system_light);

    fprintf('\n--- Controls / Electrical ---\n');
    fprintf('Surface Controls             = %10.2f lb  (%s)\n', ...
        W_surface_controls_light, label_surface_light);
    fprintf('Installed Avionics           = %10.2f lb\n', W_TRON_light);
    fprintf('Electrical System            = %10.2f lb\n', W_electrical_light);

    fprintf('\n--- Furnishings / ACAI ---\n');
    fprintf('Furnishings                  = %10.2f lb\n', W_furnishings_light);
    fprintf('Air Conditioning / Anti-Ice  = %10.2f lb\n', W_acai_light);

    fprintf('\n--- Total Light Utility Block ---\n');
    fprintf('Total Weight                 = %10.2f lb\n', W_total_light_utility);

    Component_light = {
        'Wing'
        'Fuselage'
        'Horizontal Tail'
        'Vertical Tail'
        'Landing Gear'
        'Installed Propulsion'
        'Fuel System'
        'Surface Controls'
        'Installed Avionics'
        'Electrical System'
        'Furnishings'
        'Air Conditioning / Anti-Icing'
        'Total'
        };

    Weight_light_lb = [
        W_wing_light
        W_fuselage_light
        W_HT_light
        W_VT_light
        W_LG_light
        W_propulsion_installed_light
        W_fuel_system_light
        W_surface_controls_light
        W_TRON_light
        W_electrical_light
        W_furnishings_light
        W_acai_light
        W_total_light_utility
        ];

    T_light = table(Component_light, Weight_light_lb);
    disp(T_light);
end