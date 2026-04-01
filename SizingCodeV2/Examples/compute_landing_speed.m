% claude added some stability modifications. Nvm. fuck claude ill do this myself
function [v_land, glide_angle, throttle] = compute_landing_speed(perf, W)
    v0  = 50; % strting guess

    landing_descent_rate = ft2m(20);
    
    flap_inc    = 1.3;
    aoa_limit = 10;

    err = 1;
    tol = 1E-6;
    i_limit = 20; i = 0;

    v = v0;
    
    while err > tol
        i = i + 1;

        if(v < landing_descent_rate)
            warning("Landing velocity iteration is less than descent rate. That makes no sense. Exiting loop.")
            break;
        end
    
        cond = P_Specified_Condition(perf, -landing_descent_rate, 0, v, W, perf.model.settings.codes.MV_DEC_VEL);
        perf.model.cond = cond;

        CLa = perf.model.CLa * pi/180;
        % alpha = ( cond.W.v / cosd(glide_angle) ) / ( flap_inc * CLa * cond.qinf.v * perf.model.geom.ref_area.v );
        % alpha = ( cond.W.v / cosd(glide_angle) ) / ( flap_inc * CLa * 0.5 * cond.rho.v * cond.vel.v^2 * perf.model.geom.ref_area.v );

        glide_angle = asind(landing_descent_rate / v);
        v_next = sqrt( ( cond.W.v / cosd(glide_angle) ) / ( flap_inc * aoa_limit * CLa * 0.5 * cond.rho.v * perf.model.geom.ref_area.v ) );

        err = abs(v_next - v)/v;
        v = v_next;
    end

    if i == i_limit
        warning("Landing speed search hit iteration limit.")
    end

    v_land = v;
    throttle = cond.throttle.v;
end