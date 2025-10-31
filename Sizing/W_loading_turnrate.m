function W_load = W_loading_turnrate()
g = 32.2; %ft/s^2
[~,~,~,rho,~] = queryAtmosphere(ft2m(20000),[0 0 0 1 0]);
S_ref = 500;
[q, ~, ~, ~] = metricFreestream(ft2m(20000), 0.5); %get dynamic pressure at turn altitude and assume 
AC_wet_weight = 43900; %lbf, design from 
n = 7; % assuming max load factor to produce max turn rate
CLmax = n*AC_wet_weight/(q*S_ref); 
psidot_degs = 8; %deg/s, max turn rate requirement 
psidot_rads = psidot_degs*pi/180; 
W_load = 0.5*rho*CLmax*g^2 / (psidot_rads^2) * (n^2 - 1)/n

end
