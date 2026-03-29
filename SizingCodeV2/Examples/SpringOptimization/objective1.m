function [obj, output] = objective1(X, geom, settings)
    % X -> Design Vector - for this just one variable
    % geom -> Saved to not need to reimport settings and build json_entry every time (acts as base reference)

    % obj -> numerical value to minimize to find the best, viable design
    % output -> a struct storing info about constraints and design information for plotting purposes
    
    %% STEP 1: Modify geom according the X design vector
    geom.wing = scale_surface(geom.wing, X(1), [geom.wing.qrtr_chd_x.v, geom.wing.le_y.v]);
    geom = updateGeom(geom, settings);

    %% STEP 2: Create needed classes
    model = model_class(settings, geom);
    perf = performance_class(model);
    cond = levelFlightCondition(perf, 0, 0.5, 1); % M0.5, sea level, MTOW
        % setting a starting condition just so it is happy
        model.cond = cond;

    %% STEP 3: Evaluate primary objective (uncontrained)
    cost = model.COST;

    %% STEP 4: Build vector of constraints
    [v_land, glide_angle, ~] = compute_landing_speed(perf, 1); % landing at full weight
        % could constrain glide_angle

    g1 = ms2kt(v_land)/145 - 1;

    %% STEP 5: Apply penalities and return obj
    R = 100;

    obj = cost + R * max([0, g1]);

    output = struct();
    output.perf = perf;

end