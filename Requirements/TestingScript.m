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
            testCase.verifyLessThan(geom.wing_height.v + 0.5 * testCase.geom.wing.span.v * testCase.geom.input.fold_ratio.v, ft2m(18.5));
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
            [W_final, empty_weight] = eval_air2air(testCase.perf, 700, 2, ["AIM-9X" "AIM-120" "AIM-120" "FPU-12" "FPU-12" "AIM-120" "AIM-120" "AIM-9x"]);
            testCase.verifyGreaterThanOrEqual(W_final, empty_weight);
        end

        function verifyA2GCombatRadius(testCase)
            val = getComposerVal(testCase, "Fuselage/Fuel Tanks", "A2Gcombatradius");
            [W_final, empty_weight] = eval_air2gnd(testCase.perf, 700, 50, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"]);
            testCase.verifyGreaterThanOrEqual(W_final, empty_weight);
        end

        function verifyCMEA(testCase)
            % There isn't really a constraint on CMEA...
            rfp_landing_weight = compute_rfp_landing_weight(testCase.perf, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "" "" ""]); % half stores dropped
            testCase.verifyLessThanOrEqual(ms2kt(compute_cmea(testCase.perf, rfp_landing_weight)), 145);
            testCase.geom = setLoadout(testCase.geom, ["" "" "" "" "" "" "" ""]); % just to be safe
        end

        function verifyLandingSpeed(testCase)
            rfp_landing_weight = compute_rfp_landing_weight(testCase.perf, ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "" "" ""]); % half stores dropped
            [v_land, ~, ~, ~] = compute_landing_speed(testCase.perf, rfp_landing_weight); testCase.perf.clear_data(); % landing at rfp req
            testCase.verifyLessThanOrEqual(ms2kt(v_land), 145);
        end

        function verifyMTOW(testCase)
            testCase.verifyLessThanOrEqual(N2lb(testCase.geom.weights.mtow.v), 90000);
        end

    end
end

function val = getComposerVal(testCase, comp_path, parameter_name)
    comp = lookup(testCase.sc_model, Path="AircraftArch/" + comp_path);
    comp_param = comp.getParameter(parameter_name);
    val = sscanf(comp_param.Value, '%f', 1);
end
