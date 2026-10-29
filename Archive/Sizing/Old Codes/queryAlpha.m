function alpha = queryAlpha(h, M)
    % altitude [m]
    % mach -> to free stream

    [~, ~, ~, rho, ~] = queryAtmosphere(h, [0 0 0 1 0]);

    alpha = rho/1.225;

end