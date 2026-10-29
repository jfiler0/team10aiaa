classdef flightSegment
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
        % COMBAT -> [Time, Payload] [min, N]
        % CLIMB -> NaN
        % LANDING -> NaN
        % TAKEOFF -> NaN

    end

    methods
        function obj = flightSegment(type, M, h, Cd0, input) 
            if nargin < 2, M = NaN; end
            if nargin < 3, h = NaN; end
            if nargin < 4, Cd0 = NaN; end
            if nargin < 5, input = NaN; end
        
            obj.type  = type;
            obj.h     = h;
            obj.M     = M;
            obj.Cd0   = Cd0;
            obj.input = input;

           % --- Validation checks for flight segment setup ---

            % Case 1: Cruise or Loiter must have at least one of M or h
            if isnan(M) && isnan(h) && ismember(obj.type, ["CRUISE","LOITER"])
                error("Cruise or loiter require either M or h be defined");
            end
            
            % Case 2: Cruise, Loiter, Combat all require extra input
            if all(isnan(obj.input)) && ismember(obj.type, ["CRUISE","LOITER","COMBAT"])
                error("Combat, cruise, and loiter require an additional input");
            end
            
            % Case 3: Combat requires both M and h defined
            if (isnan(M) || isnan(h)) && strcmp(obj.type, "COMBAT")
                error("Combat requires both M & h be defined");
            end
            
            % Case 4: Climb requires M defined
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
                if isnan(obj.M) && ~isnan(obj.h) % mach is free
                    fun = @(M) obj.Cruise_WF([M obj.h], W_IN, plane);
                    [M_opt, WF] = fminbnd(fun, M_bounds(1), M_bounds(2), options);
                    % fprintf("\nOptimal Mach for Cruise = %.4f", M_opt)
                elseif isnan(obj.h) && ~isnan(obj.M) % height is free
                    fun = @(h) obj.Cruise_WF([obj.M h], W_IN, plane);
                    [h_opt, WF] = fminbnd(fun, h_bounds(1), h_bounds(2), options);
                    % fprintf("\nOptimal altitude for Cruise = %.4f", h_opt)
                else % both are fixed
                    WF = obj.Cruise_WF([obj.M obj.h], W_IN, plane);
                end
            elseif(obj.type == "LOITER")
                if isnan(obj.M) && ~isnan(obj.h) % mach is free
                    fun = @(M) obj.Loiter_WF([M obj.h], W_IN, plane);
                    [M_opt, WF] = fminbnd(fun, M_bounds(1), M_bounds(2), options);
                    % fprintf("\nOptimal Mach for Loiter = %.4f", M_opt)
                elseif isnan(obj.h) && ~isnan(obj.M) % height is free
                    fun = @(h) obj.Loiter_WF([obj.M h], W_IN, plane);
                    [h_opt, WF] = fminbnd(fun, h_bounds(1), h_bounds(2), options);
                    % fprintf("\nOptimal altitude for Loiter = %.4f", h_opt)
                else % both are fixed
                    WF = obj.Loiter_WF([obj.M obj.h], W_IN, plane);
                end
            elseif(obj.type == "COMBAT")
                [TA, TSFC, ~] = engine_query(plane.engine, obj.M, obj.h, 1);% TSFC is in kg/Ns, input time is in minutes
                fuel_burned = 60*obj.input(1)*TSFC*TA;
                W_OUT = W_IN - fuel_burned - obj.input(2);
                WF = W_OUT/W_IN;
            else
                erorr("Unrecognized flight segment type.")
            end

            fuel_burned = W_IN * (1 - WF);
            W_OUT = W_IN*WF;
        end
        function WF = Cruise_WF(obj, in, W_IN, plane)
            % Making this vectorized for optimization
            M = in(1);
            h = in(2);

            [q, V, ~, ~] = metricFreestream(h, M);
            LD = 1 / ( (q*obj.Cd0) / (W_IN/plane.S) + (W_IN/plane.S) / (q * pi * plane.e * plane.AR) );

            [~, TSFC, ~] = engine_query(plane.engine, M, h, 0);
            WF = exp( -(obj.input*TSFC) / (V*LD) ); % input distance is in meters
        end
        function WF = Loiter_WF(obj, in, W_IN, plane)
            % Making this vectorized for optimization
            M = in(1);
            h = in(2);

            [q, V, ~, ~] = metricFreestream(h, M);
            LD = 1 / ( (q*obj.Cd0) / (W_IN/plane.S) + (W_IN/plane.S) / (q * pi * plane.e * plane.AR) );

            [~, TSFC, ~] = engine_query(plane.engine, M, h, 0);
            WF = exp( (-60*obj.input*TSFC/LD) ); % input time is in minutes
        end
    end
end
