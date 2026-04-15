% results = runtests('TestingScript_V2');
% table(results)
classdef TestingScript_V2 < matlab.unittest.TestCase
    methods (TestClassSetup)
        function openModel(testCase) %#ok<MANU>
            systemcomposer.openModel("AircraftArch");
        end
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
        Aircraft_Height = getComposerVal("VerticalTails", "Height");
        testCase.verifyLessThan(Aircraft_Height, ft2m(18.5));
    end

    function verifyAircraftLength(testCase)
        length_val = getComposerVal("Fuselage", "Length");
        testCase.verifyLessThan(length_val, ft2m(50));
    end

    function verifyNumEngines(testCase)
        num_engines = getComposerVal("Fuselage/F100 Engines", "NumEngines");
        testCase.verifyTrue((num_engines == 1) || (num_engines == 2));
    end

    function verifyDesignLoadFactor(testCase)
        design_load_factor = getComposerVal("Fuselage", "DesignLoadFactor");
        testCase.verifyGreaterThanOrEqual(design_load_factor, 7);
    end

    function verifyA2ACombatRadius(testCase)
        A2A_combat_radius = getComposerVal("Fuselage/Fuel Tanks", "A2Acombatradius");
        testCase.verifyTrue(A2A_combat_radius >= 700);
    end

    function verifyA2GCombatRadius(testCase)
        A2G_combat_radius = getComposerVal("Fuselage/Fuel Tanks", "A2Gcombatradius");
        testCase.verifyTrue(A2G_combat_radius >= 700);
    end

    function verifyMaxTOGW(testCase)
        togw = getComposerVal("Fuselage", "TOGW");
        testCase.verifyLessThanOrEqual(togw, 90000);
    end

    function verifyExternalStoreCapacity(testCase)
        store_cap = getComposerVal("External Stores", "TotalStoreCapacity_lb");
        testCase.verifyGreaterThanOrEqual(store_cap, 10000);
    end

    function verifyMaxSingleStore(testCase)
        max_store = getComposerVal("External Stores", "MaxSingleStore_lb");
        testCase.verifyLessThanOrEqual(max_store, 3000);
    end

    function verifyDashMachHigh(testCase)
        dash_mach = getComposerVal("Fuselage", "DashMach_30kft");
        testCase.verifyGreaterThanOrEqual(dash_mach, 1.6);
    end

    function verifyDashMachSL(testCase)
        dash_mach_sl = getComposerVal("Fuselage", "DashMach_SL");
        testCase.verifyGreaterThanOrEqual(dash_mach_sl, 0.85);
    end

    function verifySustainedTurnRate(testCase)
        turn_rate = getComposerVal("Fuselage", "SustainedTurnRate_degsec");
        testCase.verifyGreaterThanOrEqual(turn_rate, 8.0);
    end

    function verifyA2ACombatTime(testCase)
        combat_time = getComposerVal("Fuselage", "A2ACombatTime_min");
        testCase.verifyGreaterThanOrEqual(combat_time, 2);
    end

    function verifyApproachSpeed(testCase)
        approach_spd = getComposerVal("Fuselage", "ApproachSpeed_kts");
        testCase.verifyLessThanOrEqual(approach_spd, 145);
    end

    function verifyAvionicsTRL(testCase)
        avionics_trl = getComposerVal("Fuselage/Avionics", "TRL");
        testCase.verifyGreaterThanOrEqual(avionics_trl, 6);
    end

    function verifyEnginesTRL(testCase)
        engines_trl = getComposerVal("Fuselage/F100 Engines", "TRL");
        testCase.verifyGreaterThanOrEqual(engines_trl, 6);
    end

    function verifySEROC_Launch(testCase)
        seroc_launch = getComposerVal("Fuselage/F100 Engines", "SEROC_Launch_ftpm");
        testCase.verifyGreaterThanOrEqual(seroc_launch, 200);
    end

    function verifySEROC_Approach(testCase)
        seroc_approach = getComposerVal("Fuselage/F100 Engines", "SEROC_Approach_ftpm");
        testCase.verifyGreaterThanOrEqual(seroc_approach, 500);
    end

    end
end

function val = getComposerVal(comp_path, parameter_name)
    model = systemcomposer.openModel("AircraftArch");
    comp = lookup(model, Path="AircraftArch/" + comp_path);
    comp_param = comp.getParameter(parameter_name);
    val = sscanf(comp_param.Value, '%f', 1);
end