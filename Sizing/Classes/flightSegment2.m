classdef flightSegment2
    properties
        type

        h % segment altiutude in meters
        M % mach number
        % Either or both can be left as NaN and it will sove for 
        % optimum for the configuration for CRUISE & LOITER

        Cd0 % parasite drag
        input % varies depending on what segement
        % CRUISE -> Range in meters
        % LOTIER -> Time in minutes
        % COMBAT -> [Time, Payload] [min, *], Payload deployed in fraction of total stores loaded. 0.5 -> drop half. 0 -> drop nothing. 1 -> Everything
        % CLIMB -> NaN
        % LANDING -> NaN
        % TAKEOFF -> NaN

    end

    methods
        function obj = flightSegment2(type, M, h, input) 
            if nargin < 2, M = NaN; end
            if nargin < 3, h = NaN; end
            % if nargin < 4, Cd0 = NaN; end
            % if nargin < 5, input = NaN; end
            if nargin < 4, input = NaN; end
        
            obj.type  = type;
            obj.h     = h;
            obj.M     = M;
            % obj.Cd0   = Cd0;
            obj.input = input;

           % --- Validation checks for flight segment setup ---

            % Combat requires both M and h defined
            if (isnan(M) || isnan(h)) && strcmp(obj.type, "COMBAT")
                error("Combat requires both M & h be defined");
            end
            
            % Climb requires M defined
            if isnan(M) && strcmp(obj.type, "CLIMB")
                error("Climb requires M be defined");
            end

        end
        function [W_OUT, WF, fuel_burned] = queryWF(obj, W_IN, plane)
            % LD = 1 / ( (q*obj.Cd0) / (W_IN/plane.S) + (W_IN/plane.S) / (q * pi * plane.e * plane.AR) );

            % Lots taken from HW1

            % For the cruise & loiter minimization stuff - Its currently just taking the max bounds which isn't great
            options = optimset('Display', 'off');  % fminbnd is simpler and bounded
            M_bounds = [0.4, 1];         % Mach range
            h_bounds = [0, 20000];         % Altitude range [m]

            if(obj.type == "TAKEOFF")
                WF = 0.95; % Hardcoding this feels wrong
            elseif(obj.type == "LANDING")
                WF = 0.995;
            elseif(obj.type == "CLIMB")
                WF = 1.0065 - 0.0325*obj.M;
            elseif(obj.type == "CRUISE")

                if isnan(obj.M) && isnan(obj.h) % both are free
                    [h, M, ~, L2D] = plane.findMaxRangeState(W_IN);
                elseif isnan(obj.M) && ~isnan(obj.h) % mach is free
                    fun = @(M) plane.calcL2D(obj.h, M, W_IN);
                    [M, L2D] = fminbnd(fun, M_bounds(1), M_bounds(2), options);
                    h = obj.h;
                elseif isnan(obj.h) && ~isnan(obj.M) % height is free
                    fun = @(h) plane.calcL2D(h, obj.M, W_IN);
                    [h, L2D] = fminbnd(fun, h_bounds(1), h_bounds(2), options);
                    M = obj.M;
                else % both are fixed
                    M = obj.M;
                    h = obj.h;
                    L2D = plane.calcL2D(h, M, W_IN);
                end

                WF = obj.Cruise_WF(L2D, h, M, plane);

            elseif(obj.type == "LOITER")

                if isnan(obj.M) && isnan(obj.h) % both are free
                    [h, M, ~, LD] = plane.findMaxEnduranceState(W_IN);
                elseif isnan(obj.M) && ~isnan(obj.h) % mach is free
                    fun = @(M) plane.calcLD(obj.h, M, W_IN);
                    [M, LD] = fminbnd(fun, M_bounds(1), M_bounds(2), options);
                    h = obj.h;
                elseif isnan(obj.h) && ~isnan(obj.M) % height is free
                    fun = @(h) plane.calcLD(h, obj.M, W_IN);
                    [h, LD] = fminbnd(fun, h_bounds(1), h_bounds(2), options);
                    M = obj.M;
                else % both are fixed
                    M = obj.M;
                    h = obj.h;
                    LD = plane.calcLD(h, M, W_IN);
                end

                WF = obj.Loiter_WF(LD, h, M, plane);

            elseif(obj.type == "COMBAT")
                % [TA, TSFC, alpha, mdotf] = calcProp(obj, M, h, AB_perc)
                [TA, TSFC, ~, ~] = plane.calcProp(obj.M, obj.h, 1); % Assume AB for combat
                fuel_burned = 60*obj.input(1)*TSFC*TA;

                payload_to_drop = plane.W_P * obj.input(2); % Weight in N of payload to deploy. This REQUIRES plane.applyLoadout has been done at some point

                W_OUT = W_IN - fuel_burned - payload_to_drop;
                WF = W_OUT/W_IN;
            else
                erorr("Unrecognized flight segment type.")
            end

            % Note that this update fuel_burned to inclue payload deploye now
            fuel_burned = W_IN * (1 - WF);
            W_OUT = W_IN*WF;
        end
        function WF = Cruise_WF(obj, L2D, h, M, plane)
            [~, a, ~, ~, ~] = queryAtmosphere(h, [0 1 0 0 0]);
            V = M * a;
            
            [~, TSFC, ~, ~] = plane.calcProp(M, h, 0); % No AB
            WF = exp( -(obj.input*TSFC) / (V*L2D) ); % input distance is in meters
        end
        function WF = Loiter_WF(obj, LD, h, M, plane)
            [~, TSFC, ~, ~] = plane.calcProp(M, h, 0); % No AB
            WF = exp( (-60*obj.input*TSFC/LD) ); % input time is in minutes
        end
    end
end
