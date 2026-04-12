%% Roskam Weight Calculator
% 3/16/2026
% Andrew and Sidd

%% Remarks:

% Weights are in pounds (lbs)

% Lengths are in feet (ft)

% Ignore all potential comments that state the units in meters

%% Necessary Changes

% Adjust quater chord sweep for vertical rudder.

% Adjust max mach at SL and

% There is currently the assumption that the max fuselage height and max
% fuselage width are the same.

function output = RoskamWeightCalculator(geom, perf)


%% Chapter 4: Weight Component Estimation using Class II method
% this is where the value is getting better

% Step 1: List all of the known weights
W_empty = geom.weights.mtow.v * geom.weights.raymer.A.v * N2lb(geom.weights.mtow.v)^geom.weights.raymer.C.v;
% W_fuel = 15000; % from our code estimates
% W_payload = 10000; % from RFP
% W_crew = 200; % guess
% W_tfo = 300; % trapped fuel and oil weight
% TOGW = W_empty + W_fuel+W_payload+W_crew+W_tfo; % initial guess, where we want the aircraft to be at.
% GW = TOGW * 0.95 ; % flight design gross weight
TOGW = N2lb(geom.weights.mtow.v);
GW = 0.95 * TOGW;

%% List all Inputs for each equation you desire to use

% wing
K_w = 1; % is 1 for fixed wing airplanes, is 1.175 for variable sweep wing airplanes
n_ult = 1.5*7.5;
t_c_m = geom.wing.average_tc.v; % (t/c)_m
lambda_LE = deg2rad(geom.wing.average_sweep.v); % leading edge sweep angle of the wing
taper_ratio = geom.wing.taper_ratio.v;
A = geom.wing.AR.v; % wing aspect ratio
S = m2ft(m2ft(geom.wing.area.v)); % wing area

%horizontal tail
S_h = m2ft(m2ft(geom.elevator.area.v)); % horizontal tail area (m^2)
b_h = m2ft(geom.elevator.span.v); %horizontal tail span
A_h = geom.elevator.AR.v; %horizontal tail aspect ratio
t_r_h = geom.rudder.sections(1).tc.v; % horizontal tail maximum root thickness
c_bar = m2ft(geom.elevator.average_chord.v);

%vertical tail
S_v = m2ft(m2ft(geom.rudder.area.v));% vertical tail area 
A_v = geom.rudder.AR.v;% vertical tail aspect ratio
t_r_v = geom.elevator.sections(1).tc.v;% vertical tail maximum root thickness
lambda_quarter_v = deg2rad(geom.elevator.average_qrtr_chd_sweep.v);% vertical tail quarter chord sweep angle

M_H = 0.95; % maximum mach number at sealevel -> hard setting is more stable
l_v = m2ft(geom.rudder.le_x.v-geom.wing.le_x.v); %distance from wing c/4 to vertical tail cv/4
z_h = 0; %distance from the vertical tail root to where the horizontal tail is mounted on the vertical tail in feet. for fuselage mounted horizontal tails, this is 0.
l_h = m2ft(geom.elevator.le_x.v-geom.wing.le_x.v); %distance from wing c/4 to horizontal tial ch/4
b_h = m2ft(geom.elevator.span.v); %horizontal tail span
b_v = m2ft(geom.rudder.span.v); % vertical tail span (m)
taper_ratio_v = geom.rudder.taper_ratio.v; %vertical tail ratio
S_r = m2ft(m2ft(geom.rudder.area.v)); %rudder area

K_inl =  1.25; % should be 1.25 fo airplanes withi inlets attached to fuselage and 1 if the inlets are somewhere else.
q_L = 2000; %design dive dynamic pressure in psf
q_D = 2000;
l_f = geom.fuselage.length.v; %fuselage length (m)
h_f = m2ft(sqrt(geom.fuselage.max_area.v / pi)/2); %maximum fuselage height
w_f = h_f; %maximum fuselage width (m)

% TODO: THESE ARE FIXED
N_inl = geom.prop.num_engine.v; %number of inlets
A_inl = 5.5; %capture area per inlet (ft^2)
l_n = 56-24-10; %nacelle length from inlet lip to compressor face (ft)
P2 = 40; % maximum static pressure at engine compresor face in psi. (should be between 15-50 psi)

% M_D = 1.8;
K_d = 1; % 1.33 for ducts with flat cross sections, 1 for ducts with curved cross sections
K_m = 1.5; %1 for M_D below 1.4, 1.5 for M_D above 1.4

L_d = 8; % duct length


K_r = 1; % 1 for M_D below 3.0, (MD+2)/5 for MD above 3;


K_ec = 1.080; %0.686 for non-afterburning engines, 1.080 for afterburning engines
N_e = geom.prop.num_engine.v; % number of engines
b = m2ft(geom.wing.span.v); % wing span
K_osc = 0; % jet engine value is 0.

% THIS COULD BE CALCULATED
R = 1400; %maximum range (nm)

K_api = 212; % for supersonic airplanes with wing and tail anti-icing
N_cr = 1;% number of crew


% Engine Weight
W_engine = N2lb(geom.prop.dry_weight.v); % number of engines is added later


%% Chapter 5 Equations: Estimating Structure Weight

% Wing Weight Calculation (eqn 5.10, Roskam V)
part1 = K_w*n_ult*TOGW/(t_c_m);
part2 = ((tan(lambda_LE) - 2*((1-taper_ratio)/(A*1+taper_ratio))^2 + 1)*10^-6);

W_wing = 19.29 * (part1*part2)^0.464 * (A*(1+taper_ratio))^0.70 * S^0.58;

% Empennage Weight Calculation (will be expressed as W_htail + W_vtail +
% W_canards) ( eqn 5.17, eqn 5.18, no canards)

% Horizontal tail weight
W_htail = 0.0034*((TOGW*n_ult)^0.813 * S_h^0.584 *(b_h/t_r_h)^0.033 * (c_bar/l_h)^0.28)^0.915;
% vertical tail weight
W_vtail = 0.19 * ((1+(z_h/b_v))^0.5 * (TOGW*n_ult)^0.363 * S_v^1.089 * M_H^0.601 * l_v^-0.726 * (1+(S_r/S_v))^0.217 * A_v^0.337 * (1+taper_ratio_v)^0.363 * cos(lambda_quarter_v)^-0.484)^1.014;

% no carnards, thus
% W_canards = 0;

W_empennage = W_htail + W_vtail;

% Fuselage Weight Calculation (eqn 5.28)

W_fuselage = 11.03 * (K_inl)^1.23 * (q_L/100)^0.245 * (TOGW/1000)^0.98 * (l_f/h_f)^0.61;

% Nacelle Weight Estimation (eqn 5.35, for turbofan engine)

W_nacelle = 7.425 * N_inl * (A_inl^0.5 * l_n * P2)^0.731; 

% Landing Gear Weight Estimation

W_g = 129.1 * (TOGW/1000)^0.66;


%% Chapter 6 Equations: Estiamting Power Plant Weight

% This includes the W_engines + W_ai (air induction system) + W_prop
% (propellers) + W_fs (fuel system weight) + W_p (propulsion sytem)
% The propulsion system includes the engine contraols starting systems
% propeller constails provisions for engine installation


% Air Induction Sytem weight estimation (eqn 6.9)
W_ai_duct_support = 0.32 * N_inl *A_inl^0.65 * P2^0.6;
W_ai_subsonic_part = 1.735*(L_d * N_inl * A_inl^0.5 * P2 * K_d * K_m)^0.7331;

W_ai = W_ai_subsonic_part + W_ai_duct_support;

% Propeller weight estimation
% we don't have propellers
W_prop = 0;

% Fuel System Weight Estimation

% will be used in a later section in Chapter 7 (perhaps)

% Propulsion System Calculation
% Sum of engine controls, engine starting sytem propeller contraols, oil
% system and oil cooler

% Engine Controls ( eqn 6.23 for fuselage mounted jet engines )
W_ec = (K_ec * l_f * N_e)^0.792; 

% Engine Staring System ( eqn 6.29 ) electric starting system
W_ess = 38.93 * (W_engine/1000)^0.918;

% Propeller Controls, we don't have any so no need
W_pc = 0;

% Oil System and Oil cooler:
W_osc = K_osc * W_engine;

%% Chapter 7 Equations: Fixed Equipment Weights

% includes flight control sstem, hydraulic and penumatic systems electrical systems,
%  instrumentation, avionices and elcetronics, airconditionsing
%  pressuriztion and anti- and deicing systems, oxygen system, auxiliary
%  power unit, furnishings, baggage and cargo handling equipment,
%  operational items, armament, guns, launchers and weapon provisions,
%  flight test instrumentation, euxiliarty gear, ballast, paint, etc.

% Flight Control System (eqn 7.10)
W_fc = 23.77 * (TOGW /1000)^1.1;
% note that this estimate includes the wieght of all associated hydraulic
% or penumatic systems, there is another equation for a CG movement device.

% Hydraulic Systems
W_hps = 0.0180 * TOGW;

% Instrumentation, avionics, and electronics
W_iae = 0.575 * W_engine^0.556 * R^0.25;

% Electrical System Weight Esimtations, we are given this
W_els = 347* (( W_fc + W_iae)/1000)^0.509; %fs or fc

% Weight Estimatino for air conidtionaing, pressurization, and anti-icing
% and deicing stuff

W_api = 202* ( (W_iae + 200*N_cr)/ 1000)^0.735;

% Oxygen System

W_ox = 16.9 * N_cr^1.494;

% Auxiliary Power unit 

W_apu = 0.007 *TOGW;

% Furnishing

W_fur_ejection = 22.9*(N_cr*q_D/100)^0.743;
W_fur_emergency = 107*(N_cr*TOGW/100000)^0.585;
W_fur = W_fur_emergency+W_fur_ejection;

% Baggae and Cargo handling equipment 
% we don't have that cause we a fighter
W_bc = 0;

% Auxiliary Gear
W_aux = 0.005 * TOGW;

%% Form output struct

% structure weight outputs
output.W_wing = lb2N(W_wing); % wing weight
output.W_htail = lb2N(W_htail); % horizontal tail weight
output.W_vtail = lb2N(W_vtail); % vertical tail weight
output.W_fuselage = lb2N(W_fuselage); % fuselage weight
output.W_nacelles = lb2N(W_nacelle); % nacelle weight (think of this more as inlet weight)
output.W_lg = lb2N(W_g); % landing gear weight

% Sum to obtain Structure weight
W_struct = W_wing + W_empennage + W_fuselage + W_nacelle + W_g; % W_htail W_vtail in W_empennage

% powerplant weight outputs
output.W_eng = lb2N(N_e*W_engine);
output.W_ai = lb2N(W_ai); % air induction system weight
output.W_ec = lb2N(W_ec); % engine control weight
output.W_ess = lb2N(W_ess); % engine start system weight
output.W_osc = lb2N(W_osc); % oil system oil cooler weight

% Sum to obtain the total power plant weight
W_pwr = N_e*W_engine + W_ai + W_prop + W_ec + W_ess + W_pc + W_osc; % W_prop, W_pc = 0 cause we dont have a propeller

% 
output.W_fc = lb2N(W_fc); % fuel control system weight
output.W_hps = lb2N(W_hps); % hydraulic and pneumatic sytem weight
output.W_els = lb2N(W_els); % electronic system weight
output.W_iae = lb2N(W_iae); % instrumentation, avionics, and electronics
output.W_api = lb2N(W_api); % air conditioning, pressurization, and anti- and de-icing systems weight
output.W_ox = lb2N(W_ox); % oxygen system 
output.W_apu = lb2N(W_apu); % auxilliary power unit
output.W_fur = lb2N(W_fur); % furnishings
output.W_aux = lb2N(W_aux); % auxilliary gear

% output.W_empennage = lb2N(W_empennage); % empennage weight
% output.W_arm = lb2N(10000); % armmaments weights < WHAT WAS THS
% output.W_els =lb2N(W_els); % electrical system
% output.W_ops = lb2N(W_ops); % operational items
% output.W_empty_new = lb2N(W_empty_new);
% output.W_fs = lb2N(W_fs); % fuel system weight
% output.W_p = lb2N(W_p); % propulsion system weight (engine controls, starting system, engine installation

% Sum to obtain all the fixed equipment weight
W_feq = W_fc + W_hps + W_els + W_iae + W_api + W_ox + W_apu + W_fur + W_bc + W_aux; % W_bc = 0 cause we are a fighter


%% Total W_empty

% sum segments
W_empty_new = W_struct+W_feq+W_pwr;

% display new empty weight
% disp(['New Empty Weight: ', num2str(W_empty_new), ' lbs']);

% TOGW_new =  W_empty_new + W_fuel+W_payload+W_crew+W_tfo; % new TOGW

end
