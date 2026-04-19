function [obj, output] = objective4(mtow, wing_scale, model, base_geom)
    model.clear_mem();

    % Version of objective3 for wingloading_thrustoading_plot

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
    
    %% STEP 1: Modify geom 
    geom = base_geom;
    geom.weights.mtow.v = mtow;
    geom.wing = scale_surface(base_geom.wing, wing_scale);

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

    perf.clear_data();
    [W_final, W_empty] = eval_air2air(perf, 800, 2); % 2 minutes of combat
    output = add_const(output, W_final, W_empty, OVER, "800nm Radius (Air2Air)");
    % [W_final, W_empty] = eval_air2gnd(perf, 800, 50); % 50nm dash
    % output = add_const(output, W_final, W_empty, OVER, "800nm Radius (Air2Gnd)");

    try
        [v_land, glide_angle, ~] = compute_landing_speed(perf, 1); % landing at full weight
    catch
        disp("break")
    end
        % could constrain glide_angle
    perf.clear_data();
    output = add_const(output, ms2kt(v_land), 145, UNDER, "145kt Landing Speed");

    max_mach_30 = compute_max_mach_at_h(perf, 0.5, ft2m(30000)); perf.clear_data();
    output = add_const(output, max_mach_30, 1.6, OVER, "M1.6 at 30kf");

    max_mach_0 = compute_max_mach_at_h(perf, 0.5, 0); perf.clear_data();
    output = add_const(output, max_mach_0, 0.8, OVER, "M0.8 at Sealevel");

    output = add_const(output, m2ft(geom.wing.span.v), 60, UNDER, "60ft Unfolded Limit");

    % output = add_const(output, perf.model.COST, 90, UNDER, "90mil Max Cost"); perf.clear_data();


    %% STEP 5: Apply penalities and return obj
    R = 100;

    obj = geom.wing.area.v; % try to minimize
    obj = cost; % try to minimize
    obj = obj / 10 + R * max([0, output.g_vec]); % diving cost serves to normalize it closer to 1 
    
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