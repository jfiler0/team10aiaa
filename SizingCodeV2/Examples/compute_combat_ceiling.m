function [h_opt, M_opt] = compute_combat_ceiling(perf, W, climb_rate_ms)

    if nargin < 3
        climb_rate_ms = ft2m(500)/60; % 500 fpm to ms
    end

    % Compute maximum Mach number and corresponding altitude for a given weight
    % targeting an excess power of 500 fpm while maximizing h
    
    % Initial guess
    x0 = [ft2m(60000), 0.6];  % [h, M]
    
    % Define objective function
    objective = @(x) obj(perf, x(1), x(2), W, climb_rate_ms);
    
    % Optimize
    options = optimset('Display', 'off');
    x_opt = fminsearch(objective, x0, options);
    
    h_opt = x_opt(1);
    M_opt = x_opt(2);
end

function out = obj(perf, h, M, W, climb_rate_ms)
    perf.clear_data();
    perf.model.cond = levelFlightCondition(perf, h, M, W, perf.model.settings.codes.MV_DEC_MACH);

    R = 100;
    out = 1 / h + R * max( climb_rate_ms - perf.ExcessPower, 0);
end