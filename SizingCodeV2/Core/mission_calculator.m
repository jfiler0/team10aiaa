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
        t = 0 % track current time (globally)
        d = 0 % track global distance
    end

    methods
        function obj = mission_calculator(perf)
            obj.perf = perf;
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
            obj.hist.segment_name= string.empty(0,1);
        end

        function out = solve_mission(obj, mission)
            % mission object must be read from readMissionStruct function and built using a combination of missionSeg
            % the starting condition is buried in obj.perf.cond

            % reset these vaues
            obj.t = 0;
            obj.d = 0;

            if obj.record_hist
                obj.init_hist();
            end

            for i = 1:length(mission.data)
                obj.solve_section(mission.data(i));
            end

        end

        function [hf, vf, Wf] = solve_section(obj, segment)
            type = segment.type.v

            if type == 'FIXED_WF'
                disp("Implement!")
            else
                fun = getFun(segment);
    
                hi = obj.perf.model.cond.h.v; vi = obj.perf.model.cond.vel.v; Wi = obj.perf.model.cond.W.v; di = 0; ti = 0; ang_rate = 0;
                i_limit = 5000;
                dt = 5;
    
                incr = 1.618; dt_max = 200; dt_min = 2; 
                climb_limit_lower = 3; climb_limit_upper = 40;
    
                i = 0; S = 0;
                while i < i_limit && S < 1
                    i = i + 1;
    
                    % Compute how far we have gotten into the segment
                    switch type
                        case 'CRUISE'
                            S = di / segment.distance.v;
                        case 'LOITER'
                            S = ti / (segment.time.v * 60 ); % converting from minutes to seconds here
                        otherwise
                            error("Given mission type: %i is not a defined type.", type)
                    end
                    
                    h_prev = hi;
                    [hi, vi, Wi, di, ti] = obj.take_step(hi, vi, Wi, di, ti, dt, fun, S, segment.name.v);
    
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
        end

        function perf = adjustPerf(obj, h, v, W)
            obj.perf.model.clear_mem(); obj.perf.clear_data();
            obj.perf.model.cond = levelFlightCondition(obj.perf, h, v, W);
            perf = obj.perf;
        end

        function [hi, vi, Wi, di, ti, dF_dh, dF_dv] = take_step(obj, hi, vi, Wi, di, ti, dt, fun, S, seg_name)
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
            dh_damp = 2E-4;
            dv_damp = 2E-2;

            % Squaring gets batter damping when near optimum
            target_climb_angle = -angle_max * min(1, (dF_dh/dh_damp)^2 ) * sign(dF_dh);
            PE_target = vi * sind(target_climb_angle);

            cond = P_Specified_Condition(obj.perf, PE_target, hi, vi, Wi);
            climbing_throttle = cond.throttle.v;

            
            if dF_dv > 0
                throttle = climbing_throttle * max(1 - (dF_dv/dv_damp)^2, 0);
            else
                throttle = climbing_throttle + (1 - climbing_throttle) * min(1, (dF_dv/dv_damp)^2 );
            end

            throttle = max(throttle, 0); % make sure it does not go under 0

            cond = generateCondition(obj.perf.model.geom, hi, vi, 1, Wi, throttle, obj.perf.model.cond);
            obj.perf.model.cond = cond;

            climb_angle = obj.perf.ClimbAngle(obj.perf.ExcessPower - PE_target);

            hi = hi + cond.vel.v * sind(climb_angle) * dt;
            vi = vi + obj.perf.AxialAccelleration(PE_target) * obj.perf.model.settings.g_const * dt;
            Wi = Wi - obj.perf.model.settings.g_const * obj.perf.mdotf * dt;
            
            di = di + vi * dt;
            obj.d = obj.d + vi * dt;
            
            ti = ti + dt;
            obj.t = obj.t + dt;

            if obj.record_hist
                obj.hist.h(end+1)           = hi;
                obj.hist.v(end+1)           = vi;
                obj.hist.W(end+1)           = Wi;
                obj.hist.d(end+1)           = obj.d;
                obj.hist.t(end+1)           = obj.t; % using this is the global time instead of the local seg
                obj.hist.throttle(end+1)    = throttle;
                obj.hist.climb_angle(end+1) = climb_angle;
                obj.hist.dF_dh(end+1)       = dF_dh;
                obj.hist.dF_dv(end+1)       = dF_dv;
                obj.hist.mdotf(end+1)       = obj.perf.mdotf;
                obj.hist.TSFC(end+1)        = obj.perf.TSFC;
                obj.hist.F(end+1)           = fun( obj.adjustPerf(hi, vi, Wi), S );
                obj.hist.segment_name(end+1)= seg_name;
            end
        end

        function plot_hist(obj)
            assert(obj.record_hist, "record_hist is false — no data was recorded");
            
            % Prepare data
            d_km = obj.hist.d / 1000;
            
            % Get unique segments and assign colors
            [unique_segments, ~, segment_idx] = unique(obj.hist.segment_name, 'stable');
            colors = lines(length(unique_segments));
            
            % Define plot specifications
            plots = {
                obj.hist.h,            'Range [km]', 'h [m]',        'Altitude';
                obj.hist.v,            'Range [km]', 'v [m/s]',      'Velocity';
                obj.hist.W,            'Range [km]', 'W [N]',        'Weight';
                obj.hist.throttle,     'Range [km]', '-',            'Throttle';
                obj.hist.climb_angle,  'Range [km]', 'deg',          'Climb Angle';
                obj.hist.F,            'Range [km]', '-',            'F';
                obj.hist.TSFC,         'Range [km]', 'kg/(N*s)',     'TSFC';
                obj.hist.dF_dh,        'Range [km]', '-',            'dF/dh';
                obj.hist.dF_dv,        'Range [km]', '-',            'dF/dv'
            };
            
            % Create figure
            figure('Name', 'Mission History');
            
            % Plot each subplot
            for i = 1:size(plots, 1)
                subplot(3, 3, i);
                plot_segmented_data(d_km, plots{i,1}, segment_idx, colors, unique_segments);
                xlabel(plots{i,2});
                ylabel(plots{i,3});
                title(plots{i,4});
                grid on;
                axis tight;
                ylim_percentile(plots{i,1}, 99);
                
                % Add legend only to first subplot
                if i == 1
                    legend(unique_segments, 'Location', 'best', 'FontSize', 8);
                end
            end
        end
    end
end

function out = pseduo_huber(x_target, x_current, scale)
    out = scale * (sqrt(1 + ((x_current - x_target)/scale)^2) - 1);
end

function plot_segmented_data(x, y, segment_idx, colors, segment_names)
    % Plot data with different colors for each segment
    hold on;
    for seg = 1:length(segment_names)
        idx = segment_idx == seg;
        
        % Include last point from previous segment to connect
        if seg > 1
            prev_idx = find(segment_idx == seg-1, 1, 'last');
            if ~isempty(prev_idx)
                idx(prev_idx) = true;
            end
        end
        
        plot(x(idx), y(idx), 'Color', colors(seg,:), 'LineWidth', 1.5, 'DisplayName', segment_names{seg});
    end
    hold off;
end

function ylim_percentile(data, percentile)
    % Set y-limits to capture specified percentile of data
    if isempty(data) || all(isnan(data))
        return;
    end
    
    valid_data = data(~isnan(data) & ~isinf(data));
    if isempty(valid_data)
        return;
    end
    
    lower = prctile(valid_data, (100-percentile)/2);
    upper = prctile(valid_data, percentile + (100-percentile)/2);
    
    % Add 5% margin
    range = upper - lower;
    if range > 0
        ylim([lower - 0.05*range, upper + 0.05*range]);
    end
end

function fun = getFun(segment)
    % Return an anomouys function which takes P the current performance and S the state from 0 to 1
    % The fact that we need ismissing instead of isnan is an annoying relaity of needing to read json files

    switch segment.type.v
        % need scalers so the two functions are kinda near eachother
        % Goal is to minimize these functions
        case 'CRUISE'
            fun_obj = @(P) ( P.mdotf ./ P.model.cond.vel.v ) * ( 200 / 0.3 );
        case 'LOITER'
            fun_obj = @(P) P.mdotf / 0.3;
        otherwise
            error("Given mission type: %i is not a defined type.", type)
    end

    if ( ~ismissing(segment.vel_start) || ~ismissing(segment.vel_end) ) && ( ~ismissing(segment.M_start) || ~ismissing(segment.M_end) )
        warning("Having both mach and velocity constraints active is not recommended");
    end

    min_alt = 100; % Make sure we don't hit the ground
    fun_const = @(P, S) 1E-3 * max(0, (min_alt - P.model.cond.h.v)/min_alt);

    R = 1E-3; % changes how much objective is penalized due to the constraints

    a = 0.75; % When the tail constraint activates

    if ~ismissing(segment.h_start)
        if ~ismissing(segment.h_end)
            fun_const = @(P, S) fun_const(P, S) + R * pseduo_huber((1-S)*segment.h_start + S*segment.h_end, P.model.cond.h.v, 1E3);
        else
            fun_const = @(P, S) fun_const(P, S) + R * pseduo_huber(segment.h_start, P.model.cond.h.v, 1E3);
        end
    else
        if ~ismissing(segment.h_end)
            % S^2 helps it stay free at the start and then quickly go to the constraint at the end
            fun_const = @(P, S) fun_const(P, S) + ( max( S-a, 0)/(1-a) )^2 * R * pseduo_huber(segment.h_end, P.model.cond.h.v, 1E3);
        end
    end

    

    if ~ismissing(segment.vel_start)
        if ~ismissing(segment.vel_end)
            fun_const = @(P, S) fun_const(P, S) + R * pseduo_huber((1-S)*segment.vel_start + S*segment.vel_end, P.model.cond.vel.v, 100);
        else
            fun_const = @(P, S) fun_const(P, S) + R * pseduo_huber(segment.vel_start, P.model.cond.vel.v, 100);
        end
    else
        if ~ismissing(segment.vel_end)
            % S^2 helps it stay free at the start and then quickly go to the constraint at the end
            fun_const = @(P, S) fun_const(P, S) + ( max( S-a, 0)/(1-a) )^2 * R * pseduo_huber(segment.vel_end, P.model.cond.vel.v, 100);
        end
    end

    if ~ismissing(segment.M_start)
        if ~ismissing(segment.M_end)
            fun_const = @(P, S) fun_const(P, S) + R * pseduo_huber((1-S)*segment.M_start + S*segment.M_end, P.model.cond.M.v, 1);
        else
            fun_const = @(P, S) fun_const(P, S) + R * pseduo_huber(segment.M_start, P.model.cond.M.v, 1);
        end
    else
        if ~ismissing(segment.M_end)
            % S^2 helps it stay free at the start and then quickly go to the constraint at the end
            fun_const = @(P, S) fun_const(P, S) + ( max( S-a, 0)/(1-a) )^2 * R * pseduo_huber(segment.M_end, P.model.cond.M.v, 1);
        end
    end

    fun = @(P, S) fun_obj(P) + fun_const(P, S);
end