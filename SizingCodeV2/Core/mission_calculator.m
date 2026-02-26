classdef mission_calculator < handle

    properties
        perf
        data
        record_hist = false
        do_print = false
        hist
        dF_dh_prev = 0
        dF_dv_prev = 0
        grad_alpha  = 0.25
    end

    methods
        function obj = mission_calculator(perf)
            obj.perf = perf;
            obj.perf.model.cond = buildDefaultCondStruct(); % so that the first call of generateCondition has the default
            obj.hist = struct();
        end

        function init_hist(obj)
            obj.hist.h           = [];
            obj.hist.v           = [];
            obj.hist.W           = [];
            obj.hist.d           = [];
            obj.hist.t           = [];
            obj.hist.throttle    = [];
            obj.hist.climb_angle = [];
            obj.hist.dF_dh       = [];
            obj.hist.dF_dv       = [];
            obj.hist.mdotf       = [];
            obj.hist.TSFC        = [];
            obj.hist.F           = [];
        end

        function [hf, vf, Wf] = solve_section(obj, h0, v0, W0, section_def)
            total_range = nm2m(2000);
            % fun = obj.getFun(1, [NaN NaN], [NaN 180], [NaN 3000]);
            fun = obj.getFun(1, [NaN NaN], [NaN NaN], [NaN NaN]);

            hi = h0; vi = v0; Wi = W0; di = 0; ti = 0; theta_i = 0; ang_rate = 0;
            i_limit = 5000;
            dt = 5;

            if obj.record_hist
                obj.init_hist();
            end

            incr = 1.618; dt_max = 200; dt_min = 2; 
            climb_limit_lower = 3; climb_limit_upper = 40;

            i = 0; S = 0;
            while i < i_limit && S < 1
                i = i + 1;
                S = di / total_range;
                h_prev = hi;
                [hi, vi, Wi, di, ti] = obj.take_step(hi, vi, Wi, di, ti, dt, fun, S);

                if abs(h_prev - hi) < climb_limit_lower
                    dt = dt * incr;
                elseif abs(h_prev - hi) > climb_limit_upper
                    dt = dt / incr;
                end
                dt = max(dt_min, min(dt_max, dt));
                
                if obj.do_print
                    fprintf("dt = %.4g , ang_rate = %.4g , vi = %.4g, i = %i\n", dt, ang_rate, vi, i)
                end
            end

            fprintf("Final distance: %.4f\n", di)
            fprintf("Iteration count: %i\n", i)

            hf = hi; vf = vi; Wf = Wi;
        end

        function perf = adjustPerf(obj, h, v, W)
            obj.perf.model.clear_mem(); obj.perf.clear_data();
            obj.perf.model.cond = levelFlightCondition(obj.perf, h, v, W);
            perf = obj.perf;
        end

        function [hi, vi, Wi, di, ti, dF_dh, dF_dv] = take_step(obj, hi, vi, Wi, di, ti, dt, fun, S)
            angle_max = 10;
            dh = 10;
            dv = 5;

            % Smoothing these values helps quite a bit with both numerical stability and contuity with adaptive time stepping
            % Back to forward differencing from center to cut down on calls
            P_center = obj.adjustPerf(hi, vi, Wi);
            F_center = fun(P_center, S);
            dF_dh_raw = ( fun(obj.adjustPerf(hi+dh, vi, Wi), S) - F_center ) / dh;
            dF_dv_raw = ( fun(obj.adjustPerf(hi, vi+dv, Wi), S) - F_center ) / dv;

            dF_dh = obj.grad_alpha * dF_dh_raw + (1 - obj.grad_alpha) * obj.dF_dh_prev;
            dF_dv = obj.grad_alpha * dF_dv_raw + (1 - obj.grad_alpha) * obj.dF_dv_prev;

            obj.dF_dh_prev = dF_dh;
            obj.dF_dv_prev = dF_dv;

            % dh_damp = 1E-5; % When less than this it stops using max climb
            % dv_damp = 5E-3;% When less than this it stops going to max/min throttle
            dh_damp = 1E-11;
            dv_damp = 5E-8;

            % Squaring gets batter damping when near optimum
            target_climb_angle = -angle_max * min(1, dF_dh^2/dh_damp) * sign(dF_dh);
            PE_target = vi * sind(target_climb_angle);

            cond = P_Specified_Condition(obj.perf, PE_target, hi, vi, Wi);
            climbing_throttle = cond.throttle.v;

            
            if dF_dv > 0
                throttle = climbing_throttle * max(1 - dF_dv^2/dv_damp, 0);
            else
                throttle = climbing_throttle + (1 - climbing_throttle) * min(1, dF_dv^2/dv_damp);
            end

            throttle = max(throttle, 0); % make sure it does not go under 0

            cond = generateCondition(obj.perf.model.geom, hi, vi, 1, Wi, throttle, obj.perf.model.cond);
            obj.perf.model.cond = cond;

            climb_angle = obj.perf.ClimbAngle(obj.perf.ExcessPower - PE_target);

            hi = hi + cond.vel.v * sind(climb_angle) * dt;
            vi = vi + obj.perf.AxialAccelleration(PE_target) * obj.perf.model.settings.g_const * dt;
            Wi = Wi - obj.perf.model.settings.g_const * obj.perf.mdotf * dt;
            di = di + vi * dt;
            ti = ti + dt;

            if obj.record_hist
                obj.hist.h(end+1)           = hi;
                obj.hist.v(end+1)           = vi;
                obj.hist.W(end+1)           = Wi;
                obj.hist.d(end+1)           = di;
                obj.hist.t(end+1)           = ti;
                obj.hist.throttle(end+1)    = throttle;
                obj.hist.climb_angle(end+1) = climb_angle;
                obj.hist.dF_dh(end+1)       = dF_dh;
                obj.hist.dF_dv(end+1)       = dF_dv;
                obj.hist.mdotf(end+1)       = obj.perf.mdotf;
                obj.hist.TSFC(end+1)        = obj.perf.TSFC;
                obj.hist.F(end+1)        = fun( obj.adjustPerf(hi, vi, Wi), S );
            end
        end

        function plot_hist(obj)
            assert(obj.record_hist, "record_hist is false — no data was recorded");
            d_km = obj.hist.d / 1000;

            figure('Name', 'Mission History');
            subplot(3,3,1); plot(d_km, obj.hist.h);            xlabel('Range [km]'); ylabel('h [m]');    title('Altitude');       grid on;
            subplot(3,3,2); plot(d_km, obj.hist.v);            xlabel('Range [km]'); ylabel('v [m/s]');  title('Velocity');       grid on;
            subplot(3,3,3); plot(d_km, obj.hist.W);            xlabel('Range [km]'); ylabel('W [N]');    title('Weight');         grid on;
            subplot(3,3,4); plot(d_km, obj.hist.throttle);     xlabel('Range [km]'); ylabel('-');        title('Throttle');       grid on;
            subplot(3,3,5); plot(d_km, obj.hist.climb_angle);  xlabel('Range [km]'); ylabel('deg');      title('Climb Angle');    grid on;
            subplot(3,3,6); plot(d_km, obj.hist.F);            xlabel('Range [km]'); ylabel('-');        title('F');           grid on;
            subplot(3,3,7); plot(d_km, obj.hist.TSFC);         xlabel('Range [km]'); ylabel('-');        title('TSFC');           grid on;
            subplot(3,3,8); plot(d_km, obj.hist.dF_dh);        xlabel('Range [km]'); ylabel('-');        title('dF/dh');          grid on;
            subplot(3,3,9); plot(d_km, obj.hist.dF_dv);        xlabel('Range [km]'); ylabel('-');        title('dF/dv');          grid on;
        end

        function fun = getFun(obj, type, mach_const, vel_cost, alt_const)
            switch type
                case 1
                    fun_obj = @(P) 1E2 * P.mdotf ./ P.model.cond.vel.v;
                case 2
                    fun_obj = @(P) P.mdotf;
                otherwise
                    error("Given mission type: %i is not a defined type.", type)
            end

            if any(~isnan(mach_const)) && any(~isnan(vel_cost))
                error("Cannot have both a mach number and velocity constraint active")
            end

            min_alt = 100; % Make sure we don't hit the ground
            fun_const = @(P, S) 1E-4 * max(0, (min_alt - P.model.cond.h.v)/min_alt);

            R = 1E-4;

            if ~isnan(alt_const(1))
                if ~isnan(alt_const(2))
                    fun_const = @(P, S) fun_const(P, S) + R * pseduo_huber((1-S)*alt_const(1) + S*alt_const(2), P.model.cond.h.v, 1E3);
                else
                    fun_const = @(P, S) fun_const(P, S) + R * pseduo_huber(alt_const(1), P.model.cond.h.v, 1E3);
                end
            else
                if ~isnan(alt_const(2))
                    % S^2 helps it stay free at the start and then quickly go to the constraint at the end
                    fun_const = @(P, S) fun_const(P, S) + S * S * R * pseduo_huber(alt_const(2), P.model.cond.h.v, 1E3);
                end
            end

            if ~isnan(vel_cost(1))
                if ~isnan(vel_cost(2))
                    fun_const = @(P, S) fun_const(P, S) + R * pseduo_huber((1-S)*vel_cost(1) + S*vel_cost(2), P.model.cond.vel.v, 1E3);
                else
                    fun_const = @(P, S) fun_const(P, S) + R * pseduo_huber(vel_cost(1), P.model.cond.vel.v, 1E3);
                end
            else
                if ~isnan(vel_cost(2))
                    % S^2 helps it stay free at the start and then quickly go to the constraint at the end
                    fun_const = @(P, S) fun_const(P, S) + S * S * R * pseduo_huber(vel_cost(2), P.model.cond.vel.v, 1E3);
                end
            end

            if ~isnan(mach_const(1))
                if ~isnan(mach_const(2))
                    fun_const = @(P, S) fun_const(P, S) + R * pseduo_huber((1-S)*mach_const(1) + S*mach_const(2), P.model.cond.M.v, 1E3);
                else
                    fun_const = @(P, S) fun_const(P, S) + R * pseduo_huber(mach_const(1), P.model.cond.M.v, 1E3);
                end
            else
                if ~isnan(mach_const(2))
                    % S^2 helps it stay free at the start and then quickly go to the constraint at the end
                    fun_const = @(P, S) fun_const(P, S) + S * S * R * pseduo_huber(mach_const(2), P.model.cond.M.v, 1E3);
                end
            end

            fun = @(P, S) fun_obj(P) + fun_const(P, S);
        end
    end
end

function out = pseduo_huber(x_target, x_current, scale)
    out = scale * (sqrt(1 + ((x_current - x_target)/scale)^2) - 1);
end