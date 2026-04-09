function [obj, output] = objective2(X, model, base_geom)
    model.clear_mem();
    % X -> Design Vector - for this just one variable
    % geom -> Saved to not need to reimport settings and build json_entry every time (acts as base reference)

    % obj -> numerical value to minimize to find the best, viable design
    % output -> a struct storing info about constraints and design information for plotting purposes
    
    %% STEP 1: Modify geom according the X design vector
    geom = base_geom;

    % X(1) - MTOW (N)
    % X(2) - Wing Root Chord (m)
    % X(3) - Wing Span (m)
    % X(4) - Wing Sweep (deg)

    geom.weights.mtow.v = X(1);

    % MAIN WING DEFENITION - only the inboard side of the flap must be defined
        wing_root = X(2);
        wing_span = X(3);
        sweep = X(4);
        
        wing_tip = 0.25 * wing_root;
        lerx_root = wing_root*2;
        wing_le_x = 0.48 * geom.fuselage.length.v - lerx_root + wing_root;
    
        sec0 = new_section(lerx_root, wing_le_x, geom.fuselage.diameter.v/2, tc=0.06);
        sec1 = new_section(wing_root, wing_le_x + lerx_root - wing_root, sec0.le_yp.v + 0.08 * wing_span, tc=0.04);
        sec6 = new_section(wing_tip, wing_le_x + lerx_root - wing_root + sind(sweep)*(wing_span/2 - sec1.le_y.v), wing_span/2, tc=0.02);
        
        % MAIN FLAP
        sec2 = btw_section(sec1, sec6, 0.1, flap_length=0.2, control_name="Main Flap");
        sec3 = btw_section(sec1, sec6, 0.5);
        
        % AILERON
        sec4 = btw_section(sec1, sec6, 0.6, flap_length=0.1, control_name="Aileron");
        sec5 = btw_section(sec1, sec6, 0.9);
        
        geom.wing = assemble_surface([sec0, sec1, sec2, sec3, sec4, sec5, sec6]);

    %% STEP 2: Create needed classes
    geom = updateGeom(geom, model.settings, false);
    model.geom = geom;
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

    % next: mission range constraint to keep weight from falling. can I get the estimate to properly get close

    % then max mach for wing dimensions

    %% STEP 5: Apply penalities and return obj
    R = 100;

    obj = cost / 100 + R * max([0, g1]); % diving cost serves to normalize it closer to 1 

    output = struct();
    output.perf = perf;
    output.geom = geom;

end