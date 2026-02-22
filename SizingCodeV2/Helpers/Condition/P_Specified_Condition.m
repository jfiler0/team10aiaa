function cond = P_Specified_Condition(perf, EP, h, M, W)

    % EP -> array of target excess power for each flight condition

    % h, M, and W can be vectors but they must be the same length
    % Goal: Compute the required throttle and CL to fly at the given flight conditions
    % Use the generateCondition function to prefill a cond struct. We will then edit the CL and throttle from there

    perf.model.clear_mem(); perf.clear_data();

    one_vec = ones(size(h));
    cond = generateCondition(perf.model.geom, h, M, one_vec, W, one_vec);
   
    perf.model.cond = cond;
    drag = perf.Drag;
    
    ab_max_thrust = perf.TA; % When T = 1
    perf.model.cond = addCondThrottle(perf.model.cond, 0.9 * one_vec);
    mil_max_thrust = perf.TA; % When T = 0.9

    % EP = (T - D) * v / g

    cant_level = (ab_max_thrust - drag) .* perf.model.cond.vel.v / perf.model.settings.g_const - EP < 0;
    mil_power = (mil_max_thrust - drag) .* perf.model.cond.vel.v / perf.model.settings.g_const - EP > 0;
    ab_on = ~cant_level & ~mil_power;

    throttle = one_vec;

    throttle_mil_power = 0.9 * drag ./ mil_max_thrust;
    throttle(mil_power) = throttle_mil_power(mil_power);
    
    throttle_ab_on = 0.9 + 0.1 * (drag - mil_max_thrust) ./ (ab_max_thrust - mil_max_thrust);
    throttle(ab_on) = throttle_ab_on(ab_on);

    cond = addCondThrottle(perf.model.cond, throttle);

    perf.model.cond = cond;
    perf.model.clear_mem(); perf.clear_data();
end