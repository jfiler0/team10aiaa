classdef mission
    properties
        segment_list
        loadout
    end

    methods
        function obj = mission(segment_list, loadout) 
            
            % segment_list should be an array of flightSegment2 objects. loadout should be a constructor from buildLoadout

            % EXAMPLES:
            % ferry = [...
            %     flightSegment2("TAKEOFF") 
            %     flightSegment2("CLIMB", 0.7) 
            %     flightSegment2("CRUISE", 0.6, NaN, nm2m(1000)) % 800 nm flight
            %     flightSegment2("LOITER", NaN, 10000, 20) % 20 min loiter
            %     flightSegment2("COMBAT", 0.8, 1000, [8 0]) % 8 minutes of combat, deploy payload***
            %     flightSegment2("CRUISE", 0.6, NaN, nm2m(1000)) % 800 nm flight
            %     flightSegment2("LANDING") ];
            % clean_loadout = buildLoadout(["AIM-9X", "AIM-9X"]);

            obj.segment_list = segment_list;
            obj.loadout = loadout;

        end
        function [fuel_burned, W_End] = solveMission(obj, plane)
            W0 = plane.MTOW;
            W = W0;

            for i = 1:numel(obj.segment_list)
                % [W_OUT, WF, fuel_burned]
                [W, ~, ~] = obj.segment_list(i).queryWF(W, plane);
            end

            W_End = W;
            fuel_burned = W0 - W_End;
        end
    end
end
