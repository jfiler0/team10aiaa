classdef performance_class < handle % <--- Inheriting from handle allows in-place updates (memory based/pointers)

    % This evaluate point performance at a give h, M, Cl, and Weight
    % The power of this function is robustness to recalculating any expensive analyisis. It saves all the data and recrusively works through
        % them to make use any calculated values. This is different from old code that would recalculate CD over and over

    % WARNING: Be VERY VERY careful about making sure ids are unique

    properties
        aircraft % link to the aircraft - curious if this is still as memory or not
        data % struct storing key performance info as it is generated
    end

    methods
        function obj = performance_class(aircraft)
            obj.setAircraft(aircraft);
        end
        function obj = setAircraft(obj, aircraft)
            obj.aircraft = aircraft;
            obj.clear_data(); % properties are no longer valid and need to be regenerated
        end
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

        % Drag components
        function out = CD0(obj)
            out = obj.simpleUpdateCheck('CD0', @() obj.aircraft.call("CD0"));
        end
        function out = CDi(obj)
            out = obj.simpleUpdateCheck('CDi', @() obj.aircraft.call("CDi"));
        end
        function out = CDW(obj)
            out = obj.simpleUpdateCheck('CDW', @() obj.aircraft.call("CDW"));
        end

        % Total CD
        function out = CD(obj)
            out = obj.simpleUpdateCheck('CD', @() obj.CD0 + obj.CDi + obj.CDW);
        end

        % Physical Forces
        function out = Drag(obj)
            out =  obj.simpleUpdateCheck('Drag', @() obj.aircraft.geom.ref_area.v * obj.aircraft.cond.qinf * obj.CD );
        end

        % Lift Over Drag
        function out = LD(obj)
            out =  obj.simpleUpdateCheck('LD', @() obj.aircraft.cond.CL.v / obj.CD() );
        end

        % Propulsion
        function out = TA(obj)
            if obj.hasData('TA')
                out = obj.data.('TA');
            else
                out = EvaluatePropData(obj);
                out = out(1);
            end
        end
        function out = TSFC(obj)
            if obj.hasData('TSFC')
                out = obj.data.('TSFC');
            else
                out = EvaluatePropData(obj);
                out = out(2);
            end
        end
        function out = alpha(obj)
            if obj.hasData('alpha')
                out = obj.data.('alpha');
            else
                out = EvaluatePropData(obj);
                out = out(3);
            end
        end

        % Note: This function does NOT check if the values have been calcualted. Use the TA, TSFC, alpha functions instead
        function out = EvaluatePropData(obj)
            out = obj.aircraft.call("PROP");
            obj.data.('TA') = out(1);
            obj.data.('TSFC') = out(2);
            obj.data.('alpha') = out(3);
        end
    end
end