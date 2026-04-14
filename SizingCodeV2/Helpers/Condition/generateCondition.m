function cond = generateCondition(geom, h, M_vel, n, W, throttle, sample_cond, MV_decleration)
    arguments
        geom 
        h 
        M_vel 
        n 
        W 
        throttle 
        sample_cond = struct(); % this still counts as empty
        MV_decleration = geom.settings.codes.MV_DEC_UNKOWN % standard is to check magnitude to decide what to do
    end
    
    % set of checks to pattern scalers to arrays
    lengths = [length(h) length(M_vel) length(n) length(W) length(throttle)];
    n_cond = max(lengths);

    if n_cond ~= min(lengths)% we need to do some checks or throw an error
        for i = 1:5
            if lengths(i) ~= n_cond % this is the right length
                if lengths(lengths(i) > 1) % it is not a scaler
                    error("Condition input at position %i is not a scaler and does not match the maximum input vector length.", i)
                end
                switch i
                    case 1
                        h = h * ones([1 n_cond]);
                    case 2
                        M_vel = M_vel * ones([1 n_cond]);
                    case 3
                        n = n * ones([1 n_cond]);
                    case 4
                        W = W * ones([1 n_cond]);
                    case 5
                        throttle = throttle * ones([1 n_cond]);
                end
            end
        end
    end
    
    % specify either altitude and mach or altitude and velocity (tells which it is from magnitude)

    % n -> load factor for Cl calculation. 1 is level flight.

    % THROTTLE - There is both AB throttle and normal throttle. 
    %   Max military power when throttle = 0.9
    %   Full AB is throttle = 1

    % Any of these can be passed in as vectors, but their lengths MUST be the same or uncaught errors will be thrown
    % Each index will count as a case

    % Keeping things as .v so that units / names can be added later if needed

    % buildDefaultCondStruct is pretty slow. It is faster to provide an existing struct copy and overwrite it
    if isempty(sample_cond) % trigger to build
        cond = buildDefaultCondStruct();
    else
        cond = sample_cond;
    end

    cond.h.v = h;

    % could have a check to make sure all lengths are the same, but relying on passive enforcement
    cond.Nc.v = length(cond.h.v); % easy number to check how long the condition array is and how models should be patterned

    [cond.T.v, cond.a.v, cond.P.v, cond.rho.v, cond.mu.v] = queryAtmosphere(h, [1 1 1 1 1]);

    if(min(M_vel) < 0)
        warning("Condition 'M_vel' should not have a negative value: %.4f. Taking absolute value.", M_vel)
        M_vel = abs(M_vel);
    end

    if(MV_decleration == geom.settings.codes.MV_DEC_UNKOWN)
        if(max(M_vel) > 5) % pretty much no plane is going under 5 m/s
            MV_decleration = geom.settings.codes.MV_DEC_VEL;
        else
            % M_vel is entirely above between 0 and 5 -> Mach number designation
            MV_decleration = geom.settings.codes.MV_DEC_MACH;
        end
    end
    
    if(MV_decleration == geom.settings.codes.MV_DEC_VEL)
        cond.M.v = M_vel ./ cond.a.v;
        cond.vel.v = M_vel;
    elseif(MV_decleration == geom.settings.codes.MV_DEC_MACH)
        % M_vel is entirely above between 0 and 5 -> Mach number designation
        cond.M.v = M_vel;
        cond.vel.v = M_vel .* cond.a.v;
    else
        error("Unkown MV_decleration code")
    end

    cond.qinf.v = 0.5 * cond.rho.v .* cond.vel.v .* cond.vel.v;

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
        % Compute the current weight as a ratio 0-1. Goes from empty+payload empty weight to empty+payload empty weight+fuel weights
        cond.W.v = weightRatio(W, geom);
    end
    
    cond.n.v = n;
    cond.Lift.v = cond.W.v .* cond.n.v;
    cond.CL.v = cond.Lift.v ./ (geom.ref_area.v * cond.qinf.v);

    b = 1.846; % right scaling for M0.8 at face at M2
    cond.M_face.v = log(b * cond.M.v + 1) / ( b*log(b+1)); % function where f''(0)=0, f'(0)=1, f(2)=0.8, f(0)=0
    cond.M_face.v = cond.M.v;

    cond = addCondThrottle(cond, throttle);
end