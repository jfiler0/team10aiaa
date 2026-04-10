function [max_range, h_opt, M_opt, v_opt]  = estimate_max_range(perf, W)
    % Compute maximum Mach number and corresponding altitude for a given weight
    
    % Initial guess
    x0 = [10000, 1];  % [h, M]

    W_start = W - 0.05; W_end = 0.05;
    W_mid = 0.5*(W_start + W_end);
    
    % Define objective function
    objective = @(x) obj(perf, x(1), x(2), W_mid);
    
    % Optimize
    options = optimset('Display', 'off');
    x_opt = fminsearch(objective, x0, options);
    h_opt = x_opt(1);
    M_opt = x_opt(2);

    perf.model.cond = levelFlightCondition(perf, h_opt, M_opt, W_mid);
    v_opt = perf.model.cond.vel.v;

    % perf.model.settings.g_const -> 1/(TSFC * g0) converts to ISP
    max_range = perf.LD * perf.model.cond.vel.v * log( weightRatio(W_start, perf.model.geom)/weightRatio(W_end, perf.model.geom) ) / ( perf.model.settings.g_const * perf.TSFC );
end

function out = obj(perf, h, M, W)
    perf.model.cond = levelFlightCondition(perf, h, M, W);

    % range_term = perf.LD * perf.model.cond.vel.v / perf.TSFC;
    range_term = perf.model.cond.vel.v / perf.mdotf;

    alt_const = -h/100; % dont go below sea level

    R = 100;
    out = 1/range_term + R * max( [-perf.ExcessPower/100, alt_const, 0] );
end