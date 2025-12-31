function condition = updateCondition(h, M_vel, CL)
    % specify either altitude and mach or altitude and velocity (tells which it is from magnitude)
    condition = struct();

    [condition.T, condition.a, condition.P, condition.rho, condition.mu] = queryAtmosphere(h, [1 1 1 1 1]);

    if(M_vel < 5) % pretty much no plane is going under 5 m/s but this can be made more robust if it becomes an issu
        condition.M = M_vel;
        condition.vel = M_vel * condition.a;
    else
        condition.M = M_vel / condition.a;
        condition.vel = M_vel;
    end

    condition.CL = CL;

end