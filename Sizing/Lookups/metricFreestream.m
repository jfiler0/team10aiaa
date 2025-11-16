function [q, V, a, rho] = metricFreestream(h, M)
    % q - Pa - Dynamic Pressure
    % v - m/s - Free Stream Velocity
    % a - m/s - Speed of Sound
    % rho - kg/m3 - Free Stream Density

    % Quick little wrapper for queryAtmoshere to easily get other typcical values needed for aero calc

    % h in m
    [temperature, ~, ~, rho, ~] = queryAtmosphere(h, [1 0 0 1 0]);
    a = sqrt(1.4*287.14*temperature);
    q = 0.5*rho*(M*a)^2; % Pa
    
    V = a * M;

end