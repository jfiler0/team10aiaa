function [TA, TSFC, alpha] = max_prop_info(cond, T0_NoAB, T0_AB, settings)

% gives TA, TSFC, and alpha for military (first row) and max ab (second row)

T_SL  = 288.15; %deg K
P_SL = 101330; % Pa
gamma = 1.4; 
TR = 1; % Note: Throttle Ratio ~1 for Fighter Aircraft (Sarojini + Mattingly)

% Static and stagnation correction ratios
theta = cond.T.v/T_SL; delta = cond.P.v/P_SL; 

theta_0 = theta .* (1 + (gamma-1)/2 * cond.M.v.^2);
delta_0 = delta .* (1 + (gamma-1)/2 * cond.M.v.^2).^(gamma/(gamma-1));

% Lapse Ratios for Low-bypass Turbofans (See Mattingly, Aircraft Engine Design, 2e)
% Vectorized version using logical indexing - Thanks Claude

% This was needed as the best cruise appears to end up on this boundary and the kink is bad
blend_width = 0.15;  % tune this — wider = smoother but less faithful to Mattingly
t_blend = 1 ./ (1 + exp(-20/blend_width * (theta_0 - TR)));  % smooth 0->1 around TR

alpha_dry_low  = delta_0 * 0.6;
alpha_dry_high = 0.6 * delta_0 .* (1 - 3.8 * (theta_0 - TR) ./ theta_0);
alpha_dry      = (1 - t_blend) .* alpha_dry_low + t_blend .* alpha_dry_high;

alpha_AB_low   = delta_0 * 1.0;
alpha_AB_high  = delta_0 .* (1 - 3.5 * (theta_0 - TR) ./ theta_0);
alpha_AB       = (1 - t_blend) .* alpha_AB_low + t_blend .* alpha_AB_high;

% Thrusts (by definition of lapse rate)
F_th_mil = T0_NoAB * alpha_dry; % (whatever unit thrust was passed with)
F_th_AB = T0_AB * alpha_AB; % (whatever unit thrust was passed with)

TSFC_mil = (0.9 + 0.30 * cond.M.v) .* sqrt(theta); %hour^-1; Mattingly Eq.3.55a (No, these are lbm/lbf*hr)
TSFC_AB = settings.TSFC_AB_scaler * (1.6 + 0.27 * cond.M.v) .* sqrt(theta); %hour^-1; Mattingly Eq.3.55b (No, these are lbm/lbf*hr)

TA = [F_th_mil ; F_th_AB];
TSFC = [TSFC_mil ; TSFC_AB];
alpha = [alpha_dry ; alpha_AB];

TSFC = lbmlbfhr_2_kgNs(TSFC); % Since the regression was not in metric units

end