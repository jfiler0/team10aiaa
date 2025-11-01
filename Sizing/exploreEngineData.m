clear; clc;

engine = "F404";
AB_perc = 0;

% Resolution of Mach and altitude grids
N = 20;

% Define altitude (m) and Mach number ranges
hvec = linspace(100, ft2m(40000), N);  % Altitude from 100 m to 40,000 ft
Mvec = linspace(0.2, 2, N);            % Mach from 0.2 to 2.0

% Create meshgrid for evaluation
[M, h] = meshgrid(Mvec, hvec);

% Preallocate result matrices
TA    = zeros(size(M));
TSFC  = zeros(size(M));
alpha = zeros(size(M));
qinf = zeros(size(M));

% Query engine model for each point
for i = 1:numel(M)
    [TA(i), TSFC(i), alpha(i)] = engine_query(engine, M(i), h(i), AB_perc);
    [qinf(i)] = metricFreestream(h(i), M(i));
end

% ---- Plot Results ----
figure('Position',[100 100 1200 400])

% Thrust Available
subplot(2,2,1)
surf(M, m2ft(h), TA, 'EdgeColor', 'none')
xlabel('Mach Number')
ylabel('Altitude [ft]')
zlabel('Thrust Available [N]')
title('Thrust Available (TA)')
grid on; colorbar

% TSFC
subplot(2,2,2)
surf(M, m2ft(h), TSFC, 'EdgeColor', 'none')
xlabel('Mach Number')
ylabel('Altitude [ft]')
zlabel('TSFC [kg/N-s]')
title('Thrust Specific Fuel Consumption (TSFC)')
grid on; colorbar

% Alpha (mass flow parameter)
subplot(2,2,3)
surf(M, m2ft(h), alpha, 'EdgeColor', 'none')
xlabel('Mach Number')
ylabel('Altitude [ft]')
zlabel('\alpha')
title('Thrust Lapse (\alpha)')
grid on; colorbar

% Dynamic Pressure
subplot(2,2,4)
surf(M, m2ft(h), alpha, 'EdgeColor', 'none')
xlabel('Mach Number')
ylabel('Altitude [ft]')
zlabel('\q_inf')
title('Dyanamic Pressure (Pa)')
grid on; colorbar

sgtitle("Engine Performance Map - " + engine)
