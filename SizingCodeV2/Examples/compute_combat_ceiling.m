function [h_opt, M_opt] = compute_combat_ceiling(perf, W)
    % Compute maximum Mach number and corresponding altitude for a given weight
    % targeting an excess power of 500 fpm while maximizing h
    
    % Initial guess
    x0 = [10000, 1.2];  % [h, M]
    
    % Define objective function
    objective = @(x) obj(perf, x(1), x(2), W);
    
    % Optimize
    options = optimset('Display', 'off');
    x_opt = fminsearch(objective, x0, options);
    
    h_opt = x_opt(1);
    M_opt = x_opt(2);
end

function out = obj(perf, h, M, W)
    perf.model.cond = levelFlightCondition(perf, h, M, W, perf.model.settings.codes.MV_DEC_MACH);

    R = 100;
    out = 1 / h + R * max( 500 - 60*m2ft(perf.ExcessPower), 0);
end