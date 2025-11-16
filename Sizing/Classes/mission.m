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
        function [WTO_Next, fuel_burned, W_End] = solveMission(obj, plane)
            W0 = plane.MTOW;
            W = W0;

            fuel_reserve = 0.05; % Keep 5 percent fuel reserve

            plane = plane.applyLoadout(obj.loadout); % Update W_P

            fuel_burned = 0;

            for i = 1:numel(obj.segment_list)
                
                if(W < 0) % Add robustness if intial guess is way off so it can be caught in sizeAircraft
                    W = plane.WE;
                end
                % [W_OUT, WF, fuel_burned]
                [W_OUT, WF, fuel_burned_i] = obj.segment_list(i).queryWF(W, plane);
                % fprintf("\nW_IN = %.2f lb, W_OUT = %.2f lb, fuel_burned = %.2f lb, WF = %.3f", N2lb(W), N2lb(W_OUT), N2lb(fuel_burned_i), WF)

                W = W_OUT; % Update weight for the next segment
                fuel_burned = fuel_burned + fuel_burned_i;
            end
            % Fuel tank weight = fuel_burned / (1 - fuel_reserve)

            % Calculate the requried MTOW, will be NaN if something went wrong
            WTO_Next = plane.WE + fuel_burned / (1 - fuel_reserve) + plane.W_P + plane.W_Tanks + plane.W_F;
            W_End = W;

        end
    end
end
