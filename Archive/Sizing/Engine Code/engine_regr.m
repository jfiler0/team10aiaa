%% Engine Regression Function
% Version 1.1.0, 11/30/25
% Kevin Xu - Virginia Tech AOE 4065 - Team 10 AIAA Naval Strike Fighter

%-----------------------------------------------------------

% Note 1: This function takes in inputs and returns outputs in SI units; however, regressions
% WITHIN the function are based in Customary (FPS) units

% Note 2: F_th specifies total thrust of n engines. -> This is taken out into planeObj

% Note 3: TSFC is in units of inverse hours = Hz/3600.

% Note 4: Download Aerospace Toolbox. 

%-----------------------------------------------------------

% Inputs: Geometric Altitude [h_geom - ft], Freestream Mach [M_inf], Static
% Ground Thrust, military [F_static_mil - lbf], Static
% Ground Thrust, afterburner [F_static_AB - lbf], Number of Engines [n_engine]

% Outputs: Thrust [F_th - lbf], Thrust-Specific Fuel Consumption [TSFC - hour^-1] for military and afterburner thrust

%-----------------------------------------------------------

function [F_th_mil, TSFC_mil, F_th_AB, TSFC_AB] = engine_regr(h_geom, M_inf, F_static_mil, F_static_AB)

% Parameters
T_SL  = 518.69; %deg R
P_SL = 2118.6; %lbf/ft^2
gamma = 1.4; 
TR = 1; % Note: Throttle Ratio ~1 for Fighter Aircraft (Sarojini + Mattingly)

h_geom_SI = ft2m(h_geom); % meters
% [T_SI, a_SI, P_SI, rho_SI, ~ , ~] = atmosisa(h_geom_SI); % SI Temp (K), Sound Speed (m/s), Pressure (Pa), density (kg/m^3)
[T_SI, ~, P_SI, ~, ~] = queryAtmosphere(h_geom_SI, [1 0 1 0 0]); % Down with atmosisa

T = T_SI * 9 / 5; %deg R
% a = a_SI / 0.3048; %ft/s
P = P_SI * 0.0208854; %lbf/ft^2 
% rho = rho_SI * 0.00194032; %slug/ft^3

% Static and stagnation correction ratios
theta = T/T_SL; delta = P/P_SL; 

theta_0 = theta *(1 + (gamma-1)/2*M_inf^2);
delta_0 = delta*(1 + (gamma-1)/2*M_inf^2)^(gamma/(gamma-1));

% Lapse Ratios for Low-bypass Turbofans (See Mattingly, Aircraft Engine Design, 2e)
if theta_0 > TR
    alpha_dry = 0.6 * delta_0 * (1 - 3.8 * (theta_0 - TR) / theta_0); %Eqn. 2.45b
else
    alpha_dry = delta_0 * (0.6); %Eqn. 2.45b
end

if theta_0 > TR
    alpha_AB = delta_0 * (1 - 3.5* (theta_0 - TR) / theta_0); %Eqn. 2.45a
else
    alpha_AB = delta_0 * (1); % Eqn. 2.45a
end

% Thrusts (by definition of lapse rate)
F_th_mil = F_static_mil * alpha_dry; % (whatever unit thrust was passed with)
F_th_AB = F_static_AB * alpha_AB; % (whatever unit thrust was passed with)

TSFC_mil = (0.9 + 0.30 * M_inf) * sqrt(theta); %hour^-1; Mattingly Eq.3.55a (No, these are lbm/lbf*hr)
TSFC_AB = (1.6 + 0.27 * M_inf) * sqrt(theta); %hour^-1; Mattingly Eq.3.55b (No, these are lbm/lbf*hr)

end