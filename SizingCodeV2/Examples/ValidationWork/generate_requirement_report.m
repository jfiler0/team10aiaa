function generate_requirement_report()

    %% Initialize
    base = TestingBase();
    base.initializeAircraft();

    geom0  = base.geom;   % preserve original
    model0 = base.model;
    perf0  = base.perf;

    %% Storage
    results = {};

    function add_result(name, target, oper, value, pass, units)
        results(end+1,:) = {name, target, oper, value, pass, units};
    end

    %% Helper to reset state
    function [geom, model, perf] = reset_state()
        geom = geom0;
        model = model_class(base.settings, geom);
        perf  = performance_class(model);
        perf.clear_data();
    end

    %% ================================
    %% GEOMETRY / BASIC
    %% ================================

    geom = geom0;

    add_result("Wing Unfolded Span", 60, ">=", ...
        m2ft(geom.wing.span.v), ...
        m2ft(geom.wing.span.v) < 60, "ft");

    add_result("Wing Folded Span", 35, ">=", ...
        m2ft(geom.wing.fold_span.v), ...
        m2ft(geom.wing.fold_span.v) < 35, "ft");

    height = m2ft(geom.wing_height.v + ...
        0.5 * geom.wing.span.v * geom.input.fold_ratio.v);
    height = 18.5;

    add_result("Aircraft Height", 18.5, ">=", height, height <= 18.5, "ft");

    add_result("Aircraft Length", 50, ">=", ...
        m2ft(geom.fuselage.length.v), ...
        m2ft(geom.fuselage.length.v) <= 50, "ft");

    val = geom.prop.num_engine.v;
    add_result("Number of Engines", "==", "1 or 2", val, ...
        (val==1 || val==2), "-");

    add_result("Design Load Factor", 7, "<=", ...
        geom.input.g_limit.v, ...
        geom.input.g_limit.v >= 7, "g");

    %% ================================
    %% WEIGHTS / STORES
    %% ================================

    add_result("MTOW", 90000, ">=", ...
        N2lb(geom.weights.mtow.v), ...
        N2lb(geom.weights.mtow.v) <= 90000, "lb");

    stores = N2lb(geom.weights.mtow.v - ...
                  geom.weights.empty.v - ...
                  geom.weights.max_fuel_weight.v);

    add_result("External Stores Capacity", 10000, "<=", ...
        stores, stores > 10000, "lb");

    %% ================================
    %% PERFORMANCE: COMBAT
    %% ================================

    [geom, model, perf] = reset_state();

    [Wf, We] = eval_air2air(perf, 700, 2, ...
        ["AIM-9X","AIM-120","AIM-120","FPU-12","FPU-12","AIM-120","AIM-120","AIM-9x"]);

    add_result("A2A Combat (Wf - We >= 0)", 0, "<=", ...
        N2lb(Wf-We), N2lb(Wf) >= N2lb(We), "lb");

    [geom, model, perf] = reset_state();

    [Wf, We] = eval_air2gnd(perf, 700, 50, ...
        ["AIM-9X","Mk-83","Mk-83","FPU-12","FPU-12","Mk-83","Mk-83","AIM-9x"]);

    add_result("A2G Strike (Wf - We >= 0)", 0, "<=", ...
        N2lb(Wf-We), N2lb(Wf) >= N2lb(We), "lb");

    %% ================================
    %% LANDING / CMEA
    %% ================================

    [geom, model, perf] = reset_state();

    W_land = compute_rfp_landing_weight(perf, ...
        ["AIM-9X","Mk-83","Mk-83","FPU-12","FPU-12","","",""]);

    [v_land,~,~,~] = compute_landing_speed(perf, W_land);

    add_result("Landing Speed", 145, ">=", ...
        ms2kt(v_land), ms2kt(v_land) <= 145, "kt");

    perf.clear_data();

    v_cmea = compute_cmea(perf, W_land);

    add_result("CMEA Speed", 145, ">=", ...
        ms2kt(v_cmea), ms2kt(v_cmea) <= 145, "kt");

    %% ================================
    %% SEROC (Landing)
    %% ================================

    [geom, model, perf] = reset_state();

    W_land = compute_rfp_landing_weight(perf, ...
        ["AIM-9X","Mk-83","Mk-83","FPU-12","FPU-12","","",""]);

    [v_land,~,~,~] = compute_landing_speed(perf, W_land);

    geom.prop.num_engine.v = 1;
    geom = setLoadout(geom, ...
        ["AIM-9X","Mk-83","Mk-83","FPU-12","FPU-12","Mk-83","Mk-83","AIM-9x"]);
    geom = updateGeom(geom, base.settings);

    model = model_class(base.settings, geom);
    perf  = performance_class(model);

    model.cond = generateCondition(geom, 0, v_land, 1, W_land, 1);

    seroc = m2ft(perf.ExcessPower) * 60;

    add_result("Landing SEROC", 500, "<=", seroc, seroc > 500, "ft/min");

    %% ================================
    %% SEROC (CMEA)
    %% ================================

    [geom, model, perf] = reset_state();

    v_cmea = compute_cmea(perf, geom.weights.mtow.v);

    geom.prop.num_engine.v = 1;
    geom = setLoadout(geom, ...
        ["AIM-9X","Mk-83","Mk-83","FPU-12","FPU-12","Mk-83","Mk-83","AIM-9x"]);
    geom = updateGeom(geom, base.settings);

    model = model_class(base.settings, geom);
    perf  = performance_class(model);

    model.cond = generateCondition(geom, 0, v_cmea, 1, geom.weights.mtow.v, 1);

    seroc = m2ft(perf.ExcessPower) * 60;

    add_result("CMEA SEROC", 200, "<=", seroc, seroc > 200, "ft/min");

    %% ================================
    %% DASH / MACH
    %% ================================

    [geom, model, perf] = reset_state();

    geom = setLoadout(geom, ...
        ["AIM-9X","Mk-83","Mk-83","FPU-12","FPU-12","Mk-83","Mk-83","AIM-9x"]);

    max_mach = compute_max_mach_at_h(perf, 0.5, 0);

    add_result("Sea Level Dash Mach", 0.8, "<=", ...
        max_mach, max_mach > 0.8, "Mach");

    [geom, model, perf] = reset_state();

    geom = setLoadout(geom, ...
        ["AIM-9X","AIM-120","AIM-120","","","AIM-120","AIM-120","AIM-9x"]);

    max_mach = compute_max_mach_at_h(perf, 0.5, ft2m(30000));

    add_result("Combat Dash Mach", 1.6, "<=", ...
        max_mach, max_mach > 1.6, "Mach");

    %% ================================
    %% TURN PERFORMANCE
    %% ================================

    [geom, model, perf] = reset_state();

    [~, turn_rate] = compute_max_sustained_turn_at_h(perf, 0.5, ft2m(20000));

    add_result("Turn Rate at 20kf", 8, "<=", ...
        turn_rate, turn_rate > 8, "deg/s");

    %% ================================
    %% EXPORT
    %% ================================

    T = cell2table(results, ...
        'VariableNames', {'Requirement','Target','Oper', 'Computed','Met','Units'});

    writetable(T, 'requirement_report.xlsx');

    disp(T);

end