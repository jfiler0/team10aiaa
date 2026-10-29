matlabSetup();
clear getSetting queryAtmosphere

naca2412 = foil_class("NACA2412", 0.75, false); %Setting the last flag to  true will regenerate the foil
% naca2412.characterizeFoil(70, 50, 5) % Option foil plotting

build_atmosphere_lookup(-100, 20000, 200)

hornet = plane_class("F18E");
% alpha0 = 0;
% flap0 = 0;
% perturb = 0.025;
% perturb = 10;
% hornet.characterizePlane(100, -0.0421875, -2.54781, [0], 1, 5); % vary flaps
% hornet.characterizePlane(100, -0.06, -2.54781, [0], 1, 5); % vary flaps
hornet.characterizePlane(100, linspace(alpha0 - perturb, alpha0 + perturb, 250), linspace(flap0 - perturb, flap0 + perturb, 200), [0 5000 10000], 1, 5); % vary flaps

% Inputs:
%   Vmag       - fixed airspeed magnitude [m/s]
%   alphas     - vector of alphas to look at
%   nDelta     - vector of deltas to look at
%   hVals      - vector of altitudes [m] to sweep
%   surfaceIdx - index of control surface to vary (1=flaps, 2=aileron, 3=rudder, 4=elevator)
%   F or M output - [F(1) F(2) F(3) M(1) M(2) M(3)]

V = [100 0 -4];
W = [0 0 0];
h = 1000;

%% Point Calc

% flaps = 0;
% aileron = 20;
% rudder = 0;
% elevator = 2.51;
% 
% deflections = [flaps aileron rudder elevator];
% 
% [F, M] = hornet.queryPlane(V, W, h, deflections, false);
% 
% AOA = rad2deg(atan2(V(3), V(1)));
% 
% Y = [0 F(2) 0]; % Side force
% D = proj(F-Y, -V); % Drag
% L = F - Y - D; % Lift
% 
% fprintf("At an AOA of %.3f [deg], L = %.4f [kN], D = %.4f [kN], Y = %.4f [kN], and L/D = %.4f", AOA, norm(L)/1000,norm(D)/1000,norm(Y)/1000, norm(L)/norm(D))
%% Trim

% deflections = trimAircraft(obj, V, W, h, an, n, M0)
% an = [0 0 -1];
% F0 = hornet.W0*an/norm(an);
% [deflections, alpha, beta] = hornet.trimAircraft(norm(V), W, h, F0, [0 0 0], true);
% 
% [F, M] = hornet.queryPlane(V, W, h, deflections, false);
% 
% AOA = rad2deg(atan2(V(3), V(1)));
% 
% Y = [0 F(2) 0]; % Side force
% D = proj(F-Y, -V); % Drag
% L = F - Y - D; % Lift
% 
% fprintf("At an AOA of %.3f [deg], L = %.4f [kN], D = %.4f [kN], Y = %.4f [kN], and L/D = %.4f", AOA, norm(L)/1000,norm(D)/1000,norm(Y)/1000, norm(L)/norm(D))

% 
%% Plot

% Setup
% hornet = plane_class("F18E");
% 
% Vmag = 100;       % m/s total velocity magnitude
% W = [0 0 0];
% h = 1000;         % altitude [m]
% 
% % Sweep ranges
% alpha_range = deg2rad(-5:1:20);      % radians AOA sweep
% flap_range  = -20:2:20;              % degrees elevator sweep
% 
% % Allocate results
% M_plot = zeros(length(alpha_range), length(flap_range));
% 
% % Loop over conditions
% for ia = 1:length(alpha_range)
%     alpha = alpha_range(ia);
% 
%     % Build velocity vector (x forward, z down in body coords)
%     V = [Vmag*cos(alpha), 0, Vmag*sin(alpha)];
% 
%     for ie = 1:length(flap_range)
%         % elevator = flap_range(ie);
% 
%         % Other controls fixed
%         flaps = 0; aileron = 0; rudder = 0; elevator = 0;
% 
%         flaps = flap_range(ie);
% 
%         deflections = [flaps, aileron, rudder, elevator];
% 
%         % Query aircraft
%         [F, M] = hornet.queryPlane(V, W, h, deflections, false);
% 
%         % Store pitching moment (about body-Y)
%         M_plot(ia, ie) = M(2);
%     end
% end
% 
% [AlphaGrid, ElevGrid] = meshgrid(rad2deg(alpha_range), flap_range);
% 
% figure; 
% surf(AlphaGrid, ElevGrid, M_plot')
% xlabel('$\alpha$ [deg]'); ylabel('Elevator [deg]'); zlabel('$M_y$ [Nm]', 'Interpreter','latex')
% title('Pitching Moment vs AOA and Elevator Deflection')
% shading interp; colorbar; hold on
% 
% % Add zero-moment contour (M_y = 0)
% contour3(AlphaGrid, ElevGrid, M_plot', [0 0], 'k-', 'LineWidth', 2)
% legend('Pitch Moment Surface', '$M_y$ = 0 Trim Line')

%% Helpers

function R = proj(A, B)
    % Projection of A onto B
    R = (dot(A, B) / norm(B)^2) * B;
end