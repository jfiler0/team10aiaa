%% Formatting
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
% build_atmosphere_lookup(0, 50000, 1000)

%% Notes

% Mising good queryTSFC, engineLookup fuctions
% Current script does not actually find the optimal cruise and endurance points
% No corrections to TSFC right now for afterburner

%% Start with a single call and can make optimization later

% These can be varyed to optimze (especially if we can get correllations for weight + cost)
AR = 4;
e = 0.85;
W_TO_O_S = constraintAnalysis(false); % Wing loading [N/m2] from constrain analyisis

% Removing S so it is calculated in the loop
plane = make_aircraft("F16", AR, e, lb2N(2000), lb2N(14000), "F404");

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

Cd0_dirty = 0.026996; % Carrying payload
Cd0_clean = 0.016996; % No external stores

% Note TSFC, alphas are now computed inside as functions of throtte, h, and M

%% Create missions

% % Ferry mission
% mission = [...
%     flightSegment("TAKEOFF") 
%     flightSegment("CLIMB", 0.7) 
%     flightSegment("CRUISE", 0.6, NaN, Cd0_dirty, nm2m(1000)) % 800 nm flight
%     flightSegment("LOITER", NaN, 10000, Cd0_dirty, 20) % 20 min loiter
%     flightSegment("COMBAT", 0.8, 1000, Cd0_clean, [8 plane.W_P]) % 8 minutes of combat, deploy payload
%     flightSegment("CRUISE", 0.6, NaN, Cd0_dirty, nm2m(1000)) % 800 nm flight
%     flightSegment("LANDING") ];

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

mission = air2ground;

% Initial guess
W0_init = 1e7;  
debug = false;   % or false to silence

% Call fsolve (requires Optimization Toolbox)
if(debug)
    options = optimset('Display','iter','TolFun',1e-3,'TolX',1e-3, 'Display','on');
else
    options = optimset('Display','iter','TolFun',1e-3,'TolX',1e-3, 'Display','off');
end

% W0_solution = fsolve(@(W0) W0_residual(W0, mission, plane, W_TO_O_S, debug), W0_init, options);

% res = W0_residual(W0_init, mission, plane, W_TO_O_S, true)

function res = W0_residual(W0_guess, mission, plane, W_TO_O_S, debug)
    if W0_guess <= 0
        res = 1e6;
        return
    end

    plane.S = W0_guess / W_TO_O_S;
    Wj = W0_guess;
    fb_sum = 0;
    for j = 1:length(mission)
        [Wj, WF, fb] = mission(j).queryWF(Wj, plane);
        fb_sum = fb_sum + fb;
        
        if debug
            fprintf("DEBUG: seg=%s, Wj=%.2f, fb=%.4f\n", mission(j).type, Wj, fb);
        end
    end

    fb_sum = fb_sum/0.95; % 5% fuel saving

    if Wj < 0
        res = 1e6 + abs(Wj);
        return
    end

    fixed_weight = plane.W_F + plane.W_P;
    % empty_weight_fraction = 0.4;
    empty_weight_fraction = 2.34*N2lb(W0_guess)^(-0.13) ; % Use historical data

    fuel_fraction = fb_sum / W0_guess;

    W0_new = fixed_weight / (1 - empty_weight_fraction - fuel_fraction);


    % Try to stop it from going negtive and taking too large a step
    if(W0_new > 2*W0_guess)
        W0_new = 2*W0_guess;
    elseif(W0_new < 0.5*W0_guess)
        W0_new = 0.5*W0_guess;
    end

    res = abs(W0_new - W0_guess);

    W0_new

    if debug
        fprintf("DEBUG: W0_guess=%.2f, W0_new=%.2f, res=%.4f\n", W0_guess, W0_new, res);
    end
end

% S = W0_solution/W_TO_O_S;
% fprintf("\nW0 = %.4f kN (%.3f lb), S = %.4f, Wingspan = %.3f", W0_solution/1000, N2lb(W0_solution), S, sqrt(S*AR));