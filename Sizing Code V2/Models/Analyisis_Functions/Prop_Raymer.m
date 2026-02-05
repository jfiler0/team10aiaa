function out = Prop_Raymer(in)
% Prop model needs to output: [TA, TSFC, alpha]

    %% Engine Regression Function
    % Version 2.1.0, 11/30/25
    % Kevin Xu - Virginia Tech AOE 4065 - Team 10 AIAA Naval Strike Fighter
    
    % Parameters
    T_SL  = 288.15; %deg K
    P_SL = 101330; % Pa
    gamma = 1.4; 
    TR = 1; % Note: Throttle Ratio ~1 for Fighter Aircraft (Sarojini + Mattingly)
    
    % Static and stagnation correction ratios
    theta = in.condition.T/T_SL; delta = in.condition.P/P_SL; 
    
    theta_0 = theta * (1 + (gamma-1)/2 * in.condition.M^2);
    delta_0 = delta * (1 + (gamma-1)/2 * in.condition.M^2)^(gamma/(gamma-1));
    
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
    F_th_mil = in.geometry.prop.T0_NoAB.v * alpha_dry; % (whatever unit thrust was passed with)
    F_th_AB = in.geometry.prop.T0_AB.v * alpha_AB; % (whatever unit thrust was passed with)
    
    TSFC_mil = (0.9 + 0.30 * in.condition.M) * sqrt(theta); %hour^-1; Mattingly Eq.3.55a (No, these are lbm/lbf*hr)
    TSFC_AB = (1.6 + 0.27 * in.condition.M) * sqrt(theta); %hour^-1; Mattingly Eq.3.55b (No, these are lbm/lbf*hr)
    
    TA = F_th_mil + in.condition.AB * ( F_th_AB - F_th_mil );
    
    TSFC = TSFC_mil + in.condition.AB * ( TSFC_AB - TSFC_mil );
    TSFC = lbmlbfhr_2_kgNs(TSFC); % Since the regression was not in metric units

    % Added in the max check and zeroing since it got weird for high mach at sea level
    alpha = max(alpha_dry + in.condition.AB * (alpha_AB - alpha_dry), 0);
    if(alpha < 0)
        TA = 0;
    end

    out = [TA, TSFC, alpha];

end