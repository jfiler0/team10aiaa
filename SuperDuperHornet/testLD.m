% e = 0.85;
% b = 13.62; % Wing span
% S = 39; % wing area in m2
% AR = b^2 / S;
% 
% W = 140000; % N - f18e weight
% M = linspace(0.15,1,200); % Cruise mach
% h = 1000; %alt in m
% 
% Cd0 = 0.08;
% 
% [~, a, ~, rho] = atmosisa(h);
% 
% V = a.*M;
% q = 0.5*rho.*V.^2;
% 
% Cl = W./(q*S);
% 
% Cd = Cl.^2 ./ (pi*e*AR) + Cd0;
% 
% LD = Cl./Cd;
% 
% plot(M, LD)

clear; clc;

mu = 1.7895E-5; %kg/ms
V = 178; %m/s

a = 343;
rho = 1.225;
M = V/a;

L = 3;

ReL = rho*V*L/mu;

h_bd = L*0.37 / ( ReL^(1/5) );

fprintf("Boundary Layer Height: %.5f mm , Mach = %.3f", h_bd*1000, M)