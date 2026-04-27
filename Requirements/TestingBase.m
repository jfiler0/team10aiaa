classdef TestingBase < matlab.unittest.TestCase
    properties
        settings
        geom
        model
        perf
        sc_model % even though we aren't really using this
    end

    methods (TestClassSetup)
        function initializeAircraft(testCase)
            file_name = "HellstingerV3"; % HellstingerV3

            testCase.settings = readSettings();
            testCase.geom = readAircraftFile(file_name);
            testCase.geom = updateGeom(testCase.geom, testCase.settings, true);
            testCase.geom = setLoadout(testCase.geom, ["" "" "" "" "" "" "" ""]);

            testCase.model = model_class(testCase.settings, testCase.geom);
            testCase.perf = performance_class(testCase.model);
            testCase.perf.clear_data();

            % testCase.sc_model = systemcomposer.openModel("AircraftArch");
        end
    end
end