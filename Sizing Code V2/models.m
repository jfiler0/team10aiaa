classdef models

    properties
        geometry
        settings

        CD0_model
    end

    methods
        function obj = models(geometry, settings, CD0_model)
            obj.geometry = geometry;
            obj.settings = settings;

            obj.CD0_model = CD0_model;
        end
        function CD0 = fetch_CD0(obj, input)
            CD0 = obj.CD0_model(input, obj.geometry, obj.settings);
        end
    end
end
