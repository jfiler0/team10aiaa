function [q, V, a, rho] = metricFreestream(h, M)

    % h in m
    [temperature, ~, ~, rho, ~] = queryAtmosphere(h, [1 0 0 1 0]);
    a = sqrt(1.4*287.14*temperature);
    q = 0.5*rho*(M*a)^2; % Pa
    
    V = a * M;

end