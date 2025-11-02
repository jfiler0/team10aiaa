%% Homework 1
% Xander Fry
% AOE 4065

%% Constants
W_TO_new = 45000; % Takeoff weight initial guess (lbf)
W_S = 104.59; % Wing loading (lbf/ft^2)
% weight naming covention: _XX denotes what segment was just finished
Mach_climb = 0.87;
Mach_cruise1=0.87;
Mach_cruise2=0.87;
TSFC_cruise=0.00019;
TSFC_loiter=TSFC_cruise;
TSFC_dash=0.00061;
TSFC_combat=0.02847/60; %to get in per second
e=0.914;
AR=3;
CD0_laden=0.027;
CD0_unladen=0.017;
Distance_cruise1=190; %nm
Distance_dash=50; %nm
time_combat=2; %min
payload=4400; %lbs
Distance_cruise2=250; %nm
time_loiter=20; %min
iter=0; %inializing iteration variable
max_iter=1000; % maximum number of iterations
difference=100; % initializing percent error variable
max_diff=0.5; %max percent error tolerable

%% While loop:
% calls each function, feeding outputs weight of one into the
% next. It then calculates a new take off weight and uses this in the next
% iteration.
while iter<max_iter & norm(difference)>max_diff
    W_TO=W_TO_new;
    iter=iter+1;
    [W_takeoff,fuel_used_takeoff]=segment_takeoff(W_TO);
    [W_climb, fuel_used_climb] = segment_climb(W_TO, W_takeoff, Mach_climb);
    [W_cruise1, fuel_used_cruise1, WF_cruise1, LD_cruise1, V_cruise1] = segment_cruise(W_climb, TSFC_cruise, Distance_cruise1, Mach_cruise1, CD0_laden, e, AR, W_TO);
    [W_dash, fuel_burned_dash, LD_dash, WF_dash, V_dash] = segment_dash(W_cruise1, W_TO, CD0_laden, e, AR, TSFC_dash, Distance_dash);
    [W_combat, fuel_used_combat, WF_combat] = segment_combat(W_dash, time_combat, TSFC_combat, payload);
    [W_cruise2, fuel_used_cruise2, WF_cruise2, LD_cruise2, V_cruise2] = segment_cruise(W_combat, TSFC_cruise, Distance_cruise2, Mach_cruise2, CD0_unladen, e, AR, W_TO);
    [W_loiter, WF_loiter, fuel_used_loiter, LD_loiter] = segment_loiter(W_TO, W_cruise2, CD0_unladen, e, AR, time_loiter, TSFC_loiter);
    [W_landing, fuel_used_landing] = segment_landing(W_loiter, W_TO);

    total_fuel_used=fuel_used_takeoff+fuel_used_climb+fuel_used_cruise1+fuel_burned_dash+fuel_used_combat+fuel_used_cruise2+fuel_used_loiter+fuel_used_landing;
    fuel_fraction=1.06*total_fuel_used/W_TO;
    empty_weight_fraction=2.34*W_TO^(-0.13);
    empty_weight=empty_weight_fraction*W_TO;
    fixed_weight=payload+700; % adding the 700 lbs fixed weight
    W_TO_new=fixed_weight/(1-empty_weight_fraction-fuel_fraction);
    difference=100*(W_TO-W_TO_new)/W_TO;
end

%% ---- Add: Max-range wing loading at cruise (jet) ----
k = 1/(pi*e*AR);                 % induced-drag factor
a_cr = 968.076;                  % ft/s @ 40,000 ft
rho_cr = 0.000585189;            % slugs/ft^3 @ 40,000 ft
V_cr = a_cr*Mach_cruise1;        % ft/s (your cruise Mach)
q_cr = 0.5*rho_cr*V_cr^2;        % dynamic pressure
CL_range = sqrt(CD0_laden/(3*k));            % jet max-range CL
W_S_max_range = q_cr * CL_range             % wing loading at max-range condition

%% ---- Add: Max-endurance time at loiter (jet Breguet) ----
% Uses weights around the loiter segment: W_cruise2 (start), W_loiter (end)
% Computes the max endurance achievable if flown at the jet max-endurance CL.
rho_lo = 0.00175549;     % slugs/ft^3 @ 10,000 ft
a_lo   = 1077.39;        % ft/s @ 10,000 ft
CL_end = sqrt(3*CD0_unladen/k);                          % jet max-endurance CL
LD_end = CL_end / (CD0_unladen + k*CL_end^2);            % corresponding L/D
Wi_loiter = W_cruise2;            % weight entering loiter
Wf_loiter = W_loiter;             % weight leaving loiter
E_max_loiter_sec = (1/TSFC_loiter) * LD_end * log(Wi_loiter/Wf_loiter);
E_max_loiter_min = E_max_loiter_sec/60;

% Optional: W/S at max-endurance CL at your chosen loiter speed (Mach 0.3)
V_lo   = a_lo*0.3;                      % ft/s
q_lo   = 0.5*rho_lo*V_lo^2;
W_S_endurance_loiter = q_lo * CL_end   % wing loading at max-endurance CL for that V

%% renaming variables to MathWorks standards:
W_Takeoff=W_takeoff;
W_Climb=W_climb;
W_Cruise=W_cruise1;
W_Dash=W_dash;
W_Combat=W_combat;
W_Cruise2=W_cruise2;
W_Loiter=W_loiter;
W_Landing=W_landing;
f1=fuel_used_takeoff;
f2=fuel_used_climb;
f3=fuel_used_cruise1;
f4=fuel_burned_dash;
f5=fuel_used_combat;
f6=fuel_used_cruise2;
f7=fuel_used_loiter;
f8=fuel_used_landing;

%% List of functions for each segment
function [W_out, fuel_used] = segment_takeoff(W_in)
WF=0.95;
W_out=W_in*WF;
fuel_used=W_in-W_out;
end

function [W_out, fuel_used] = segment_climb(W_TO, W_in, Mach)
WF_climb = 1.0065-0.0325*Mach;
fuel_used = (1-WF_climb)*W_TO; %used W_in here instead of the recommended W_{TO} bc we have the section weight fraction.
W_out=W_in-fuel_used;
end

function [W_out, fuel_used, WF, LD, V] = segment_cruise(W_in, TSFC, Distance, Mach, CD0, e, AR, W_TO)
% from standard atmosphere calcultor @40,000 ft:
a=968.076; %ft/s
rho=0.000585189; %slugs/ft^3
p=391.686; %lbf/ft^2

load_factor_TO=104.59; %W_TO/S
S=W_TO/load_factor_TO;
load_factor_cruise=W_in/S;

V=a*Mach;

q=1/2*rho*V^2;
LD=(q*CD0/load_factor_cruise+load_factor_cruise/(q*pi()*e*AR))^(-1);

Distance=Distance*6076.11549; %converting nm to ft
time=Distance/V; %seconds

% during cruise, steady level flight, so L=W_in & T=D
T=1/LD*W_in;
fuel_used=TSFC*time*T;

W_out=W_in-fuel_used;
WF=W_out/W_in;
end

function [W_out, fuel_burned, LD, WF, V] = segment_dash(W_in, W_TO, CD0, e, AR, TSFC, Distance)
% @ 40,000 ft:
a=968.076; %ft/s
rho=0.000585189; %slugs/ft^3
p=391.686; %lbf/ft^2

load_factor_TO=104.59; %W_TO/S
S=W_TO/load_factor_TO;
load_factor_cruise=W_in/S;
Mach=1.5;
V=a*Mach;

q=1/2*rho*V^2;
LD=(q*CD0/load_factor_cruise+load_factor_cruise/(q*pi()*e*AR))^(-1);

Distance=Distance*6076.11549; %converting nm to ft
time=Distance/V; %seconds

% during cruise, steady level flight, so L=W_in & T=D
T=1/LD*W_in;
fuel_burned=TSFC*time*T;

W_out=W_in-fuel_burned;
WF=W_out/W_in;

end

function [W_out, fuel_used, WF] = segment_combat(W_in, time, TSFC, payload)
T_a=9906.98;
W_fuel_combat=time*60*TSFC*T_a; %factor of 60 to convert min to sec.
fuel_used=W_fuel_combat;

W_out=W_in-fuel_used-payload;

WF=W_out/W_in;
end

function [W_out, WF, fuel_used, LD] = segment_loiter(W_TO, W_in, CD0, e, AR, time, TSFC)
Mach=0.3;
% @ 10,000 ft:
a=1077.39; %ft/s
rho=0.00175549; %slugs/ft^3

load_factor_TO=104.59; %W_TO/S
S=W_TO/load_factor_TO;
load_factor_cruise=W_in/S;

V=a*Mach;

q=1/2*rho*V^2;
LD=(q*CD0/load_factor_cruise+load_factor_cruise/(q*pi()*e*AR))^(-1);

% during cruise, steady level flight, so L=W_in & T=D
T=1/LD*W_in;
time=time*60;
fuel_used=TSFC*time*T;

W_out=W_in-fuel_used;
WF=W_out/W_in;

end

function [W_out, fuel_used] = segment_landing(W_in, W_TO)
WF=0.995;
W_out=WF*W_in;
fuel_used=W_in-W_out;
end
