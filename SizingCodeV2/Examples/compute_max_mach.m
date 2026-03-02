function [h_opt, M_opt] = compute_max_mach(perf, W)
    % Compute maximum Mach number and corresponding altitude for a given weight
    
    % Initial guess
    x0 = [1000, 0.5];  % [h, M]
    
    % Define objective function
    objective = @(x) obj(perf, x(1), x(2), W);
    
    % Optimize
    options = optimset('Display', 'off');
    x_opt = fminsearch(objective, x0, options);
    
    h_opt = x_opt(1);
    M_opt = x_opt(2);
end

function out = obj(perf, h, M, W)
    perf.model.cond = levelFlightCondition(perf, h, M, W);

    R = 100;
    out = 1 / perf.model.cond.M.v + R * max( -perf.ExcessPower, 0) / 100;
end