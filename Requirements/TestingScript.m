classdef TestingScript < matlab.unittest.TestCase

    methods (TestClassSetup)

    end

    methods (Test)
        function verifyWingUnfoldedSpan(testCase)
            span_val = getComposerVal("MainWing", "Span");
            testCase.verifyLessThan(span_val, ft2m(60));
        end
        function verifyWingFoldedSpan(testCase)
            span_val = getComposerVal("MainWing", "Span");
            fold_ratio_val = getComposerVal("MainWing", "FoldRatio");
            testCase.verifyLessThan(span_val * (1 - fold_ratio_val), ft2m(35));
        end
        function verifyAircraftHeight(testCase)
            span_val = getComposerVal("MainWing", "Span");
            fold_ratio_val = getComposerVal("MainWing", "FoldRatio");
            testCase.verifyLessThan( 1 + span_val * fold_ratio_val, ft2m(18.5));
        end
        function verifyAircraftLength(testCase)
            length_val = getComposerVal("Fuselage", "Length");
            testCase.verifyLessThan( length_val, ft2m(50));
        end
        function verifyNumEngines(testCase)
            num_engines = getComposerVal("Fuselage/F100 Engines", "NumEngines");
            testCase.verifyTrue( (num_engines == 1) || (num_engines == 2) );
        end
        function verifyDesignLoadFactor(testCase)
            design_load_factor = getComposerVal("Fuselage", "DesignLoadFactor");
            testCase.verifyGreaterThanOrEqual(design_load_factor, 7);
        end
        function verifyCombatRadius(testCase)
            combat_radius = getComposerVal("Fuselage", "CombatRadius");
            testCase.verifyGreaterThan(combat_radius, ft2m(699));
        end
    end
end

function val = getComposerVal(comp_path, parameter_name)
    model = systemcomposer.openModel("AircraftArch");
    comp = lookup(model, Path="AircraftArch/" + comp_path);
    comp_param = comp.getParameter(parameter_name);
    val = sscanf(comp_param.Value, '%f', 1);
end