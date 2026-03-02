function M_opt = compute_max_mach_at_h(perf, W, h)
    % Compute maximum Mach number and corresponding altitude for a given weight
    
    % Define objective function
    objective = @(M) obj(perf, h, M, W);
    
    % Optimize
    options = optimset('Display', 'off');
    M_opt = fminsearch(objective, 0.5, options);
end

function out = obj(perf, h, M, W)
    perf.model.cond = levelFlightCondition(perf, h, M, W);

    R = 100;
    out = 1 / perf.model.cond.M.v + R * max( -perf.ExcessPower, 0) / 100;
end