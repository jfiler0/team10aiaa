function [v_land, glide_angle, throttle] = compute_landing_speed(perf, W)
    % Landing info

    % Define objective function
    objective = @(v) obj(perf, v, W);
    
    % Optimize
    options = optimset('Display', 'off');
    v_land = fminsearch(objective, 200, options);
    
    [~, glide_angle, throttle] = obj(perf, v_land, W);
end

% function [out, glide_angle, throttle] = obj(perf, v, W)
% 
%     landing_descent_rate = ft2m(20); % 20ft/s descent rate max
%     alpha = 8; % 8 degree AOA limit
%     CL_max = 1.8; % once we have flaps
% 
%     perf.model.cond = P_Specified_Condition(perf, -landing_descent_rate, 0, v, W);
% 
%     glide_angle = asind(landing_descent_rate/v);
% 
%     n = 1 / cosd(alpha - glide_angle);
% 
%     Max_Lift = CL_max * perf.model.geom.ref_area.v * perf.model.cond.qinf.v;
% 
%     lift_const = 1 - Max_Lift * n / perf.model.cond.W.v
% 
%     throttle = perf.model.cond.throttle.v;
% 
%     R = 100;
%     out = v / 100 + R * max( [ lift_const, throttle / 1 - 1, 0 ] );
% end

function [out, glide_angle, throttle] = obj(perf, v, W)
    landing_descent_rate = ft2m(20); % 20ft/s descent rate max
    aoa_limit = 8; % 8 degree AOA limit

    cond = P_Specified_Condition(perf, -landing_descent_rate, 0, v, W);
    perf.model.cond = cond;

    glide_angle = asind(landing_descent_rate/v);

    flap_inc = 1.6;

    alpha = fzero(@(alpha) cond.W.v/cosd(alpha - glide_angle) - flap_inc * perf.model.CLa * alpha * cond.qinf.v * perf.model.geom.ref_area.v, aoa_limit );

    n = 1 / cosd(alpha - glide_angle);
    throttle = cond.throttle.v;

    R = 100;
    out = v / 100 + R * max([alpha/aoa_limit - 1, cond.throttle.v / 1 - 1, 0]);
end