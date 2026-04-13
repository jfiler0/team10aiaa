function [obj, output] = objective2(X, model, base_geom, settings)
    model.clear_mem();
    % codes for which constraint type to use
    OVER = 1; 
    UNDER = 0; 

    output = struct(); % stores detailed constraint info
    output.g_vec = [];
    output.g_names = [];
    output.value = [];
    output.type = [];
    output.target = [];

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
        sweep = 30; % to match mach angle
        
        wing_tip = X(4);
        lerx_root = wing_root*1.7;
        wing_le_x = 0.48 * geom.fuselage.length.v - lerx_root + wing_root;
    
        sec0 = new_section(lerx_root, wing_le_x, geom.fuselage.diameter.v/2, tc=0.06);
        sec1 = new_section(wing_root, wing_le_x + lerx_root - wing_root, sec0.le_yp.v + 0.08 * wing_span, tc=0.04);
        sec6 = new_section(wing_tip, sec1.le_x.v + sind(sweep)*(wing_span/2 - sec1.le_y.v), wing_span/2, tc=0.02);
        
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

% log(weightRatio(1, geom) / weightRatio(0, geom))

    %% STEP 3: Evaluate primary objective (uncontrained)
    cost = model.COST;

    %% STEP 4: Build vector of constraints
    
    % output = compute_missions_res(output, readMissionStruct("OPM_Air2Air_700nm"), perf, settings, "Air2Air");

    x0 = [ft2m(30000), 0.7];

    perf.model.geom = setLoadout(geom, ["AIM-9X" "AIM-120" "AIM-120" "AIM-120" "AIM-120" "AIM-120" "AIM-120" "AIM-9X"]);
    range_air2air = estimate_max_range(perf, 1, x0_override=x0);    
    output = add_const(output, m2nm(range_air2air), 1600, OVER, "800nm Radius (Air2Air)");

    % perf.model.geom = setLoadout(geom, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"]);
    % range_air2air = estimate_max_range(perf, 1, x0_override=x0);    
    % output = add_const(output, m2nm(range_air2air), 1600, OVER, "800nm Radius (Air2Gnd)");
    % 
    % perf.model.geom = setLoadout(geom, ["AIM-9X" "" "" "FPU-12" "FPU-12" "" "" "AIM-9x"]);
    % range_air2air = estimate_max_range(perf, 1, x0_override=x0);    
    % output = add_const(output, m2nm(range_air2air), 1600, OVER, "900nm Radius (Ferry)");  

    try
        [v_land, glide_angle, ~] = compute_landing_speed(perf, 1); % landing at full weight
    catch
        disp("break")
    end
        % could constrain glide_angle
    output = add_const(output, ms2kt(v_land), 145, UNDER, "145kt Landing Speed");

    % if m2nm(range) < 1700
    %     % Don't even bother with the more advanced mission sims
    %     output = add_const(output, 1, 1, OVER, "Air2Gnd (IGNORED)");
    %     output = add_const(output, 1, 1, OVER, "Air2Air (IGNORED)");
    % else
    %     output = compute_missions_res(output, readMissionStruct("OPM_Air2Air_700nm"), perf, settings, "Air2Air");
    %     output = compute_missions_res(output, readMissionStruct("OPM_Air2Gnd_700nm"), perf, settings, "Air2Gnd");
    % end

    max_mach_30 = compute_max_mach_at_h(perf, 0.5, ft2m(30000));
    output = add_const(output, max_mach_30, 1.6, OVER, "M1.6 at 30kf");

    max_mach_0 = compute_max_mach_at_h(perf, 0.5, 0);
    output = add_const(output, max_mach_0, 0.8, OVER, "M0.8 at Sealevel");

    output = add_const(output, m2ft(geom.wing.span.v), 60, UNDER, "60ft Unfolded Limit");

    % then max mach for wing dimensions

    %% STEP 5: Apply penalities and return obj
    R = 100;

    obj = cost / 100 + R * max([0, output.g_vec]); % diving cost serves to normalize it closer to 1 
    
    % fprintf("obj = %.5g | X = [%.3g %.3g %.3g %.3g]\n", obj, X(1), X(2), X(3), X(4))

    output.perf = perf;
    output.geom = geom;
    output.cost = cost;

end

function output = add_const(output, value, target, type, name, opts)
arguments
    output 
    value 
    target 
    type 
    name 
    opts.weight = 1
end
    % codes for which constraint type to use
    UNDER = 0; OVER = 1; 

    if type == UNDER
        output.g_vec = [output.g_vec, opts.weight*(value/target-1)];
    elseif type == OVER
        output.g_vec = [output.g_vec, opts.weight*(1-value/target)];
    else
        error("Undefined constraint type")
    end

    output.value = [output.value, value];
    output.target = [output.target, target];
    output.g_names = [output.g_names, name];
    output.type = [output.type, type];
end

function output = compute_missions_res(output, mission, perf, settings, des)
    % copying performance is a bit safer
    temp_perf = perf; % the loadout being set transfer back out cause yay memory based variables
    temp_perf.clear_data; temp_perf.model.clear_mem();

    temp_calc = mission_calculator(temp_perf, settings); % loadout is applied internally
    temp_calc.record_hist = false; % true for plotting
    temp_calc.do_print = false;
    temp_calc.build_map(); % assembles v, h, W map for key performance info

    W_final = temp_calc.solve_mission(mission, 0, kt2ms(135), 1); % starts at 135 kt at full weight

    if isnan(W_final) % it failed -> set a high penalty that forces mtow higher
        output = add_const(output, perf.model.geom.weights.mtow.v, lb2N(120000), 1, des, weight=100); % manually large number
    else
        % everything is fine
        output = add_const(output, W_final, weightRatio(0, temp_perf.model.geom), 1, des);
    end

    % temp_calc.plot_hist
end