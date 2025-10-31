%% Formatting - cause plots must be beautiful
clear;clc;close all;
set(0,'defaultfigureposition',[50 80 1300 650]')

set(groot, 'defaultAxesFontName', 'Times New Roman');
set(groot, 'defaultTextFontName', 'Times New Roman');
set(groot, 'defaultAxesFontSize', 24);
set(groot, 'defaultTextFontSize', 14);
set(groot, 'defaultLegendFontSize', 18);
set(groot, 'defaultColorbarFontSize', 14);
set(groot, 'defaultAxesTitleFontWeight', 'normal');

% Set default interpreter to LaTeX
set(groot, 'defaultTextInterpreter', 'latex');
set(groot, 'defaultAxesTickLabelInterpreter', 'latex');
set(groot, 'defaultLegendInterpreter', 'latex');

% Line width
set(groot, 'defaultLineLineWidth', 2);

%% Atmosphere table
% This only needs to be run if atmoshper_lookup.mat is not created. But it should already be downloaded
% build_atmosphere_lookup(0, 50000, 1000)

%% Notes

% Current script does not actually find the optimal cruise and endurance points
% No corrections to TSFC right now for afterburner

%% Start with a single call and can make optimization later

% These can be varyed to optimze (especially if we can get correllations for weight + cost)
% They are apart of L/D induced drag calcs for mission weight
AR = 4;
e = 0.85;

% Note the engine input by name at the end here
% Using constructors = much cleaner code
% Payload and fixed weights are driven here
plane = make_aircraft("FAXX", AR, e, lb2N(2000), lb2N(10000), "F404");

% Constructor for cleaner code
function aircraft = make_aircraft(name, AR, e, W_F, W_P, engine)
    aircraft.name = name;
    aircraft.AR = AR; % ASPECT RATIO
    aircraft.e = e; % OSWALD EFFICENCY
    aircraft.W_F = W_F; % FIXED WEIGHT - N
    aircraft.W_P = W_P; % PAYLOAD - N (gets deployed)
    aircraft.engine = engine; % String for engine lookup
    aircraft.S = 1; % Is updated in the loop
end

% SOLVE CONSTRAINT ANALYSIS. First variable toggles constraint plot
W_TO_O_S = constraintAnalysis(true, plane.engine); % Wing loading [N/m2] from constrain analyisis

%% Create missions

% Input into L/D calculations for paraiste drag
Cd0_dirty = 0.026996; % Carrying payload
Cd0_clean = 0.016996; % No external stores

% % Ferry mission
ferry = [...
    flightSegment("TAKEOFF") 
    flightSegment("CLIMB", 0.7) 
    flightSegment("CRUISE", 0.6, NaN, Cd0_clean, nm2m(1000)) % 800 nm flight
    flightSegment("LOITER", NaN, 10000, Cd0_clean, 20) % 20 min loiter
    flightSegment("COMBAT", 0.8, 1000, Cd0_clean, [8 plane.W_P]) % 8 minutes of combat, deploy payload
    flightSegment("CRUISE", 0.6, NaN, Cd0_clean, nm2m(1000)) % 800 nm flight
    flightSegment("LANDING") ];

air2ground = [...
    flightSegment("TAKEOFF") 
    flightSegment("CLIMB", 0.85) % Check this mach
    flightSegment("CRUISE", 0.85, ft2m(30000), Cd0_dirty, nm2m(700)) % 700 nm flight
    flightSegment("LANDING") % Saying this is decent
    flightSegment("LOITER", NaN, ft2m(10000), Cd0_dirty, 10) % 10 min loiter
    flightSegment("CLIMB", 0.85) % Check this mach
    flightSegment("CRUISE", 0.85, NaN, Cd0_dirty, nm2m(50)) % Penetrate
    flightSegment("COMBAT", 0.85, 1000, Cd0_dirty, [30/60 plane.W_P/2]) % quick combat
    flightSegment("CLIMB", 0.85) % Check this mach
    flightSegment("CRUISE", 0.85, ft2m(30000), Cd0_clean, nm2m(700)) % 700 nm flight
    flightSegment("LOITER", NaN, ft2m(10000), Cd0_clean, 20) % 20 min loiter
    flightSegment("LANDING") ];

%% Solve for W0

% SET WHICH MISSION YOU WANT TO ANALYZE HERE
mission = ferry;

% Initial guess
W0_init = 1e5;  

W0 = fminsearch(@(W) W0_res(W, mission, plane, W_TO_O_S), W0_init);

% Alot of trial and error was needed to make this function robust as it has multiple local minimums that arent solutions
function res = W0_res(W0_guess, mission, plane, W_TO_O_S)
    plane.S = W0_guess / W_TO_O_S;
    Wj = W0_guess;
    fb_sum = 0;
    for j = 1:length(mission)
        [Wj, WF, fb] = mission(j).queryWF(Wj, plane);
        fb_sum = fb_sum + fb;
    end

    fb_sum = fb_sum/0.95; % 5% fuel saving

    fixed_weight = plane.W_F + plane.W_P;
    % empty_weight_fraction = 0.4;
    empty_weight_fraction = 2.34*N2lb(W0_guess)^(-0.13) ; % Use historical data

    fuel_fraction = fb_sum / W0_guess;

    W0_new = real( fixed_weight / (1 - empty_weight_fraction - fuel_fraction) );

    turn_point = 0.05; % As 1 - fractions approaches 0, residual skyrockets. This creates a barrier for solutions left of the spike
    
    % This setup ensure the gradient is always towards the solution with no local minima
    if(W0_guess < 0)
        res = abs(fixed_weight/turn_point) + abs(W0_guess);
    elseif(1 - empty_weight_fraction - fuel_fraction < turn_point)
        res = abs(W0_guess - fixed_weight/turn_point);
    else
        res = abs(W0_guess - W0_new);
    end
end

%% Final Output
W_load = W_loading_turnrate()
S = W0/W_TO_O_S; % Final surface area

fprintf("\nW0 = %.3f kN (%.0f lb), S = %.4f, Wingspan = %.3f", W0/1000, N2lb(W0), S, sqrt(S*AR));