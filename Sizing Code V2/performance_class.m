classdef performance_class < handle % <--- Inheriting from handle allows in-place updates (memory based/pointers)

    % This evaluate point performance at a give h, M, Cl, and Weight
    % The power of this function is robustness to recalculating any expensive analyisis. It saves all the data and recrusively works through
        % them to make use any calculated values. This is different from old code that would recalculate CD over and over

    % WARNING: Be VERY VERY careful about making sure ids are unique

    properties
        model % link to the model. Stays connected through memory
        data % struct storing key performance info as it is generated
    end

    methods
        % INITIALIZATION
        function obj = performance_class(model)
            obj.model = model;
        end

        %% HELPERS
        function obj = clear_data(obj)
            obj.data = struct();
        end
        function bool = hasData(obj, field)
            bool = isfield(obj.data, field);
        end
        function out = simpleUpdateCheck(obj, id, handle)
            if obj.hasData(id)
                out = obj.data.(id);
            else
                obj.data.(id) = handle();
                out = obj.data.(id);
            end
        end

        %% ACTUAL MAIN FUNCTIONS

        % Total CD
        function out = CD(obj)
            out = obj.simpleUpdateCheck('CD', @() obj.model.CD0 + obj.model.CDi + obj.model.CDw);
        end

        % Physical Forces
        function out = Drag(obj)
            out =  obj.simpleUpdateCheck('Drag', @() obj.model.geom.ref_area.v * obj.model.cond.qinf .* obj.CD );
        end

        % Lift Over Drag
        function out = LD(obj)
            out =  obj.simpleUpdateCheck('LD', @() obj.model.cond.CL.v ./ obj.CD );
        end

        % Propulsion
        function out = TA(obj)
            if obj.hasData('TA')
                out = obj.data.('TA');
            else
                out = obj.model.PROP;
                out = out(1);
            end
        end
        function out = TSFC(obj)
            if obj.hasData('TSFC')
                out = obj.data.('TSFC');
            else
                out = obj.model.PROP;
                out = out(2);
            end
        end
        function out = alpha(obj)
            if obj.hasData('alpha')
                out = obj.data.('alpha');
            else
                out = obj.model.PROP;
                out = out(3);
            end
        end
    end
end