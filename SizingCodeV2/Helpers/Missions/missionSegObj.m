classdef missionSegObj < handle
   properties
        type
        % 'TAKEOFF' 'CLIMB' 'CRUISE' 'LOITER' 'COMBAT' 'LANDING'
        do_search % wether to search optimum lotier/cruise conditions
        N_split % number of times to divde divisible sections

        h
        h_specified

        vel
        vel_specified

        mach
        mach_specified

        distance
        time
        throttle_override
        load_factor
   end
   methods
      function obj = missionSegObj(type, opts)
          % GOAL: Make sure the user passed in all the correct arguments and set all the defaults
        arguments
            type    string
            opts.do_search  logical = true
            opts.h          double  = missing
            opts.vel        double  = missing
            opts.mach       double  = missing
            opts.distance   double  = missing
            opts.time       double  = missing
            opts.throttle_override double = 0
            opts.load_factor       double = 1
            opts.N_split    int16 = 10
        end
        
         obj.type = type;
         obj.N_split = opts.N_split;
         obj.do_search = opts.do_search;
         obj.h_specified = ~ismissing(opts.h);
         obj.load_factor = opts.load_factor;
         obj.throttle_override = opts.throttle_override;

         h_default = 0;
         vel_default = 0;

         % note that takeoff, climb, and landing currently do not have additional inputs
         switch(type)
             case 'TAKEOFF'
                h_default = ft2m(100); vel_default = kt2ms(145);
             case 'CLIMB'
                h_default = ft2m(10000); vel_default = kt2ms(250);
             case 'CRUISE'
                 h_default = ft2m(30000); vel_default = kt2ms(300);
                 if ismissing(opts.distance)
                    error("Cruise requires distance specification")
                 end
                 obj.distance = opts.distance; % MUST be defined as no default check
             case 'LOITER'
                 h_default = ft2m(30000); vel_default = kt2ms(300);
                 if ismissing(opts.time)
                    error("Cruise requires time specification")
                 end
                 obj.time = opts.time; % seconds
             case 'COMBAT'
                 h_default = ft2m(1000); vel_default = kt2ms(500);
                 if ismissing(opts.time)
                    error("Combat requires time specification")
                 end
                 obj.time = opts.time; % seconds
                 % can set load_factor and throttle_override
             case 'LANDING'
                h_default = ft2m(100); vel_default = kt2ms(145);
             otherwise
                 error('%s is not a recognized mission type', obj.type)
                
         end

         obj.checkDefault(opts, 'h', h_default);
         [~, a, ~, ~, ~] = queryAtmosphere(obj.h, [0 1 0 0 0]);

         % NOTE THAT IF do_search is enabled, combat/cruise/loiter search behavior depends on what was specified
         if ~ismissing(opts.vel)
            % velocity was defined
            obj.vel = opts.vel; % m/s
            obj.mach = obj.vel / a;

            obj.vel_specified = true;
            obj.mach_specified = false;
         elseif ~ismissing(opts.mach)
            % mach number was defined
            obj.mach = opts.mach;
            obj.vel = obj.mach * a; % m/s

            obj.vel_specified = false;
            obj.mach_specified = true;
         else
            % use default velocity
            obj.checkDefault(opts, 'vel', vel_default); % m/s
            obj.mach = obj.vel / a;

            obj.vel_specified = false;
            obj.mach_specified = false;
         end
      end
      function is_specified = checkDefault(obj, opts, name, default_val)
            % got opts.note_specified
            if ismissing(opts.(name))
                obj.(name) = default_val;
                is_specified = false;
            else
            obj.(name) = opts.(name);
                    is_specified = true;
            end
        end
        function [W_out, h_out, v_out, d_out] = evaluate(obj, perf, W_in)
            % INPUT: The performance obj (and the missionSeg object)
            % OUTPUTS: W, h, v, d (reative to start). These can be column vectors if it the seg
            h_out = obj.h; v_out = obj.vel; d_out = v_out * 60; % default vals if not set
            switch(obj.type)
                case 'TAKEOFF'
                    W_out = 0.97 * W_in;
                case 'CLIMB'
                    W_out = 0.985 * W_in;
                case 'CRUISE'
                    [W_out, h_out, v_out, d_out] = obj.evaluate_split(@(perf, W_in, distance) obj.evaluate_cruise(perf, W_in, distance), perf, W_in, obj.distance);
                case 'LOITER'
                    [W_out, h_out, v_out, d_out] = obj.evaluate_split(@(perf, W_in, distance) obj.evaluate_loiter(perf, W_in, distance), perf, W_in, obj.time);
                case 'COMBAT'
                    [W_out, h_out, v_out, d_out] = obj.evaluate_split(@(perf, W_in, distance) obj.evaluate_combat(perf, W_in, distance), perf, W_in, obj.time);
                case 'LANDING'
                    W_out = 0.995 * W_in;
            end
        end
        function [W_out, h_out, v_out, d_out] = evaluate_split(obj, fun, perf, W_in, split_input)
            % evaluats fun N times advancing it forward as needed and dividing up split_input
            W_out = zeros([obj.N_split, 1]); h_out = W_out; v_out = W_out; d_out = W_out;

            prev_d = 0; % need to track distance increase
            for i = 1:obj.N_split
                % running this function will update perf to be the optimal/set for the mission
                time = fun(perf, W_in, split_input / cast(obj.N_split,"double")); % having issues with integer def carrying
                    % return the seconds spent at that condtion
                h_out(i) = perf.model.cond.h.v; v_out(i) = perf.model.cond.vel.v;

                W_out(i) = W_in - perf.model.settings.g_const * perf.mdotf * time;
                W_in = W_out(i);
                d_out(i) = time * perf.model.cond.vel.v + prev_d; % add previous distance
                prev_d = d_out(i); % update
            end
        end
        function time = evaluate_cruise(obj, perf, W_in, distance)
            % distance is taken out from split section
            fun = @(perf) perf.mdotf ./ perf.model.cond.vel.v; % best cruise when this is minimized
                % must be vectorized since we do a grid search for X0
            perf = obj.set_cond_opt(perf, W_in, fun);
            time = distance / perf.model.cond.vel.v;
        end
        function time = evaluate_loiter(obj, perf, W_in, time)
            fun = @(perf) perf.mdotf; % best cruise when this is minimized
            perf = obj.set_cond_opt(perf, W_in, fun);
        end
        function time = evaluate_combat(obj, perf, W_in, time)
            if(obj.throttle_override==0) % fly at best turn rate
                fun = @(perf) 1./perf.TurnRate; % best combat when this is minimized
            else % fly at max excess power as it is now non zero
                fun = @(perf) 1./perf.ExcessPower; % best combat when this is minimized
            end 
            perf = obj.set_cond_opt(perf, W_in, fun);
        end
        function perf = set_cond_opt(obj, perf, W_in, fun)
            % NOTE THAT WE ARE NOT RETURNING A COPY OF PERF
            % We are modifying it in memory and returning it
            perf.clear_data();
            % set the condition to the current defaults. This will end up saving h, v, M if they are not being set fo reference
            starting_cond = P_Specified_Condition(perf, 0, obj.h, obj.vel, W_in, perf.model.settings.codes.MV_DEC_VEL, obj.load_factor);
            perf.model.cond = starting_cond;
            % return the set performance object with the optimal condition to minimzie the given function. Given x0 [h, vel]
            if obj.do_search && (~obj.h_specified || (~obj.vel_specified && ~obj.mach_specified))
                % just for readability here:
                do_h_opt = ~obj.h_specified; do_vel_opt = ~obj.vel_specified; do_mach_opt = ~obj.mach_specified && ~obj.vel_specified;

                % Remeber: X values are scaled in their functions so X0 is not the physical starting values
                if(do_h_opt)
                    if(do_vel_opt)
                        X0 = [1, 1];
                        fun_mod = @(X) fun_hv(fun, perf, X, obj.throttle_override);
                    elseif(do_mach_opt)
                        X0 = [1, 1];
                        fun_mod = @(X) fun_hM(fun, perf, X, obj.throttle_override);
                    else % just altitude
                        X0 = 1;
                        fun_mod = @(X) fun_h(fun, perf, X, obj.throttle_override);
                    end
                else
                    if(do_vel_opt)
                        X0 = 1;
                        fun_mod = @(X) fun_v(fun, perf, X, obj.throttle_override);
                    else % must be mach opt
                        X0 = 1;
                        fun_mod = @(X) fun_M(fun, perf, X, obj.throttle_override);
                    end
                end

                % Make a vector of X to find optimum in grid to seed initial point
                N = 30;
                X0_temp = linspace(0.2, 3, N);
                if ~isscalar(X0) % need to do meshgrid
                    [X0_1, X0_2] = meshgrid(X0_temp, X0_temp);
                    X0 = [X0_1(:)' ; X0_2(:)'];
                else
                    X0 = X0_temp; % row vectors
                end

                grid_out = fun_mod(X0); % evaluate on the grid
                [~, idx] = min(grid_out); % get the row with the lowest value (closest to optimum)
                X0 = X0(:, idx); % overwrite X0 to that value

                perf.model.cond = starting_cond; % grid eval usally modifies the condition so we need to reset it

                % so as insane as it is, we don't need to extract the optimum. perf stays passed as its memory position
                % so when fminunc returns, it will have modified perf
                options = optimoptions(@fminunc,'Display','off');
                fminunc(fun_mod, X0, options);
            end 
            % else we already set the default and just keep that
        end
    end
end

% we add scalers to X to make the magnitudes similar for more stable convergence
% since all we need to do is modify the perf value, the actual X magnitude does not matter
function out = fun_h(fun, perf, X, throttle_override) % Only altitude
    set_condition(perf, 3000 * X, perf.model.cond.vel.v, perf.model.settings.codes.MV_DEC_VEL, throttle_override);
    out = fun(perf) + penalize(perf);
end
function out = fun_v(fun, perf, X, throttle_override) % Only velocity
    set_condition(perf, perf.model.cond.h.v, 100 * X, perf.model.settings.codes.MV_DEC_VEL, throttle_override);
    out = fun(perf) + penalize(perf);
end
function out = fun_M(fun, perf, X, throttle_override) % Only mach number
    set_condition(perf, perf.model.cond.h.v, 0.5 * X, perf.model.settings.codes.MV_DEC_MACH, throttle_override);
    out = fun(perf) + penalize(perf);
end
function out = fun_hv(fun, perf, X, throttle_override) % Both altitude and velocity
    set_condition(perf, 3000 * X(1, :), 100 * X(2, :), perf.model.settings.codes.MV_DEC_VEL, throttle_override);
    out = fun(perf) + penalize(perf);
end
function out = fun_hM(fun, perf, X, throttle_override) % Both altitude and mach number
    set_condition(perf, 3000 * X(1, :), 0.5 * X(2, :), perf.model.settings.codes.MV_DEC_MACH, throttle_override);
    out = fun(perf) + penalize(perf);
end
function set_condition(perf, h, M_vel, MV_DEC, throttle_override, W, n)
    if nargin < 6
        W = perf.model.cond.W.v;
    end
    if nargin < 7
        n = perf.model.cond.n.v;
    end
    perf.clear_data();
    if(throttle_override==0) % no override
        perf.model.cond = P_Specified_Condition(perf, 0, h, M_vel, W, MV_DEC, n);
    else
        % for combat where we set the throttle
        perf.model.cond = generateCondition(perf.model.geom, h, M_vel, n, W, throttle_override, perf.model.cond, MV_DEC);
    end
end
function out = penalize(perf)
    % return some penalty of the current perf
    h_limits = [ft2m(100), 30000];
    g1 = 1 - perf.model.cond.h.v/h_limits(1);
    g2 = perf.model.cond.h.v/h_limits(2) - 1;
    g3 = - perf.ExcessPower / 10; % Excess power MUST be positive (usally is 0 to machine precision)
    out = 100 * max([zeros(size(g1)) ; g1 ; g2 ; g3]); % properly deals with vector conditions
end