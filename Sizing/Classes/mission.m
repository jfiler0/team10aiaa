classdef mission
    properties
        segment_list
        loadout
        N_divisions
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
            obj.N_divisions = 10; % How many times to run a segment like cruise/range to get more accuracy

        end
        function [WTO_Next, fuel_burned, W_End] = solveMission(obj, plane, do_plot)
            if nargin < 3
                do_plot = false;
            end

            W0 = plane.MTOW;
            W = W0;

            fuel_reserve = 0.05; % Keep 5 percent fuel reserve

            plane = plane.applyLoadout(obj.loadout); % Update W_P

            % Preallocate for plotting
            time_vec = [0];
            weight_vec = [W];
            speed_vec = [0];
            mach_vec = [0];
            alt_vec = [0];
            fuel_burned_vec = [0];
            type_vec = [""];
            LD_vec = [0];
            TSFC_vec = [0];

            fuel_burned = 0;

            for i = 1:numel(obj.segment_list)
                
                if(W < 0) % Add robustness if intial guess is way off so it can be caught in sizeAircraft
                    W = plane.WE;
                end
                % [W_OUT, WF, fuel_burned]
                
                N_run = 1; % Default
                if ismember(obj.segment_list(i).type, ["CRUISE", "LOITER", "COMBAT"])
                    N_run = obj.N_divisions;
                end
                
                storeInput = obj.segment_list(i).input;
                obj.segment_list(i).input = storeInput / N_run; % If N_run = 1, nothing changes
                for j = 1:N_run
                    % [W_OUT, WF, fuel_burned_i]
                    [W_OUT, ~, fuel_burned_i, info] = obj.segment_list(i).queryWF(W, plane);
                    % info is a struct holding
                    % mach, altitude (meters), time (seconds), speed (m/s)
                    fuel_burned = fuel_burned + fuel_burned_i;

                    if do_plot
                        if(j == 1) % Need to make first point in segment
                            time_vec = [time_vec, time_vec(end)];
                            weight_vec = [weight_vec, W];
                            speed_vec = [speed_vec, info.speed];
                            mach_vec = [mach_vec, info.mach];
                            alt_vec = [alt_vec, info.altitude];
                            fuel_burned_vec = [fuel_burned_vec, fuel_burned];
                            type_vec = [type_vec, obj.segment_list(i).type];
                            LD_vec = [LD_vec, info.LD];
                            TSFC_vec = [TSFC_vec, info.TSFC];
                        end
                        time_vec = [time_vec, time_vec(end) + info.time];
                        weight_vec = [weight_vec, W_OUT];
                        speed_vec = [speed_vec, info.speed];
                        mach_vec = [mach_vec, info.mach];
                        alt_vec = [alt_vec, info.altitude];
                        fuel_burned_vec = [fuel_burned_vec, fuel_burned];
                        type_vec = [type_vec, obj.segment_list(i).type];
                        LD_vec = [LD_vec, info.LD];
                        TSFC_vec = [TSFC_vec, info.TSFC];
                    end

                    W = W_OUT; % Update weight for the next segment

                end
                obj.segment_list(i).input = storeInput; % Reset it
                
                % fprintf("\nW_IN = %.2f lb, W_OUT = %.2f lb, fuel_burned = %.2f lb, WF = %.3f", N2lb(W), N2lb(W_OUT), N2lb(fuel_burned_i), WF)

            end
            % Fuel tank weight = fuel_burned / (1 - fuel_reserve)

            % Calculate the requried MTOW, will be NaN if something went wrong
            WTO_Next = plane.WE + fuel_burned / (1 - fuel_reserve) + plane.W_P + plane.W_Tanks + plane.W_F;
            W_End = W;

            %% Plotting

            % Define colors for each segment type
            segment_colors = containers.Map( ...
                    {'','TAKEOFF','CLIMB','CRUISE','LOITER','COMBAT','LANDING'}, ...
                    {[0 0 1],[0 0 1],[0 0.5 1],[0 1 0],[1 0.5 0],[1 0 0],[0.5 0.5 0.5]} ...
                );
            % Helper function to plot a segment given start and end indices
            function plotSegment(ax, x, y, types, lineStyle)
                    hold(ax, 'on');
                    start_idx = 1;
                    for k = 2:(length(types)+1)
                        if k == length(types) + 1 || ~strcmp(types(k), types(start_idx))
                            seg_color = segment_colors(types(k-1));
                            plot(ax, x(start_idx:(k-1)), y(start_idx:(k-1)), 'Color', seg_color, 'LineWidth', 2, 'LineStyle', lineStyle);
                            start_idx = k;
                        end
                       
                    end
                    hold(ax, 'off');
                end

            if do_plot && ~isempty(time_vec)
                figure;
            
                % Top-left: Weight & Fuel Burned
                ax1 = subplot(3,2,1); hold(ax1,'on');
                plotSegment(ax1, time_vec/60, N2lb(weight_vec), type_vec, '-');
                plotSegment(ax1, time_vec/60, N2lb(fuel_burned_vec), type_vec, '--');
                xlabel(ax1,'Time [min]'); ylabel(ax1,'Weight / Fuel [lb]');
                title(ax1,'Current Weight & Fuel Burned'); grid(ax1,'on');
            
                % Top-middle: Altitude
                ax2 = subplot(3,2,2);
                plotSegment(ax2, time_vec/60, m2ft(alt_vec)/1000, type_vec, '-'); % km
                xlabel(ax2,'Time [min]'); ylabel(ax2,'Altitude [kft]');
                title(ax2,'Altitude vs Time'); grid(ax2,'on');

                 % Top-right: TSFC
                ax3 = subplot(3,2,3);
                plotSegment(ax3, time_vec/60, TSFC_vec, type_vec, '-'); % km
                xlabel(ax3,'Time [min]'); ylabel(ax3,'TSFC kg/Ns');
                title(ax3,'TSFC vs Time'); grid(ax3,'on');
            
                % Bottom-left: Mach
                ax4 = subplot(3,2,4);
                plotSegment(ax4, time_vec/60, mach_vec, type_vec, '-');
                xlabel(ax4,'Time [min]'); ylabel(ax4,'Mach');
                title(ax4,'Mach vs Time'); grid(ax4,'on');
            
                % Bottom-middle: Speed
                ax5 = subplot(3,2,5);
                plotSegment(ax5, time_vec/60, speed_vec, type_vec, '-');
                xlabel(ax5,'Time [min]'); ylabel(ax5,'Speed [m/s]');
                title(ax5,'Speed vs Time'); grid(ax5,'on');

                % Bottom-right: LD
                ax6 = subplot(3,2,6);
                plotSegment(ax6, time_vec/60, LD_vec, type_vec, '-');
                xlabel(ax6,'Time [min]'); ylabel(ax6,'Lift / Drag');
                title(ax6,'Lift over Drag vs Time'); grid(ax6,'on');

                % --- Add a shared legend to the right ---
                axLegend = axes('Position',[0 0 1 1],'Visible','off'); 
                hold(axLegend,'on');
                
                used_types = unique(type_vec);
                used_types(strcmp(used_types,'')) = [];  % Remove empty string
                
                segment_handles = gobjects(length(used_types),1);
                
                for k = 1:length(used_types)
                    t = used_types{k};
                    % Draw invisible line in the legend axes
                    segment_handles(k) = plot(axLegend, nan, nan, 'Color', segment_colors(t), 'LineWidth', 2);
                end
                
                % Make legend in the figure, outside all subplots
                lgd = legend(segment_handles, used_types, 'Location', 'eastoutside', 'FontSize', 10);
                lgd.Title.String = 'Segment Type';
            end


        end
    end
end
