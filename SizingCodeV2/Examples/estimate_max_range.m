function max_range = estimate_max_range(perf, W)
    max_range = 0;

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

    perf.model.cond = levelFlightCondition(perf, h_opt, M_opt, W);

    max_range = perf.LD * (perf.model.cond.vel.v / perf.model.settings.g_const) * (1/perf.TSFC) * log (perf.model.cond.W.v / perf.model.geom.weights.empty.v);
end

function out = obj(perf, h, M, W)
    perf.model.cond = levelFlightCondition(perf, h, M, W);

    range_term = perf.LD * perf.model.cond.vel.v /perf.TSFC;

    alt_const = -h/100; % dont go below sea level

    R = 100;
    out = 1/range_term + R * max( [-perf.ExcessPower, alt_const, 0] ) / 100;
end