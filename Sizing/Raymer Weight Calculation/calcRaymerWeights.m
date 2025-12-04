function output = calcRaymerWeights(input)
% calcRaymerWeights - Raymer component weights
%
% INPUT:
%   input - struct with fields as before
%   units - 'imperial' (default) or 'metric'
%
% USAGE:
%   out = calcRaymerWeights(input);           % default imperial

% -----------------------------
% Convert metric input to imperial if needed
% -----------------------------
input = metricToImperial(input);

output = calcWeightsImperial(input);

% -----------------------------
% Convert outputs to Newtons
% -----------------------------
fnames = fieldnames(output);
for i = 1:numel(fnames)
    output.(fnames{i}) = lb2N( output.(fnames{i}) ); % lb -> N
end

end

% -----------------------------
% Nested helper: convert metric input -> imperial
% -----------------------------
function inputImperial = metricToImperial(input)
    inputImperial = input;  % copy struct

    % Lengths (m -> ft)
    lenFields = {'L','Lf','Ln','Lm','Ld','Ls','Ltp','Lsh','Lec','Lt'};
    for f = lenFields
        fn = f{1};
        if isfield(inputImperial,fn)
            inputImperial.(fn) = m2ft( inputImperial.(fn) );
        end
    end

    % Areas (m^2 -> ft^2)
    areaFields = {'Sw','Sht','Svt','Sfw','Scsw','Scs'};
    for f = areaFields
        fn = f{1};
        if isfield(inputImperial,fn)
            inputImperial.(fn) = m2ft(m2ft( inputImperial.(fn) ) );
        end
    end

    % Forces (N -> lbf) for weights and thrusts
    forceFields = {'Wdg','WNl','Wen','T','W_param','W_uav'};
    for f = forceFields
        fn = f{1};
        if isfield(inputImperial,fn)
            inputImperial.(fn) = N2lb( inputImperial.(fn) );
        end
    end

    % Volumes: assume m^3 -> ft^3
    volFields = {'Vt','Vi','Vp'};
    for f = volFields
        fn = f{1};
        if isfield(inputImperial,fn)
            inputImperial.(fn) = m2ft(m2ft(m2ft( inputImperial.(fn) ) ) ); % m^3 -> ft^3
        end
    end
end

function output = calcWeightsImperial(input)

% calcRaymerWeights - Raymer component weight equations (filled)
%
% Usage:
%   out = calcRaymerWeights(input)
%
% INPUT struct fields (common names used in the formulas you provided).
%   input.Wdg       - design gross weight (W_{dg}) [lb]
%   input.Nz        - ultimate load factor (N_z)
%   input.Sw        - wing area S_w [ft^2]
%   input.AR        - wing aspect ratio (A or AR)
%   input.tc_root   - (t/c)_root (unitless)
%   input.lambda    - taper ratio (lambda)
%   input.sweep     - sweep angle in degrees (used via cosd)
%   input.Scsw      - S_{csw} control-surface related area [ft^2]
%   input.K_dw      - K_{dw} correction factor (default 1)
%   input.K_vs      - K_{vs} correction factor (default 1)
%
%   input.Sht       - horizontal tail area S_{ht} [ft^2]
%   input.F_w       - F_w (used in horizontal tail factor) (default 0)
%   input.B_h       - B_h (used in horizontal tail factor) (default 1)
%
%   input.Svt       - vertical tail area S_{vt} [ft^2]
%   input.K_rht     - K_{rht} correction factor (default 1)
%   input.H_t       - H_t (vertical tail geometry; default 1)
%   input.H_v       - H_v (vertical tail geometry; default 1)
%   input.M         - Mach or M (used in Vtail formula) (default 0.8)
%   input.L_t       - tail moment arm L_t [ft]
%   input.S_r       - S_r additional surface area [ft^2]
%   input.A_vt      - A_{vt} vertical tail aspect ratio (or shape factor)
%   input.lam_vt    - taper ratio for v-tail (if different) (default same as input.lambda)
%   input.sweep_vt  - sweep for vertical tail (deg)
%
%   input.L         - fuselage length L [ft]
%   input.D         - fuselage diameter or depth D [ft]
%   input.W_param   - W parameter used in fuselage formula (named W in equation)
%   input.K_dwf     - K_{dwf} correction factor (default 1)
%
%   input.WNl       - W_{Nl} (landing weight used for LG sizing) [lb]
%   input.K_cb      - K_{cb} correction for main gear (default 1)
%   input.K_tpg     - K_{tpg} correction for main gear (default 1)
%   input.Lm        - L_m main gear length [ft]
%
%   input.Ln        - L_n nose gear length [ft]
%   input.Nnw       - N_{nw} number of nose wheels (default 1)
%
%   input.Nen       - N_{en} number of engines
%   input.T         - thrust (T) [lbf] (per engine or total consistent with original formula)
%   input.Wen       - W_{en} single engine weight [lb]
%   input.Nen       - number of engines (used across engine formulas)
%
%   input.Sfw       - firewall area [ft^2]
%
%   input.K_vg      - K_{vg} correction factor (default 1)
%   input.Ld        - L_d (intake characteristic length) [ft]
%   input.Kd        - K_d (intake correction factor) (default 1)
%   input.Ls        - L_s (some intake length) [ft]
%   input.De        - D_e engine diameter [ft]
%   input.Ltp       - L_{tp} tailpipe length [ft]
%   input.Lsh       - L_{sh} engine cooling length [ft]
%   input.T_e       - T_e starter thrust/power param (for starter) (units consistent with formula)
%
%   input.Vt        - V_t total fuel volume [units consistent with formula]
%   input.Vi        - V_i internal fuel volume
%   input.Vp        - V_p external/pod fuel volume
%   input.Nt        - N_t number of tanks
%   input.SFC       - specific fuel consumption (use same units as in formula)
%
%   input.Mach      - M (Mach) if used in flight-controls or tails
%   input.Scs       - S_{cs} control-surface area for flight-controls
%   input.Ns        - N_s number of control surfaces
%   input.Nc        - N_c crew count
%
%   input.K_vsh     - K_{vsh} hydraulics factor (default 1)
%   input.Nu        - N_u (hydraulics design factor)
%
%   input.K_mc      - K_{mc} electrical system factor (default 1)
%   input.R_kva     - R_{kva} electrical power rating
%   input.Ngen      - N_{gen} number of generators
%   input.La        - L_a electrical length factor (default 1)
%
%   input.W_uav     - W_{uav} uninstalled avionics weight (lb)
%
% OUTPUT struct fields:
%   output.W_wing, output.W_htail, output.W_vtail, output.W_fuselage,
%   output.W_mlg, output.W_nlg, output.W_engine_mounts, output.W_firewall,
%   output.W_engine_section, output.W_air_induction, output.W_tailpipe,
%   output.W_engine_cooling, output.W_oil_cooling, output.W_engine_controls,
%   output.W_starter_pneumatic, output.W_fuel_system, output.W_flight_controls,
%   output.W_instruments, output.W_hydraulics, output.W_electrical,
%   output.W_avionics, output.W_furnishings, output.W_aircon_antiice,
%   output.W_handling_gear
%
% Example:
%   in.Wdg = 33000; in.Nz = 9; in.Sw = 300; ...; out = calcRaymerWeights(in);

% Helper to fetch input field with default
getf = @(s,fn,def) (isfield(s,fn) && ~isempty(s.(fn))).*(s.(fn)) + (~isfield(s,fn) | (isempty(s.(fn)))).*def;
% Note: the above returns numeric arrays; if fields are arrays it will work elementwise.

% Read inputs (use getf to provide defaults)
Wdg    = getf(input,'Wdg',0);        % W_{dg}
Nz     = getf(input,'Nz',1);         % N_z
Sw     = getf(input,'Sw',0);         % S_w
AR     = getf(input,'AR',1);         % Aspect ratio A
tc_root= getf(input,'tc_root',0.12); % (t/c)_root
lam    = getf(input,'lambda',0.0);   % taper ratio lambda
sweep  = getf(input,'sweep',0);      % sweep in degrees
Scsw   = getf(input,'Scsw',1);       % S_{csw}
K_dw   = getf(input,'K_dw',1);       % K_{dw}
K_vs   = getf(input,'K_vs',1);       % K_{vs}

% Horizontal tail inputs
Sht    = getf(input,'Sht',0);        % S_{ht}
Fw     = getf(input,'F_w',0);        % F_w
Bh     = getf(input,'B_h',1);        % B_h

% Vertical tail inputs
Svt    = getf(input,'Svt',0);        % S_{vt}
K_rht  = getf(input,'K_rht',1);      % K_{rht}
Ht     = getf(input,'H_t',1);        % H_t
Hv     = getf(input,'H_v',1);        % H_v
M_vt   = getf(input,'M',0.8);        % M in V-tail formula (Mach or other factor)
Lt     = getf(input,'L_t',1);        % L_t
Sr     = getf(input,'S_r',0);        % S_r
Avt    = getf(input,'A_vt',1.0);     % A_{vt}
lam_vt = getf(input,'lam_vt',lam);   % lam for vt if provided
sweep_vt= getf(input,'sweep_vt',0);  % sweep for vertical tail

% Fuselage inputs
Lfus   = getf(input,'L',0);          % fuselage length L
Df     = getf(input,'D',0);          % fuselage diameter D
Wparam = getf(input,'W_param',0);    % W parameter used in fuselage eqn (named W)
K_dwf  = getf(input,'K_dwf',1);      % K_{dwf}

% Landing gear inputs
WNl    = getf(input,'WNl',Wdg);      % W_{Nl} default to Wdg if not provided
K_cb   = getf(input,'K_cb',1);       % K_{cb}
K_tpg  = getf(input,'K_tpg',1);      % K_{tpg}
Lm     = getf(input,'Lm',1);         % L_m

Ln     = getf(input,'Ln',1);         % L_n
Nnw    = getf(input,'Nnw',1);        % N_{nw}

% Engine & nacelle inputs
Nen    = getf(input,'Nen',1);        % N_{en}
T      = getf(input,'T',0);          % T (thrust)
Wen    = getf(input,'Wen',0);        % W_{en}
Sfw    = getf(input,'Sfw',0);        % firewall area S_{fw}

K_vg   = getf(input,'K_vg',1);       % K_{vg}
Ld     = getf(input,'Ld',1);         % L_d
Kd     = getf(input,'Kd',1);         % K_d
Ls     = getf(input,'Ls',1);         % L_s
De     = getf(input,'De',1);         % D_e
Ltp    = getf(input,'Ltp',1);        % L_{tp}
Lsh    = getf(input,'Lsh',1);        % L_{sh}
Te     = getf(input,'Te',0);         % T_e

% Fuel system inputs
Vt     = getf(input,'Vt',0);         % V_t total fuel volume
Vi     = getf(input,'Vi',0);         % V_i internal fuel volume
Vp     = getf(input,'Vp',0);         % V_p external/pod fuel volume
Nt     = getf(input,'Nt',1);         % N_t
SFC    = getf(input,'SFC',1);        % SFC (use consistent units)

% Flight controls / instruments / crew
Mach   = getf(input,'Mach',0.8);     % Mach (if used)
Scs    = getf(input,'Scs',0);        % S_{cs}
Ns     = getf(input,'Ns',1);         % N_s
Nc     = getf(input,'Nc',1);         % N_c
Nu     = getf(input,'Nu',1);         % N_u

% Hydraulics
K_vsh  = getf(input,'K_vsh',1);      % K_{vsh}

% Electrical
K_mc   = getf(input,'K_mc',1);       % K_{mc}
R_kva  = getf(input,'R_kva',1);      % R_{kva}
Ngen   = getf(input,'Ngen',1);       % N_{gen}
La     = getf(input,'La',1);         % L_a

% Avionics / furnishings
W_uav  = getf(input,'W_uav',0);      % W_{uav}

% -----------------------------
% Now compute each equation exactly as pasted
% -----------------------------

% Wing weight:
% W_wing = 0.0103 K_dw K_vs (W_dg N_z)^{0.5} S_w^{0.622} A^{0.785} (t/c)_{root}^{-0.4}
%          (1+lambda)^{0.05} (cos Lambda)^{-1.0} S_{csw}^{0.04}
W_wing = 0.0103 .* K_dw .* K_vs .* (Wdg .* Nz).^0.5 .* Sw.^0.622 .* AR.^0.785 .* tc_root.^(-0.4) ...
         .* (1 + lam).^0.05 .* (cosd(sweep)).^(-1.0) .* Scsw.^0.04;

% Horizontal tail:
% W_horizontal tail = 3.316 (1 + F_w/B_h)^{-2.0} ((W_dg N_z)/1000)^{0.260} S_ht^{0.806}
W_htail = 3.316 .* (1 + (Fw ./ Bh)).^(-2.0) .* ((Wdg .* Nz) ./ 1000).^0.260 .* Sht.^0.806;

% Vertical tail:
% W_vertical tail = 0.452 K_{rht} (1 + H_t/H_v)^{0.5} (W_dg N_z)^{0.488} S_{vt}^{0.718} M^{0.341}
%                   L_t^{-1.0} (1 + S_r / S_{vt})^{0.348} A_{vt}^{0.223} (1+\lambda)^{0.25} (cos Lambda_vt)^{-0.323}
W_vtail = 0.452 .* K_rht .* (1 + Ht ./ Hv).^0.5 .* (Wdg .* Nz).^0.488 .* Svt.^0.718 .* M_vt.^0.341 ...
          .* Lt.^(-1.0) .* (1 + Sr ./ max(Svt,eps)).^0.348 .* Avt.^0.223 .* (1 + lam_vt).^0.25 .* (cosd(sweep_vt)).^(-0.323);

% Fuselage:
% W_fuselage = 0.499 K_{dwf} W_{dg}^{0.35} N_z^{0.25} L^{0.5} D^{0.849} W^{-0.685}
W_fuselage = 0.499 .* K_dwf .* Wdg.^0.35 .* Nz.^0.25 .* Lfus.^0.5 .* Df.^0.849 .* Wparam.^(0.685);

% Main landing gear:
% W_main landing gear = K_cb K_tpg (W_Nl)^{0.25} L_m^{0.973}
W_mlg = K_cb .* K_tpg .* (WNl).^0.25 .* Lm.^0.973;

% Nose landing gear:
% W_nose landing gear = (W_Nl)^{0.290} L_n^{0.5} N_{nw}^{0.525}
% NOTE: original uses (W_{Nl})^{0.290} but likely intended a different W for nose; using WNl as provided
W_nlg = (WNl).^0.290 .* Ln.^0.5 .* Nnw.^0.525;

% Engine mounts:
% W_engine mounts = 0.013 N_en^{0.795} T^{0.579} N_z
W_engine_mounts = 0.013 .* (Nen).^0.795 .* T.^0.579 .* Nz;

% Firewall:
% W_firewall = 1.13 S_fw
W_firewall = 1.13 .* Sfw;

% Engine section:
% W_engine section = 0.01 W_en^{0.717} N_en N_z
W_engine_section = 0.01 .* Wen.^0.717 .* Nen .* Nz;

% Air induction system:
% W_air_induction = 13.29 K_vg L_d^{0.643} K_d^{0.182} N_en^{1.498} (L_s/L_d)^{-0.373} D_e
W_air_induction = 13.29 .* K_vg .* Ld.^0.643 .* Kd.^0.182 .* (Nen).^1.498 .* ( (Ls ./ max(Ld,eps)).^(-0.373) ) .* De;

% Tailpipe:
% W_tailpipe = 3.5 D_e L_tp N_en
W_tailpipe = 3.5 .* De .* Ltp .* Nen;

% Engine cooling:
% W_engine cooling = 4.55 D_e L_sh N_en
W_engine_cooling = 4.55 .* De .* Lsh .* Nen;

% Oil cooling:
% W_oil cooling = 37.82 N_en^{1.023}
W_oil_cooling = 37.82 .* Nen.^1.023;

% Engine controls:
% W_engine controls = 10.5 N_en^{1.008} L_ec^{0.222}
Lec = getf(input,'Lec',1); % L_{ec} engine controls length
W_engine_controls = 10.5 .* Nen.^1.008 .* Lec.^0.222;

% Starter (pneumatic):
% W_starter (pneumatic) = 0.025 T_e^{0.760} N_en^{0.72}
W_starter_pneumatic = 0.025 .* Te.^0.760 .* Nen.^0.72;

% Fuel system and tanks:
% W_fuel system and tanks = 7.45 V_t^{0.47} (1 + V_i/V_t)^{-0.095} (1 + V_p/V_t) N_t^{0.066} N_en^{0.052} (T*SFC/1000)^{0.249}
% Protect against division by zero if Vt == 0
Vt_safe = max(Vt, eps);
W_fuel_system = 7.45 .* Vt_safe.^0.47 .* (1 + (Vi ./ Vt_safe)).^(-0.095) .* (1 + (Vp ./ Vt_safe)) ...
                .* Nt.^0.066 .* Nen.^0.052 .* ((T .* SFC ./ 1000)).^0.249;

% Flight controls:
% W_flight controls = 36.28 M^{0.003} S_cs^{0.489} N_s^{0.484} N_c^{0.127}
W_flight_controls = 36.28 .* Mach.^0.003 .* Scs.^0.489 .* Ns.^0.484 .* Nc.^0.127;

% Instruments:
% W_instruments = 8.0 + 36.37 N_en^{0.676} N_t^{0.237} + 26.4(1 + N_ci)^{1.356}
% N_ci = number of crew instrumentation sets? default 0
Nci = getf(input,'Nci',0);
W_instruments = 8.0 + 36.37 .* Nen.^0.676 .* Nt.^0.237 + 26.4 .* (1 + Nci).^1.356;

% Hydraulics:
% W_hydraulics = 37.23 K_vsh N_u^{0.664}
W_hydraulics = 37.23 .* K_vsh .* Nu.^0.664;

% Electrical:
% W_electrical = 172.2 K_mc R_kva^{0.152} N_c^{0.10} L_a^{0.10} N_gen^{0.091}
W_electrical = 172.2 .* K_mc .* R_kva.^0.152 .* Nc.^0.10 .* La.^0.10 .* Ngen.^0.091;

% Avionics:
% W_avionics = 2.117 W_uav^{0.933}
W_avionics = 2.117 .* W_uav.^0.933;

% Furnishings:
% W_furnishings = 217.6 N_c
W_furnishings = 217.6 .* Nc;

% Air conditioning and anti-ice:
% W_airconditioning = 201.6 ((W_uav + 200 N_c)/1000)^{0.735}
W_aircon_antiice = 201.6 .* ((W_uav + 200 .* Nc) ./ 1000).^0.735;

% Handling gear:
% W_handling_gear = 3.2e-4 W_dg
W_handling_gear = 3.2e-4 .* Wdg;


% My own thing

W_engine_weight = Nen * Wen;

% -----------------------------
% Collect outputs
% -----------------------------
output.W_wing                = W_wing;
output.W_htail               = W_htail;
output.W_vtail               = W_vtail;
output.W_fuselage            = W_fuselage;
output.W_mlg                 = W_mlg;
output.W_nlg                 = W_nlg;
output.W_engine_mounts       = W_engine_mounts;
output.W_firewall            = W_firewall;
output.W_engine_section      = W_engine_section;
output.W_engine_weight       = W_engine_weight;
output.W_air_induction       = W_air_induction;
output.W_tailpipe            = W_tailpipe;
output.W_engine_cooling      = W_engine_cooling;
output.W_oil_cooling         = W_oil_cooling;
output.W_engine_controls     = W_engine_controls;
output.W_starter_pneumatic   = W_starter_pneumatic;
output.W_fuel_system         = W_fuel_system;
output.W_flight_controls     = W_flight_controls;
output.W_instruments         = W_instruments;
output.W_hydraulics          = W_hydraulics;
output.W_electrical          = W_electrical;
output.W_avionics            = W_avionics;
output.W_furnishings         = W_furnishings;
output.W_aircon_antiice      = W_aircon_antiice;
output.W_handling_gear       = W_handling_gear;

end