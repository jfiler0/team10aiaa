function optimal_WS = constraintAnalysis(do_plot)


%% Setup

WS_range = [2000 1E4];
Wto_S_range = linspace(WS_range(1), WS_range(end), 1000);

% Note available conversions
%   ft2m -> feet to meters
%   nm2m -> nautical miles to meters
%   lb2N -> pound force to newtons
%   N2lb -> newtons to pound force

%% Max Mach

h = ft2m(36000);
M = 1.6;

[q, ~, ~] = metricFreestream(h, M);
alpha_MaxMach = find_lapse_rate(h, M, 1);
% alpha_MaxMach = find_lapse_rate_og(0.298293, 0.57698, 1);

Cd0 = 0.039317;
K1 = 0.213727;
beta = 0.899666;

A = q*Cd0/alpha_MaxMach;
B = q.*K1.*(beta./q).^2 / alpha_MaxMach;

TW_MaxMach = A ./ Wto_S_range + B .* Wto_S_range;

%% Cruise

h = ft2m(36000);
M = 0.87;

[q, ~, ~] = metricFreestream(h, M);

Cd0 = 0.016996;
alpha_Cruise = find_lapse_rate(h, M, 0);
% alpha_Cruise = find_lapse_rate_og(0.27111, 1, 0);

beta = 0.899666;
K1 = 0.116031;

A = q*Cd0/alpha_Cruise;
B = q*K1*(beta/q)^2 / alpha_Cruise;

TW_Cruise = A ./ Wto_S_range + B * Wto_S_range;

%% Max Altitude

Cd0 = 0.016996;
K1 = 0.116031;
K2 = -0.0063;
beta = 0.899666;

h = ft2m(50000);
M = 0.87;

[q, ~, ~] = metricFreestream(h, M);

alpha_MaxAlt = find_lapse_rate(h, M, 1);
% alpha_MaxAlt = find_lapse_rate_og(0.138789, 0.17029, 1);

A = q*Cd0/alpha_MaxAlt;
B = q.*K1.*(beta./q).^2 / alpha_MaxAlt;
C = K2*beta/alpha_MaxAlt;

TW_MaxAlt = A ./ Wto_S_range + B .* Wto_S_range + C;

%% Turn 1

h = ft2m(20000);
M = 0.87;

[q, ~, ~] = metricFreestream(h, M);
alpha_CmbtTrn1 = find_lapse_rate(h, M, 1);
% alpha_CmbtTrn1 = find_lapse_rate_og(0.555662, 0.681777, 1);

Cd0 = 0.016996;
K1 = 0.116031;
K2 = -0.0063;
beta = 0.899666;
n = 4.5; % 4.5g turn

TW_CmbtTrn1 = (beta/alpha_CmbtTrn1)*(K1 * n^2 * (beta/q) * Wto_S_range + K2*n + Cd0./( (beta/q)*Wto_S_range ) );

%% Turn 2

h = ft2m(36000);
M = 1.4;

[q, ~, ~] = metricFreestream(h, M);

alpha_CmbtTrn2 = find_lapse_rate(h, M, 1);
% alpha_CmbtTrn2 = find_lapse_rate_og(0.357862, 0.556558, 1);

Cd0 = 0.040614;
K1 = 0.219406;
K2 = -0.001;
beta = 0.899666;
n = 1.4; % 4.5g turn

TW_CmbtTrn2 = (beta/alpha_CmbtTrn2)*(K1 * n^2 * (beta/q) * Wto_S_range + K2*n + Cd0./( (beta/q)*Wto_S_range ) );

%% Excess Power
h = ft2m(10000);
M = 0.87;

[q, V, ~] = metricFreestream(h, M);

alpha_Ps = find_lapse_rate(0.702727, 0.85355, 1);
% alpha_Ps = find_lapse_rate_og(0.702727, 0.85355, 1);

Cd0 = 0.016996;
K1 = 0.116031;
K2 = -0.0063;
beta = 0.899666;
n = 1;

climb_rate = ft2m(500); %m/s

TW_Ps = (beta/alpha_Ps)*( K1 * (beta/q) * Wto_S_range + K2 + Cd0./( (beta/q)*Wto_S_range ) + climb_rate/V );

%% Takeoff

h = ft2m(0);

[~, ~, ~, rho] = metricFreestream(h, 0);

g = 9.805; % m/s

k_takeoff = 1.2;
beta = 1;
alpha = find_lapse_rate(h, M, 1);
% alpha = 0.939778; %NEEDS TO BE FIXED

cl_max = 1.275665;
s_t = ft2m(4000); % m
Cd0 = 0.051996;
mu = 0.03;

TW_Takeoff = k_takeoff^2 * beta^2 * Wto_S_range / (alpha * rho * cl_max*g*s_t) + 0.7 *Cd0 / (beta * cl_max) + mu;

%% Landing Constraint
s_l = s_t; % m

mu = 0.5;
cl_max = 1.425909;
Cd0 = 0.061996;
k_land = 1.3;
beta = 1; % Fraction of W_current / W_TO

WS_Landing = s_l*rho*g*(mu*cl_max + 0.83*Cd0) / (k_land.^2 * beta);

%% Find Optimum

T_Wto_required = max([TW_MaxMach ; TW_MaxAlt ; TW_Ps ; TW_Ps ; TW_CmbtTrn1 ; TW_CmbtTrn2 ; TW_Takeoff] );
[min_TW, min_idx] = min(T_Wto_required);
optimal_WS = Wto_S_range(min_idx);

fprintf("Min TW: %.4f , Optimal WS: %.4f", min_TW, optimal_WS)

function alpha = find_lapse_rate_og(alpha_dry, alpha_ab, AB_frac)
    T_max = 23770;
    T_min = 15000;
    alpha = ( T_min*alpha_dry + AB_frac*( alpha_ab*T_max - alpha_dry*T_min ) )/T_max;
end

%% Plotting
if(do_plot)
    figure;
    hold on;
    
    plot(Wto_S_range, TW_MaxMach, DisplayName="Max Mach");
    plot(Wto_S_range, TW_MaxAlt, DisplayName="Max Alt");
    plot(Wto_S_range, TW_Ps, DisplayName="Excess Power");
    plot(Wto_S_range, TW_CmbtTrn1, DisplayName="Turn 1");
    plot(Wto_S_range, TW_CmbtTrn2, DisplayName="Turn 2");
    plot(Wto_S_range, TW_Takeoff, DisplayName="Takeoff");
    plot(optimal_WS, min_TW, 'b.', DisplayName="Optimum", MarkerSize=25);
    xline(WS_Landing, DisplayName="Landing", LineWidth=2);
    
    legend;
    xlabel("$\frac{W_{TO}}{S}$, Wing Loading, [$\frac{N}{m^2}$]")
    ylabel("$\frac{T}{W_{TO}}$, Thrust to Weight")
end

end