function v_cmea = compute_cmea(perf, W)
    % Associated loadout should have been applied to perf.model.geom
    % GOAL: Find v where lift at aoa_max

    aoa_max = 10; % for CL_max
    aoa_cmea = 0.9 * aoa_max; % will be 90% clmax since airfoils are symmetric
    flap_inc = 1.55;

    v0  = 50; % strting guess

    err = 1;
    tol = 1E-5;
    i_limit = 30; i = 0;

    v = v0;
    
    while err > tol
        i = i + 1;

        cond = generateCondition(perf.model.geom, 0, v, 1, W, 1); % max ab
        perf.model.cond = cond;

        CL = flap_inc * perf.model.CLa * aoa_cmea * pi/180;

        v_next = sqrt( 2*cond.W.v/(cond.rho.v*perf.model.geom.ref_area.v*CL));

        err = abs(v_next - v)/v;
        v = v_next;
    end

    if i == i_limit
        warning("Landing speed search hit iteration limit.")
    end

    v_cmea = v;
end