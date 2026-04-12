classdef mission_calculator < handle

    properties
        perf
        perf_map
        settings
        data
        record_hist = false
        do_print = false
        hist
        mission
        dF_dh_prev = 0
        dF_dv_prev = 0
        grad_alpha  = 0.25

        % global variables to track
        h
        v
        W
        t = 0 % track current time (globally)
        d = 0 % track global distance
    end

    methods
        function obj = mission_calculator(perf, settings)
            obj.perf = perf;
            obj.settings = settings;
            obj.hist = struct();
        end

        function build_map(obj)
            v_vec = linspace(150, 500, 15);
            h_vec = linspace(0, ft2m(30000), 8);
            W_vec = linspace(obj.perf.model.geom.weights.empty.v, obj.perf.model.geom.weights.mtow.v, 5);
            EP_vec = linspace(-200, 200, 5);

            if W_vec(1) > W_vec(end)
                error("Weights have gone crazy and empty is now more than mtow")
            end
            
            perf = obj.perf;
            
            % Create 4D grid
            [V, H, W_grid, EP_grid] = ndgrid(v_vec, h_vec, W_vec, EP_vec);
            
            % Flatten for vectorized computation
            v_flat = V(:)';
            h_flat = H(:)';
            W_flat = W_grid(:)';
            EP_flat = EP_grid(:)';
            
            perf.model.cond = P_Specified_Condition(perf, EP_flat, h_flat, v_flat, W_flat);
            
            % Compute outputs and reshape to 4D grid
            Throttle_grid = reshape(perf.model.cond.throttle.v, size(V));
            TSFC_grid = reshape(perf.TSFC, size(V));
            mdotf_grid = reshape(perf.mdotf, size(V));
            ExcessThrust_grid = reshape(perf.ExcessThrust, size(V));
            ExcessPower_grid = reshape(perf.ExcessPower, size(V));
            MaxClimbAngle_grid = reshape(perf.ClimbAngle, size(V));
            
            % Create gridded interpolants
            obj.perf_map = struct();
            obj.perf_map.v_vec = v_vec;
            obj.perf_map.h_vec = h_vec;
            obj.perf_map.W_vec = W_vec;
            obj.perf_map.EP_vec = EP_vec;
            
            % Original maps with EP as input
            obj.perf_map.TSFC = griddedInterpolant({v_vec, h_vec, W_vec, EP_vec}, ...
                                                  TSFC_grid, 'linear', 'linear');
            obj.perf_map.mdotf = griddedInterpolant({v_vec, h_vec, W_vec, EP_vec}, ...
                                                   mdotf_grid, 'linear', 'linear');
            obj.perf_map.ExcessThrust = griddedInterpolant({v_vec, h_vec, W_vec, EP_vec}, ...
                                                           ExcessThrust_grid, 'linear', 'linear');
            obj.perf_map.ExcessPower = griddedInterpolant({v_vec, h_vec, W_vec, EP_vec}, ...
                                                          ExcessPower_grid, 'linear', 'linear');
            obj.perf_map.MaxClimbAngle = griddedInterpolant({v_vec, h_vec, W_vec, EP_vec}, ...
                                                            MaxClimbAngle_grid, 'linear', 'linear');
            obj.perf_map.Throttle = griddedInterpolant({v_vec, h_vec, W_vec, EP_vec}, ...
                                                            Throttle_grid, 'linear', 'linear');
            
            % This is slower - having to build two maps but oh well
            % Build a SECOND map with throttle on a regular grid
            throttle_vec = linspace(0, 1, 10);
            [V2, H2, W2_grid, T_grid] = ndgrid(v_vec, h_vec, W_vec, throttle_vec);
            
            v_flat2 = V2(:)';
            h_flat2 = H2(:)';
            W_flat2 = W2_grid(:)';
            throttle_flat2 = T_grid(:)';
            n_vec = ones(size(v_flat2));
            
            perf.model.clear_mem();
            perf.clear_data();
            perf.model.cond = generateCondition(perf.model.geom, h_flat2, v_flat2, ...
                                                n_vec, W_flat2, throttle_flat2);
            
            EP_grid2 = reshape(perf.ExcessPower, size(V2));
            
            % Now you can use griddedInterpolant properly
            obj.perf_map.ExcessPower_Throttle = griddedInterpolant({v_vec, h_vec, W_vec, throttle_vec}, ...
                                                          EP_grid2, 'linear', 'linear');
                        
            perf.model.clear_mem(); 
            perf.clear_data();
        end

        % function [W_end, total_distance] = solve_mission_simple(obj, mission, fuel_weight_start)
        %     % based on simplifications and assuming the aicraft is at the best conditions it can be at
        % 
        %     obj.t = 0;
        %     obj.d = 0;
        %     obj.h = h0;
        %     obj.v = v0;
        %     obj.W = obj.perf.model.geom.weights.empty.v + ...
        %         obj.perf.model.geom.weights.loaded.v + ...
        %         fuel_weight_start * obj.perf.model.geom.weights.max_fuel_weight.v;
        % 
        %     for i = 1:length(mission.data)
        %         obj.solve_section_simple(mission.data(i));
        %     end
        % 
        %     W_end = obj.W;
        %     total_distance = obj.d;
        % end
        % 
        % function solve_section_simple(obj, segment)
        %     % Any solve needs to have the altitude, velocity, and time/distance. That will then be saved
        % 
        %     if strcmp(segement.type, 'FIXED_WF') % easy just apply the scaler
        %         obj.W = obj.W * segment.WFi;
        %         dt = segment.time;
        %     else % there will be some type of constraint involved
        % 
        %         N = 10; % the number of times to divide up a section
        %         h_vec = []; % list of altitude to hit
        % 
        %         fun = obj.getFun(segment);
        % 
        %         if( ~isnan(segment.h_start) && ~isnan(segment.h_end) ) % both are already specified
        %             h_vec = linspace(segment.h_start, segment.end, N);
        %         elseif( ~isnan(segment.h_start) ) % only the start is specfied (constant)
        %             h_vec = segment.h_start * ones([N 1]);
        %         elseif( ~isnan(segment.h_end)) % the end is
        % 
        %         if obj.h ~= segment.h_start
        % 
        %         end
        % 
        %         switch segment.type
        %             case 'CRUISE'
        %                 S = di / segment.distance.v;
        %             case 'LOITER'
        %                 S = ti / (segment.time.v * 60 ); % converting from minutes to seconds here
        %             case 'COMBAT'
        %                 S = ti / (segment.time.v * 60 ); % converting from minutes to seconds here
        %             otherwise
        %                 error("Given mission type: %i is not a defined type.", type)
        %         end
        % 
        % 
        %         obj.d = obj.d + obj.v * dt; % tracking global distance
        %         obj.t = obj.t + dt; % tracking global time
        % 
        %         if obj.record_hist
        %             obj.hist.h(end+1)           = obj.h;
        %             obj.hist.v(end+1)           = obj.v;
        %             obj.hist.W(end+1)           = obj.W;
        %             obj.hist.d(end+1)           = obj.d;
        %             obj.hist.t(end+1)           = obj.t; % using this is the global time instead of the local seg
        %             obj.hist.throttle(end+1)    = throttle;
        %             obj.hist.climb_angle(end+1) = climb_angle;
        %             obj.hist.dF_dh(end+1)       = dF_dh;
        %             obj.hist.dF_dv(end+1)       = dF_dv;
        %             obj.hist.mdotf(end+1)       = mdotf;
        %             obj.hist.TSFC(end+1)        = obj.perf_map.TSFC(I);
        %             obj.hist.F(end+1)           = F_center;
        %             obj.hist.segment_name(end+1)= segment.name.v;
        %         end
        %     end
        % end

        function [W_end, total_distance] = solve_mission(obj, mission, h0, v0, W_start)
            % time/physics based simulation -> more computation

            % mission object must be read from readMissionStruct function and built using a combination of missionSeg
            % the starting condition is buried in obj.perf.cond
            % W_start -> ratio from 0 to 1 of how much the tank starts loaded
            obj.mission = mission;

            obj.perf.model.geom = setLoadout(obj.perf.model.geom, mission.loadout);

            % reset these vaues
            obj.t = 0;
            obj.d = 0;
            obj.h = h0;
            obj.v = v0;
            obj.W = weightRatio(W_start, obj.perf.model.geom);

            if obj.record_hist
                obj.hist.h           = obj.h;
                obj.hist.v           = obj.v;
                obj.hist.W           = obj.W;
                obj.hist.d           = obj.d;
                obj.hist.t           = obj.t; % using this is the global time instead of the local seg
                obj.hist.throttle    = [NaN];
                obj.hist.climb_angle = [NaN];
                obj.hist.dF_dh       = [NaN];
                obj.hist.dF_dv       = [NaN];
                obj.hist.mdotf       = [NaN];
                obj.hist.TSFC        = [NaN];
                obj.hist.F           = [NaN];
                obj.hist.segment_name= [mission.data(1).name.v];
            end

            for i = 1:length(mission.data)
                obj.solve_section(mission.data(i));
            end

            W_end = obj.W;
            total_distance = obj.d;
        end

        function solve_section(obj, segment)
            type = segment.type.v;

            if obj.W < obj.perf.model.geom.weights.empty.v / 2
                % warning("Weight too low for mission");
                % this helps add robustess if the mission cannot be completed. Setting it reduces noise as increasing mtow will bring it
                % closer
                % obj.W(end) = obj.perf.model.geom.weights.empty.v / 2;
                obj.W(end) = NaN;
                return;
            end

            if strcmp(type, 'FIXED_WF')
                fuel_burned = obj.W * (1 - segment.WFi.v);
                obj.W = obj.W - fuel_burned;
                obj.t = obj.t + segment.time.v * 60;

                if obj.record_hist
                    obj.hist.h(end+1)           = obj.h;
                    obj.hist.v(end+1)           = obj.v;
                    obj.hist.W(end+1)           = obj.W;
                    obj.hist.d(end+1)           = obj.d;
                    obj.hist.t(end+1)           = obj.t; % using this is the global time instead of the local seg
                    obj.hist.throttle(end+1)    = NaN;
                    obj.hist.climb_angle(end+1) = NaN;
                    obj.hist.dF_dh(end+1)       = NaN;
                    obj.hist.dF_dv(end+1)       = NaN;
                    obj.hist.mdotf(end+1)       = NaN;
                    obj.hist.TSFC(end+1)        = NaN;
                    obj.hist.F(end+1)           = NaN;
                    obj.hist.segment_name(end+1)= segment.name.v;
                end
            else
                fun = obj.getFun(segment);
    
                di = 0; ti = 0;
                i_limit = 5000;
                dt = 5;
    
                incr = 1.618; dt_max = 50; dt_min = 2; 
                climb_limit_lower = 3; climb_limit_upper = 10;
    
                i = 0; S = 0;
                while i < i_limit && S < 1
                    i = i + 1;
    
                    % Compute how far we have gotten into the segment
                    switch type
                        case 'CRUISE'
                            S = di / segment.distance.v;
                        case 'LOITER'
                            S = ti / (segment.time.v * 60 ); % converting from minutes to seconds here
                        case 'COMBAT'
                            S = ti / (segment.time.v * 60 ); % converting from minutes to seconds here
                        otherwise
                            error("Given mission type: %i is not a defined type.", type)
                    end
                    
                    h_prev = obj.h;
                    [di, ti] = obj.take_step(di, ti, dt, fun, S, segment);
    
                    if abs(h_prev - obj.h) < climb_limit_lower
                        dt = dt * incr;
                    elseif abs(h_prev - obj.h) > climb_limit_upper
                        dt = dt / incr;
                    end
                    dt = max(dt_min, min(dt_max, dt));
                    
                    if obj.do_print
                        fprintf("dt = %.4g , t = %.4g,  h = %.4g, v = %.4g, i = %i, W = %.3g\n", dt, obj.t, obj.h, obj.v, i, obj.W)
                    end
                end
            end
        end

        function [di, ti, dF_dh, dF_dv] = take_step(obj, di, ti, dt, fun, S, segment)
            angle_max = 10;
            dh = 10;
            dv = 5;

            % Smoothing these values helps quite a bit with both numerical stability and contuity with adaptive time stepping
            % Back to forward differencing from center to cut down on calls
            F_center = fun([obj.v, obj.h, obj.W, 0], S); % 0 means level flight
            dF_dh_raw = ( fun([obj.v, obj.h + dh, obj.W, 0], S) - F_center ) / dh;
            dF_dv_raw = ( fun([obj.v+dv, obj.h, obj.W, 0], S) - F_center ) / dv;

            dF_dh = obj.grad_alpha * dF_dh_raw + (1 - obj.grad_alpha) * obj.dF_dh_prev;
            dF_dv = obj.grad_alpha * dF_dv_raw + (1 - obj.grad_alpha) * obj.dF_dv_prev;

            obj.dF_dh_prev = dF_dh;
            obj.dF_dv_prev = dF_dv;

            % dh_damp = 1E-5; % When less than this it stops using max climb
            % dv_damp = 5E-3;% When less than this it stops going to max/min throttle
            dh_damp = 2E-3;
            dv_damp = 2E-2;

            % Squaring gets batter damping when near optimum
            target_climb_angle = -angle_max * min(1, (dF_dh/dh_damp)^2 ) * sign(dF_dh);
            PE_target = obj.v * sind(target_climb_angle);

            % Override throttle to max if combat
            if strcmp(segment.type.v, 'COMBAT')
                throttle = 1;
            else
                climbing_throttle = obj.perf_map.Throttle([obj.v, obj.h, obj.W, PE_target]);
                
                if dF_dv > 0
                    throttle = climbing_throttle * max(1 - (dF_dv/dv_damp)^2, 0);
                else
                    throttle = climbing_throttle + (1 - climbing_throttle) * min(1, (dF_dv/dv_damp)^2 );
                end
            end

            throttle = max(throttle, 0); % make sure it does not go under 0
            EP_throttle = obj.perf_map.ExcessPower_Throttle(obj.v, obj.h, obj.W, throttle);
                % How much excess power we get for this throttle setting

            % used to do this extra check but it does not seem to be needed
            % climb_angle = obj.perf.ClimbAngle(obj.perf.ExcessPower - PE_target);
            climb_angle = target_climb_angle;

            I = [obj.v, obj.h, obj.W, EP_throttle]; % input - resolves throttle again

            ET_Climb = PE_target * obj.W / obj.v; % excess thrust required for the climb
            axial_acc = (obj.perf_map.ExcessThrust(I) - ET_Climb) / obj.W; % in Gs
            mdotf = obj.perf_map.mdotf(I);

            obj.h = obj.h + obj.v * sind(climb_angle) * dt;
            obj.v = obj.v + axial_acc * obj.settings.g_const * dt;
            obj.W = obj.W - obj.settings.g_const * mdotf * dt;
            
            di = di + obj.v * dt;            
            ti = ti + dt;

            obj.d = obj.d + obj.v * dt; % tracking global distance
            obj.t = obj.t + dt; % tracking global time

            if obj.record_hist
                obj.hist.h(end+1)           = obj.h;
                obj.hist.v(end+1)           = obj.v;
                obj.hist.W(end+1)           = obj.W;
                obj.hist.d(end+1)           = obj.d;
                obj.hist.t(end+1)           = obj.t; % using this is the global time instead of the local seg
                obj.hist.throttle(end+1)    = throttle;
                obj.hist.climb_angle(end+1) = climb_angle;
                obj.hist.dF_dh(end+1)       = dF_dh;
                obj.hist.dF_dv(end+1)       = dF_dv;
                obj.hist.mdotf(end+1)       = mdotf;
                obj.hist.TSFC(end+1)        = obj.perf_map.TSFC(I);
                obj.hist.F(end+1)           = F_center;
                obj.hist.segment_name(end+1)= segment.name.v;
            end
        end

        function fun = getFun(obj, segment)
            % Return an anomouys function which takes P the current performance and S the state from 0 to 1
            % The fact that we need ismissing instead of isnan is an annoying relaity of needing to read json files

            % I = [V, H, W, EP]
        
            switch segment.type.v
                % need scalers so the two functions are kinda near eachother
                % Goal is to minimize these functions
                case 'CRUISE'
                    fun_obj = @(I) ( obj.perf_map.mdotf(I) ./ I(1) ) * ( 200 / 0.3 ); % I(1) is velocity
                case 'LOITER'
                    fun_obj = @(I) obj.perf_map.mdotf(I) / 0.3;
                case 'COMBAT'
                    fun_obj = @(I) obj.perf_map.ExcessPower(I) / 100;
                otherwise
                    error("Given mission type: %i is not a defined type.", type)
            end
        
            min_alt = 100; % Make sure we don't hit the ground
            fun_const = @(I, S) 1E-3 * max(0, (min_alt - I(2))/min_alt); % I(2) is altitude
        
            R = 6E-2; % changes how much objective is penalized due to the constraints
        
            a = 0.75; % When the tail constraint activates
        
            if ~ismissing(segment.h_start)
                if ~ismissing(segment.h_end)
                    fun_const = @(I, S) fun_const(I, S) + R * pseduo_huber((1-S)*segment.h_start + S*segment.h_end, I(2), 1E3);
                else
                    fun_const = @(I, S) fun_const(I, S) + R * pseduo_huber(segment.h_start, I(2), 1E3);
                end
            else
                if ~ismissing(segment.h_end)
                    % S^2 helps it stay free at the start and then quickly go to the constraint at the end
                    fun_const = @(I, S) fun_const(I, S) + ( max( S-a, 0)/(1-a) )^2 * R * pseduo_huber(segment.h_end, I(2), 1E3);
                end
            end
        
            if ~ismissing(segment.vel_start)
                if ~ismissing(segment.vel_end)
                    fun_const = @(I, S) fun_const(I, S) + R * pseduo_huber((1-S)*segment.vel_start + S*segment.vel_end, I(1), 100);
                else
                    fun_const = @(I, S) fun_const(I, S) + R * pseduo_huber(segment.vel_start, I(1), 100);
                end
            else
                if ~ismissing(segment.vel_end)
                    % S^2 helps it stay free at the start and then quickly go to the constraint at the end
                    fun_const = @(I, S) fun_const(I, S) + ( max( S-a, 0)/(1-a) )^2 * R * pseduo_huber(segment.vel_end, I(1), 100);
                end
            end
        
            fun = @(I, S) fun_obj(I) + fun_const(I, S);
        end

        function plot_hist(obj)
            assert(obj.record_hist, "record_hist is false — no data was recorded");
            
            % Prepare data
            d_km = obj.hist.d / 1000;
            t_min = obj.hist.t / 60;  % Convert to minutes
            
            % Get unique segments and assign colors
            [unique_segments, ~, segment_idx] = unique(obj.hist.segment_name, 'stable');
            colors = lines(length(unique_segments));
            
            if obj.settings.be_imperial
                plots = {
                    m2ft(obj.hist.h),            'h [ft]',        'Altitude';
                    m2ft(obj.hist.v),            'v [ft/s]',      'Velocity';
                    N2lb(obj.hist.W),            'W [lb]',        'Weight';
                    obj.hist.throttle,     'Throttle',     'Throttle';
                    obj.hist.climb_angle,  'Angle [deg]',  'Climb Angle';
                    kgNs_2_lbmlbfhr(obj.hist.TSFC),         'TSFC [lbm/lbfhr]', 'TSFC'
                };
            else
                plots = {
                    obj.hist.h,            'h [m]',        'Altitude';
                    obj.hist.v,            'v [m/s]',      'Velocity';
                    obj.hist.W,            'W [N]',        'Weight';
                    obj.hist.throttle,     'Throttle',     'Throttle';
                    obj.hist.climb_angle,  'Angle [deg]',  'Climb Angle';
                    obj.hist.TSFC,         'TSFC [s]', 'TSFC'
                };
            end
            
            % Determine if we should use point markers (very few unique x values)
            use_points = (length(unique(d_km)) <= 2);
            
            % Create figure 1: vs Distance
            figure('Name', 'Mission History vs Distance');
            if obj.settings.be_imperial
                plot_mission_data(m2nm(d_km*1000), 'Range [nm]', plots, segment_idx, colors, ...
                                 unique_segments, use_points);
            else
                plot_mission_data(d_km, 'Range [km]', plots, segment_idx, colors, ...
                                 unique_segments, use_points);
            end
            
            % Create figure 2: vs Time
            figure('Name', 'Mission History vs Time');
            plot_mission_data(t_min, 'Time [min]', plots, segment_idx, colors, ...
                             unique_segments, use_points);
        end
    end
end

function out = pseduo_huber(x_target, x_current, scale)
    out = scale * (sqrt(1 + ((x_current - x_target)/scale)^2) - 1);
end

function plot_mission_data(x_data, x_label, plots, segment_idx, colors, ...
                          segment_names, use_points)
    % Create 3x3 grid: left 3x2 for plots, right column for legend
    n_plots = size(plots, 1);
    
    for i = 1:n_plots
        % Map to left 2 columns: [1,2], [4,5], [7,8]
        row = floor((i-1)/2) + 1;
        col = mod(i-1, 2) + 1;
        plot_idx = (row-1)*3 + col;
        
        subplot(3, 3, plot_idx);
        
        if use_points
            plot_segmented_points(x_data, plots{i,1}, segment_idx, colors);
        else
            plot_segmented_data(x_data, plots{i,1}, segment_idx, colors);
        end
        
        xlabel(x_label);
        ylabel(plots{i,2});
        title(plots{i,3});
        grid on;
        axis tight;
        ylim_percentile(plots{i,1}, 99);
    end
    
    % Create large legend spanning entire right column [3, 6, 9]
    subplot(3, 3, [3, 6, 9]);
    axis off;
    
    % Create dummy lines for legend
    hold on;
    legend_handles = [];
    for seg = 1:length(segment_names)
        if use_points
            h = plot(NaN, NaN, 'o', 'Color', colors(seg,:), 'MarkerFaceColor', colors(seg,:), ...
                    'MarkerSize', 8, 'DisplayName', segment_names{seg});
        else
            h = plot(NaN, NaN, 'Color', colors(seg,:), 'LineWidth', 2, ...
                    'DisplayName', segment_names{seg});
        end
        legend_handles(end+1) = h;
    end
    hold off;
    
    % Display legend
    leg = legend(legend_handles, 'Location', 'northwest', 'FontSize', 12);
    leg.Box = 'on';
    title('Mission Segments', 'FontSize', 14, 'FontWeight', 'bold');
end

function plot_segmented_data(x, y, segment_idx, colors)
    % Plot line data with different colors for each segment
    hold on;
    for seg = 1:max(segment_idx)
        idx = segment_idx == seg;
        
        % Include last point from previous segment to connect
        if seg > 1
            prev_idx = find(segment_idx == seg-1, 1, 'last');
            if ~isempty(prev_idx)
                idx(prev_idx) = true;
            end
        end
        
        plot(x(idx), y(idx), 'Color', colors(seg,:), 'LineWidth', 1.5);
    end
    hold off;
end

function plot_segmented_points(x, y, segment_idx, colors)
    % Plot point data with different colors for each segment
    hold on;
    for seg = 1:max(segment_idx)
        idx = segment_idx == seg;
        plot(x(idx), y(idx), 'o', 'Color', colors(seg,:), ...
            'MarkerFaceColor', colors(seg,:), 'MarkerSize', 8);
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

