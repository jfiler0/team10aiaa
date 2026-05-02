function M_opt = compute_max_mach_at_h(perf, W, h, T_max)
    if(nargin < 4)
        T_max = 1; % throttle limit
    end
    % Compute maximum Mach number and corresponding altitude for a given weight
    
    % Define objective function
    objective = @(M) obj(perf, h, M, W, T_max);
    
    % Optimize
    options = optimset('Display', 'off');
    M_opt = fminsearch(objective, 1.2, options);
end

function out = obj(perf, h, M, W, T_max)
    perf.model.cond = levelFlightCondition(perf, h, M, W, perf.model.settings.codes.MV_DEC_MACH);

    R = 100;
    out = 1 / perf.model.cond.M.v + R * max( [-perf.ExcessPower, 0, 100*(perf.model.cond.throttle.v/T_max - 1)] ) / 100;
end