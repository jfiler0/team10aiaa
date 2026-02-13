function cond = generateCondition(geom, h, M_vel, CL, W, throttle)
    % specify either altitude and mach or altitude and velocity (tells which it is from magnitude)

    % THROTTLE - There is both AB throttle and normal throttle. 
    %   Max military power when throttle = 0.9
    %   Full AB is throttle = 1

    % Any of these can be passed in as vectors, but their lengths MUST be the same or uncaught errors will be thrown
    % Each index will count as a case

    % Keeping things as .v so that units / names can be added later if needed

    cond = struct();

    cond.h.v = h;
    [cond.T.v, cond.a.v, cond.P.v, cond.rho.v, cond.mu.v] = queryAtmosphere(h, [1 1 1 1 1]);

    % using max and min helps ensure proper behavior when using a vector
    if(max(M_vel) > 5) % pretty much no plane is going under 5 m/s but this can be made more robust if it becomes an issu
        cond.M.v = M_vel ./ cond.a.v;
        cond.vel.v = M_vel;
    elseif( min(M_vel) < 0)
        error("Condition 'M_vel' cannot have a negative value: %.4f", M_vel)
    else
        % M_vel is entirely above between 0 and 5 -> Mach number designation
        cond.M.v = M_vel;
        cond.vel.v = M_vel .* cond.a.v;
    end

    cond.CL.v = CL;
    cond.mil_throttle.v = min(throttle, 0.9)/0.9; % Goes from 0-1 from output between throttle=0-0.9
    cond.ab_throttle.v = (max(throttle, 0.9) - 0.9)/0.1; % Stays 0 unitl throttle = 0.9 and grows to 1between 0.9-1

    cond.qinf.v = 0.5 * cond.rho.v .* cond.vel.v .* cond.vel.v;

    cond.Lift.v = geom.ref_area.v * cond.qinf.v .* cond.CL.v;

    if( min(W) > 1)
        % Weight was passed in normally
        cond.W.v = W;
    elseif( min(W) < 0)
        % Weight has become negative -> throw an error
        error("Weight has become negative during condition generation.")
    elseif(max(W) > 1)
        error("Cannot have a mixed weight vector of 0-1 and above 1.")
    else
        % The user wants a linear scale between WE and MTOW
        cond.W.v = weightRatio(W, geom);
    end
end