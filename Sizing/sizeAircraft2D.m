function plane = sizeAircraft2D(plane_in, missionList, constrainFun)
    % Simple & Fast. Scales wing area and changes MTOW to minimize cost. Capped at 50 iterations

    % A graphSize of 2 will go from 0.5 * opt to 2 * opt. Don't go less than 1

    x0 = [plane_in.MTOW 1];

    f = @(x) objective_constrained(x(1), x(2), plane_in, missionList, constrainFun);

    options = optimset( ...
        'Display', 'iter', ...      % Display iteration info
        'TolX', 1e-5, ...           % Tolerance on x
        'TolFun', 1e-5, ...         % Tolerance on function value
        'MaxIter', 50, ...         % Maximum iterations
        'MaxFunEvals', 1000 ...     % Maximum function evaluations
    );
    
    [x_opt, fval_opt, exitflag, output] = fminsearch(f, x0, options);

    MTOW_opt    = x_opt(1);
    scale_opt = x_opt(2);

    plane = plane_in;

    plane.span = plane_in.span * scale_opt;
    plane.c_r = plane_in.c_r * scale_opt;
    plane.c_t = plane_in.c_t * scale_opt;
    plane.MTOW = MTOW_opt;

    plane = plane.updateDerivedVariables();

    fprintf("Aicraft: %s | Sized has MTOW = %.3f lb + Wings scaled by %.5f\n", plane.name, N2lb(plane.MTOW), scale_opt)

end