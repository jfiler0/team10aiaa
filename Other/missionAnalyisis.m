clear; clc; close all;

%% DEFINE CONSTANTS
AR = 3; % Aspect ratio
e = 0.914; % Oswald efficiency factor 
W_TO = 26257; % Takeoff weight initial guess (lbf)
W_TO_O_S_I = 104.59; %lb/ft2 (imperial)

% Convert Wing Loading
W_TO_O_S = lb2N(W_TO_O_S_I) * 3.2808399^2; %N/m2

% Define flight conitions (helps simplify later code and make it more applicable)
cruise_TSFC = 0.00019;
seg1_cond = flight_condition(ft2m(40000), 0.87, cruise_TSFC, 0.026996);
dash_cond = flight_condition(ft2m(40000), 1.5, 0.00061, 0.026996);
seg2_cond = flight_condition(ft2m(40000), 0.87, cruise_TSFC, 0.016996);
loiter_cond = flight_condition(ft2m(10000), 0.3, cruise_TSFC, 0.016996);

% N - Define initial guess
W0 = lb2N(W_TO); 
% Use aircraft constructor to store wing + engine info
f16 = make_aircraft("F16", AR, e, lb2N(W_TO)/W_TO_O_S, W0, lb2N(0.75*700), lb2N(4400), lb2N(9906.98));

%% Main Loop
%Initialize loop values
i = 0;
iter_max = 1000;
tol = 0.025/100;

while i < iter_max

    f16.S = W0 / W_TO_O_S; % Update aircraft surface area
    i = i + 1;
        
    [W1, f1] = apply_WF(W0, 0.95); % TAKEOFF
    [W2, f2] = segment_climb(W1, 0.87); % CLIMB
    [W3, WF_3, f3, LD3] = flight_segment(W2, "CRUISE", nm2m(190), seg1_cond, f16); % CRUISE 1
    [W4, WF_4, f4, LD4] = flight_segment(W3, "CRUISE", nm2m(50), dash_cond, f16); % DASH
    [W5, WF_5, f5] = segment_combat(W4, 2*60, 0.75*1.708/(60*60), f16.W_P, f16.TA_max); % COMBAT
    [W6, WF_6, f6, LD6] = flight_segment(W5, "CRUISE", nm2m(250), seg2_cond, f16); % CRUISE 2
    [W7, WF_7, f7, LD7] = flight_segment(W6, "LOITER", 20*60, loiter_cond, f16); % LOTIER
    [W8, f8] = apply_WF(W7, 0.995); % LANDING
    
    fixed_weight = f16.W_F + f16.W_P; % Calling fixed weight and payload from aircraft constructor
    
    fuel_weight = f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8 ;
    fuel_fraction = fuel_weight / W0;
    
    empty_weight_fraction = 2.34*N2lb(W0)^(-0.13) ; % Use historical data
    empty_weight = W0 * empty_weight_fraction;
    
    % Update the guess
    W_TO_new = fixed_weight / (1 - empty_weight_fraction - fuel_fraction );
    
    % Check tolerance
    if( abs(W_TO_new - W0)/W0 < tol)
       i = iter_max; %Seems more reliable than break
    else
        W0 = W_TO_new;
    end
end

% Set imperial variables for the grader
W_Takeoff = N2lb(W1)
f1 = N2lb(f1)
W_Climb = N2lb(W2)
f2 = N2lb(f2)
W_Cruise = N2lb(W3)
f3 = N2lb(f3)
W_Dash = N2lb(W4)
f4 = N2lb(f4)
W_Combat = N2lb(W5)
f5 = N2lb(f5)
W_Cruise2 = N2lb(W6)
f6 = N2lb(f6)
W_Loiter = N2lb(W7)
f7 = N2lb(f7)
W_Landing = N2lb(W8)
f8 = N2lb(f8)
total_fuel_used = N2lb(fuel_weight)
empty_weight = N2lb(empty_weight)
W_TO = N2lb(W0)

%% Data Constructors
function cond = flight_condition(altitude, mach, TSFC, CD0)
    %Constructor for cleaner code and generalization
    cond.altitude = altitude;
    [cond.T, cond.a, cond.P, cond.rho, cond.nu, cond.mu] = atmosisa(altitude); %METRIC

    cond.mach = mach;
    cond.V = cond.mach * cond.a;
    cond.q = 0.5*cond.rho*cond.V^2;

    cond.TSFC = TSFC;
    cond.CD0 = CD0;
end
function aircraft = make_aircraft(name, AR, e, S, W0, W_F, W_P, TA_max)

    aircraft.name = name;
    aircraft.AR = AR; % ASPECT RATIO
    aircraft.e = e; % OSWALD EFFICENCY
    aircraft.W0 = W0; % GROSS TAKEOFF WEIGHT - N
    aircraft.S = S; % WING AREA - m2
    aircraft.W_F = W_F; % FIXED WEIGHT - N
    aircraft.W_P = W_P; % PAYLOAD - N (gets deployed)
    aircraft.TA_max = TA_max; % MAX TA - N (for combat)

end

%% Unit Conversion Helpers
function  m = ft2m(ft)
    m = ft / 3.2808399; % Because why is this imperial
end
function m = nm2m(nm)
    m = 1852*nm;
end
function N = lb2N(lb)
    N = lb / 0.224808943;
end
function lb = N2lb(N)
    lb = N * 0.224808943;
end

function [W_out, fuel_used] = apply_WF(W_in, WF)
    %This covers both landing and takeoff

    % ARGUMENTS:
    %   W_in = Aircraft weight at end of previous segment (N)
    %   W_TO = Takeoff weight (N)
    
    % RETURNS:
    %   W_out = Aircraft weight at end of segment (N)
    %   fuel_used = Weight of burned fuel (N)

    W_out = WF*W_in;
    fuel_used = W_in - W_out;
end
function [W_out, WF, fuel_used, LD] = flight_segment(W_in, type, time_or_range, cond, aircraft)
    % ARGUMENTS:
    %   W_in = Previous segment's end weight (N)
    %   aircraft (AR, e, wing properties)
    %   cond (CD0, altitude, velocity)
    %   TSFC = Thrust Specific Fuel Consumption (1/s)
    %   time_or_range = Time spent in segment (s) when type is "LOITER" OR Distance flown (m) when type is "CRUISE"
    
    % RETURNS:
    %   W_out = Aircraft's weight at segment's end (N)
    %   WF = Weight fraction of segment (dimensionless)
    %   fuel_used = Weight of burned fuel (N)
    %   LD = Lift-to-drag ratio (dimensionless)

    cond.q;
    
    LD = 1 / ( (cond.q*cond.CD0) / (W_in/aircraft.S) + (W_in/aircraft.S) / (cond.q * pi * aircraft.e * aircraft.AR) );

    if type == "CRUISE"
        WF = exp( -(time_or_range*cond.TSFC) / (cond.V*LD) );
    elseif(type == "LOITER")
        WF = exp( (-time_or_range*cond.TSFC)/LD);
    else
        error("Not a defined flight segement")
    end
    
    W_out = W_in*WF;
    fuel_used = W_in - W_out;

end
function [W_out, WF, fuel_burned] = segment_combat(W_in, time, TSFC, payload, TA)
    % ARGUMENTS:
    %   W_in = Aircraft weight at beginning of segment (N)
    %   time = Segment duration (s)
    %   TSFC = Thrust Specific Fuel Consumption (1/s)
    %   payload = Payload weight (N)
    %   TA = Thrust Available (N)
    
    % RETURNS:
    %   W_out = Aircraft weight at segment's end (N)
    %   fuel_burned = Weight of fuel burned during the segment (N)
    %   WF = Weight fraction (dimensionless)
    
    fuel_burned = time*TSFC*TA;
    W_out = W_in - fuel_burned - payload;
    WF = W_out/W_in;
end
function [W_out, fuel_used] = segment_climb(W_in, Mach)
    % ARGUMENTS:
    %   W_TO = Gross takeoff weight (N)
    %   W_in = Aircraft's weight at the segment's start (N)
    %   Mach = Mach number (I hope you recognize this, otherwise God help you)
    
    % OUTPUTS:
    %   W_out = Aircraft's weight at the end of the segment (N)
    %   fuel_used = Weight of the fuel burned during this segment (N)
    
    % W_out = W_in*(0.991 - 0.007*Mach - 0.01*Mach.^2);
    WF = 1.0065 - 0.0325*Mach;
    W_out = W_in*WF;
    fuel_used = W_in - W_out;
end