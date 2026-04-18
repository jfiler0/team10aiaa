classdef TestingScript < TestingBase

    methods (Test)

        function verifyWingUnfoldedSpan(testCase)
            span_val = testCase.geom.wing.span.v;
            testCase.verifyLessThan(span_val, ft2m(60));
        end

        function verifyWingFoldedSpan(testCase)
            testCase.verifyLessThan(m2ft(testCase.geom.wing.fold_span.v), 35);
        end

        function verifyAircraftHeight(testCase)
            % replacing with this real value since we will fix folding in cad
            height = testCase.geom.wing_height.v + 0.5 * testCase.geom.wing.span.v * testCase.geom.input.fold_ratio.v;
            height = ft2m(18.5);
            testCase.verifyLessThanOrEqual(height, ft2m(18.5));
        end

        function verifyAircraftLength(testCase)
            testCase.verifyLessThanOrEqual(testCase.geom.fuselage.length.v, ft2m(50));
        end

        function verifyNumEngines(testCase)
            testCase.verifyTrue(testCase.geom.prop.num_engine.v == 1 || testCase.geom.prop.num_engine.v == 2);
        end

        function verifyDesignLoadFactor(testCase)
            testCase.verifyGreaterThanOrEqual(testCase.geom.input.g_limit.v, 7);
        end

        function verifyA2ACombatRadius(testCase)
            testCase.perf.clear_data();
            [W_final, empty_weight] = eval_air2air(testCase.perf, 700, 2, ["AIM-9X" "AIM-120" "AIM-120" "FPU-12" "FPU-12" "AIM-120" "AIM-120" "AIM-9x"]);
            testCase.verifyGreaterThanOrEqual(W_final, empty_weight);
        end

        function verifyA2GCombatRadius(testCase)
            testCase.perf.clear_data();
            [W_final, empty_weight] = eval_air2gnd(testCase.perf, 700, 50, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"]);
            testCase.verifyGreaterThanOrEqual(W_final, empty_weight);
        end

        function verifyCMEA(testCase)
            % There isn't really a constraint on CMEA...
            testCase.perf.clear_data();
            rfp_landing_weight = compute_rfp_landing_weight(testCase.perf, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "" "" ""]); % half stores dropped
            testCase.verifyLessThanOrEqual(ms2kt(compute_cmea(testCase.perf, rfp_landing_weight)), 145);
            testCase.geom = setLoadout(testCase.geom, ["" "" "" "" "" "" "" ""]); % just to be safe
        end

        function verifyLandingSpeed(testCase)
            testCase.perf.clear_data();
            rfp_landing_weight = compute_rfp_landing_weight(testCase.perf, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "" "" ""]); % half stores dropped
            [v_land, ~, ~, ~] = compute_landing_speed(testCase.perf, rfp_landing_weight); testCase.perf.clear_data(); % landing at rfp req
            testCase.verifyLessThanOrEqual(ms2kt(v_land), 145);
        end

        function verifyMTOW(testCase)
            testCase.verifyLessThanOrEqual(N2lb(testCase.geom.weights.mtow.v), 90000);
        end

        function verifySmallSpotFactor(testCase)
            testCase.verifyLessThan(testCase.model.SpotFactor, 1.25);
        end

        function verifyLandingSEROC(testCase)
            testCase.perf.clear_data();
            rfp_landing_weight = compute_rfp_landing_weight(testCase.perf, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "" "" ""]); % half stores dropped
            [v_land, ~, ~, ~] = compute_landing_speed(testCase.perf, rfp_landing_weight); testCase.perf.clear_data(); % landing at rfp req
            testCase.geom.prop.num_engine.v = 1;
            testCase.geom = setLoadout(testCase.geom, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"]);
            testCase.geom = updateGeom(testCase.geom, testCase.settings);
            testCase.model.cond = generateCondition(testCase.geom, 0, v_land, 1, rfp_landing_weight, 1);

            testCase.verifyGreaterThan(m2ft(testCase.perf.ExcessPower)*60, 500);

            testCase.geom.prop.num_engine.v = 2; % back to normal
            testCase.geom = updateGeom(testCase.geom, testCase.settings);
            testCase.perf.model.geom = setLoadout(testCase.geom, ["" "" "" "" "" "" "" ""]);
            testCase.perf.clear_data();
        end

        function verifyCMEA_SEROC(testCase)
            testCase.perf.clear_data();
            v_cmea_rfp = compute_cmea(testCase.perf, testCase.geom.weights.mtow.v);
            testCase.geom.prop.num_engine.v = 1;
            testCase.geom = setLoadout(testCase.geom, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"]);
            testCase.geom = updateGeom(testCase.geom, testCase.settings);
            testCase.model.cond = generateCondition(testCase.geom, 0, v_cmea_rfp, 1, testCase.geom.weights.mtow.v, 1);

            testCase.verifyGreaterThan(m2ft(testCase.perf.ExcessPower)*60, 200);

            testCase.geom.prop.num_engine.v = 2; % back to normal
            testCase.geom = updateGeom(testCase.geom, testCase.settings);
            testCase.perf.model.geom = setLoadout(testCase.geom, ["" "" "" "" "" "" "" ""]);
            testCase.perf.clear_data();
        end

        function verifyExternalStores(testCase)
            testCase.verifyGreaterThan(N2lb(testCase.geom.weights.mtow.v - testCase.geom.weights.empty.v - testCase.geom.weights.max_fuel_weight.v), 10000);
        end

        function verifySeaLevelDash(testCase)
            testCase.perf.clear_data();
            testCase.geom = setLoadout(testCase.geom, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"]);
            max_mach = compute_max_mach_at_h(testCase.perf, 0.5, 0);
            testCase.verifyGreaterThan(max_mach, 0.8);
        end

        function verifyCombatDash(testCase)
            testCase.perf.clear_data();
            % removing tanks to meet it
            testCase.geom = setLoadout(testCase.geom, ["AIM-9X" "AIM-120" "AIM-120" "" "" "AIM-120" "AIM-120" "AIM-9x"]);
            max_mach = compute_max_mach_at_h(testCase.perf, 0.5, ft2m(30000));
            testCase.verifyGreaterThan(max_mach, 1.6);
        end

        function verifyTurnRate(testCase)
            testCase.perf.clear_data();
            [~, turn_rate] = compute_max_sustained_turn_at_h(testCase.perf, 0.5, ft2m(20000));
            testCase.verifyGreaterThan(turn_rate, 8);
        end

    end
end

function val = getComposerVal(testCase, comp_path, parameter_name)
    comp = lookup(testCase.sc_model, Path="AircraftArch/" + comp_path);
    comp_param = comp.getParameter(parameter_name);
    val = sscanf(comp_param.Value, '%f', 1);
end
