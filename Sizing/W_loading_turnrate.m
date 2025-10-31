function W_load = W_loading_turnrate(aircraft)
g = 32.2; %ft/s^2
[~,~,~,rho,~] = queryAtmosphere(m2ft(20000),[0 0 0 1 0]);

psidot_degs = 8; %deg/s, max turn rate requirement 
psidot_rads = psidot_degs*pi/180; 
W_S_turnrate = 0.5*rho*aircraft.CL*g^2 / (psidot_rads^2) * (n^2 - 1)/n

end
