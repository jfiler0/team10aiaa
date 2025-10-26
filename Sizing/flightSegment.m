classdef flightSegment
    properties
        type

        h
        M
        % Either or both can be left as NaN and it will sove for 
        % optimum for the configuration for CRUISE & LOITER

        Cd0
        input
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
            % TSFC = queryTSFC(obj.h, obj.M, plane.engine);
            % [q, V, a, rho] = metricFreestream(h, M)
            % LD = 1 / ( (q*obj.Cd0) / (W_IN/plane.S) + (W_IN/plane.S) / (q * pi * plane.e * plane.AR) );

            if(obj.type == "TAKEOFF")
                WF = 0.95;
            elseif(obj.type == "LANDING")
                WF = 0.995;
            elseif(obj.type == "CLIMB")
                WF = 1.0065 - 0.0325*obj.M;
                % W_out = W_in*WF;
                % fuel_burned = W_in - W_out;
            elseif(obj.type == "CRUISE")
                % input distance is in meters
                [LD, h, M, V] = findOptimalFlightCond(obj, W_IN, plane);
                TSFC = queryTSFC(h, M, plane.engine);
                WF = exp( -(obj.input*TSFC) / (V*LD) );
            elseif(obj.type == "LOITER")
                % input time is in minutes
                [LD, h, M, ~] = findOptimalFlightCond(obj, W_IN, plane);
                WF = exp( (-60*obj.input*queryTSFC(h, M, plane.engine)/LD) );
            elseif(obj.type == "COMBAT")
                TA0 = engineLookup(plane.engine); %TA at sealevel
                alpha = find_lapse_rate(obj.h, obj.M, 1); % full ab
                TA = TA0*alpha;

                % TSFC is in kg/Ns, input time is in minutes
                fuel_burned = 60*obj.input(1)*queryTSFC(obj.h, obj.M, plane.engine)*TA;
                
                W_OUT = W_IN - fuel_burned - obj.input(2);
                WF = W_OUT/W_IN;
            else
                erorr("Unrecognized flight segment type.")
            end

            fuel_burned = W_IN * (1 - WF);
            W_OUT = W_IN*WF;
        end
        function [LD, h, M, V] = findOptimalFlightCond(obj, W_IN, plane)
            % Define lift and drag polars in terms of q
            Cl = @(q) abs(W_IN) ./ (q*plane.S); % abs to be robust to negative W_IN
            Cd = @(q) Cl(q).^2 ./ (pi*plane.e*plane.AR) + obj.Cd0;
        
            % Objective function selector
            switch obj.type
                case "CRUISE"   % maximize range ~ CL / CD^2
                    f = @(q) -(Cl(q) ./ (Cd(q).^2));
                case "LOITER"   % maximize endurance ~ CL / CD
                    f = @(q) -(Cl(q) ./ Cd(q));
                otherwise
                    error("Not a recognized flight condition.")
            end
        
            % Pick a practical q search range [N/m^2]
            q_min = 100;     % avoids div by zero
            q_max = 50000;   % ~ Mach 1 at sea level
            q_opt = fminbnd(f, q_min, q_max);
        
            % Now back out LD
            LD = Cl(q_opt) ./ Cd(q_opt);
        
            % Back-solve Mach or h depending on what’s free
            if isnan(obj.M) && ~isnan(obj.h)
                % altitude fixed, solve for Mach
                [~, a, ~, rho, ~] = queryAtmosphere(obj.h, [0 1 0 1 0]);
                M = sqrt(2*q_opt/rho) / a;
                V = M*a;
                h = obj.h;
            elseif isnan(obj.h) && ~isnan(obj.M)
                % Mach fixed, solve for altitude
                h_guess = linspace(0, 20000, 200);  % m
                q_vals = zeros(size(h_guess));
                for k = 1:numel(h_guess)
                    [~, a, ~, rho, ~] = queryAtmosphere(h_guess(k), [0 1 0 1 0]);
                    V = obj.M*a;
                    q_vals(k) = 0.5*rho*V^2;
                end
                [~, idx] = min(abs(q_vals - q_opt));
                h = h_guess(idx);
                M = obj.M;
            else
                h = obj.h;
                M = obj.M;
                [q, V, ~, ~] = metricFreestream(h, M);
                LD = 1 / ( (q*obj.Cd0) / (W_IN/plane.S) + (W_IN/plane.S) / (q * pi * plane.e * plane.AR) );
            end
        end

    end
end
