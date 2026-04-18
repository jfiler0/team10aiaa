function [M_opt, turn_rate] = compute_max_sustained_turn_at_h(perf, W, h)
    % Compute maximum Mach number and corresponding altitude for a given weight
    
    % Define objective function
    objective = @(M) obj(perf, h, M, W);
    
    % Optimize
    options = optimset('Display', 'off');
    M_opt = fminsearch(objective, 0.4, options);
    [~, turn_rate] = obj(perf, h, M_opt, W);
end

function [out, turn_rate] = obj(perf, h, M, W)
    perf.model.cond = Max_N_Condition(perf, h, M, W);

    R = 100;
    turn_rate = perf.TurnRate;
    out = 1 / turn_rate + R * max( -perf.ExcessPower, 0) / 100;
end