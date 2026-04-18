function cond = P_Specified_Condition(perf, EP, h, MV, W, MV_decleration)
    arguments
        perf 
        EP 
        h 
        MV 
        W 
        MV_decleration = perf.model.settings.codes.MV_DEC_UNKOWN
    end

    % EP -> array of target excess power for each flight condition

    % h, M, and W can be vectors but they must be the same length
    % Goal: Compute the required throttle and CL to fly at the given flight conditions
    % Use the generateCondition function to prefill a cond struct. We will then edit the CL and throttle from there

    perf.model.clear_mem(); perf.clear_data();

    one_vec = ones([1 , max([length(EP), length(h), length(MV), length(W)])]);
    if ~isstruct(perf.model.cond)
        perf.model.cond = buildDefaultCondStruct();
    end
    perf.model.cond = generateCondition(perf.model.geom, h(:)', MV(:)', one_vec(:)', W(:)', one_vec(:)', perf.model.cond, MV_decleration); % make sure everything is forced to row vector with (:)'
    EP = EP(:)'; % also needs to be a row vector
   
    drag = perf.Drag;

    % EP = (T - D) * v / W
    thrust_req = EP .* perf.model.cond.W.v ./ perf.model.cond.vel.v + drag;
   
    ab_max_thrust = perf.TA; % When T = 1

    perf.model.clear_mem(); perf.clear_data();
    perf.model.cond = addCondThrottle(perf.model.cond, 0.9 * one_vec);
    mil_max_thrust = perf.TA; % When T = 0.9

    cant_level = (ab_max_thrust - thrust_req) .* perf.model.cond.vel.v / perf.model.settings.g_const - EP < 0;
    mil_power = (mil_max_thrust - thrust_req) .* perf.model.cond.vel.v / perf.model.settings.g_const - EP > 0;
    ab_on = ~cant_level & ~mil_power; % ab_on = ~cant_level & ~mil_power;

    throttle = one_vec; % note this means all cant_level is set to 1

    throttle_mil_power = 0.9 * thrust_req ./ mil_max_thrust;
    throttle(mil_power) = throttle_mil_power(mil_power);
    
    throttle_ab_on = 0.9 + 0.1 * (thrust_req - mil_max_thrust) ./ (ab_max_thrust - mil_max_thrust);
    throttle(ab_on) = throttle_ab_on(ab_on);

    cond = addCondThrottle(perf.model.cond, throttle);
    perf.model.cond = cond;

    perf.model.clear_mem(); perf.clear_data();
end