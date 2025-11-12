function W_load = W_loading_turnrate()
g = 32.2; %ft/s^2
gamma = 1.4;
R = 287; %J/kgK

alt = linspace(0,50000); %ft
v = linspace(77,617); %Landing approach speed to max speed in m/s
[T,~,~,rho,~] = queryAtmosphere(ft2m(alt),[1 0 0 1 0]);
S_ref = 500;

MachVec = v./sqrt(gamma.*R.*T);
q = zeros(1,100);
for i = 1:100

    [dynpress, ~, ~, ~] = metricFreestream(ft2m(alt(i)), MachVec(i)); %get dynamic pressure at turn altitude and assume 
    q(i) = dynpress;
end

[Dyn,Dens] = meshgrid(q,rho);

weight = lb2N(46000); %lbf, design from 
n = 7; % assuming max load factor to produce max turn rate
%CLmax = n*weight/(q*S_ref); 
psidot_degs = 8; %deg/s, max turn rate requirement 
psidot_rads = psidot_degs*pi/180; 
W_load = 0.5.*Dens.* (n.*weight./(Dyn.*S_ref)) .*g^2 ./ (psidot_rads^2) .* (n^2 - 1)/n;

figure;
surf(Dyn,Dens,W_load);
colorbar;

% handle = gca;
% handle.XTick = 0:1:100;
% handle.XTickLabel = string()
xlabel('Dynamic Pressure');
ylabel('Density');
zlabel('Wing Loading');
title('Wing Loading Required for Max Turn Rate at Max Load Factor vs. Altitude and Mach No.');

end
