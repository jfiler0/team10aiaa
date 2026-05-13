function W_res = eval_mission(perf, mission_obj, do_plot, W_start)
    perf.model.geom = setLoadout(perf.model.geom, mission_obj.loadout);
    W_current = weightRatio(W_start, perf.model.geom);
    segObjs = mission_obj.segObjs;

    if do_plot
        n_segs = length(segObjs);
        % Cell arrays: one entry per segment, each is a column vector
        seg_d    = cell(n_segs, 1);
        seg_t    = cell(n_segs, 1);
        seg_h    = cell(n_segs, 1);
        seg_v    = cell(n_segs, 1);
        seg_W    = cell(n_segs, 1);
        seg_W_start_arr = zeros(1, n_segs);
        seg_W_end_arr   = zeros(1, n_segs);
        seg_labels      = strings(1, n_segs);
        d_offset = 0; t_offset = 0;
    end

    for i = 1:length(segObjs)
        [W_out, h_out, v_out, d_out, t_out] = segObjs(i).evaluate(perf, W_current);

        if do_plot
            seg_W_start_arr(i) = W_current;
            seg_W_end_arr(i)   = W_out(end);
            seg_labels(i)      = segObjs(i).type;

            % Prepend start conditions and offset to absolute distance/time
            seg_d{i} = [0;        d_out(:)] + d_offset;
            seg_t{i} = [0;        t_out(:)] + t_offset;
            seg_h{i} = [h_out(1); h_out(:)];
            seg_v{i} = [v_out(1); v_out(:)];
            seg_W{i} = [W_current; W_out(:)];

            d_offset  = seg_d{i}(end);
            t_offset  = seg_t{i}(end);
        end

        W_current = W_out(end);
    end

    W_res = W_current - weightRatio(0, perf.model.geom);

    if do_plot
        % Compute mach per segment
        seg_M = cell(n_segs, 1);
        for i = 1:n_segs
            seg_M{i} = zeros(size(seg_v{i}));
            for k = 1:length(seg_v{i})
                [~, a_k, ~, ~, ~] = queryAtmosphere(seg_h{i}(k), [0 1 0 0 0]);
                seg_M{i}(k) = seg_v{i}(k) / a_k;
            end
        end

        seg_colors = containers.Map(...
            {'TAKEOFF','CLIMB','CRUISE','LOITER','COMBAT','LANDING'}, ...
            {[0.2 0.7 0.2], [0.2 0.5 1.0], [0.1 0.1 0.8], ...
             [0.8 0.6 0.1], [0.8 0.1 0.1], [0.5 0.2 0.8]});

        plot_data_fn = @(i) { ...
            {m2ft(seg_h{i}/1000),  'Alt (kft)' }, ...
            {ms2kt(seg_v{i}), 'Vel (kts)'}, ...
            {seg_M{i},        'Mach'          }, ...
            {N2lb(seg_W{i}),        'Weight (lb)'    }  ...
        };

        [~, unique_idx] = unique(seg_labels, 'stable');

        plot_mission_figure('Mission Profile (Distance)', ...
            seg_d, plot_data_fn, seg_labels, seg_colors, unique_idx, 'Distance (nm)', m2nm(1));

        plot_mission_figure('Mission Profile (Time)', ...
            seg_t, plot_data_fn, seg_labels, seg_colors, unique_idx, 'Time (min)', 1/60);

        %% Fuel burn per segment
        figure('Name', 'Fuel Burn by Segment', 'NumberTitle', 'off');
        delta_W = seg_W_start_arr - seg_W_end_arr;
        bar_colors = zeros(n_segs, 3);
        for i = 1:n_segs
            bar_colors(i,:) = seg_colors(char(seg_labels(i)));
        end
        b = bar(N2lb(delta_W), 'FaceColor', 'flat');
        b.CData = bar_colors;
        set(gca, 'XTick', 1:n_segs, 'XTickLabel', seg_labels, 'XTickLabelRotation', 30);
        ylabel('Fuel Burned (lb)');
        title('Fuel Burn per Segment');
    end
end

function plot_mission_figure(fig_name, seg_x, plot_data_fn, seg_labels, ...
                              seg_colors, unique_idx, x_label, x_scale)
    n_segs  = length(seg_labels);
    n_plots = 4;

    figure('Name', fig_name, 'NumberTitle', 'off');
    t_layout = tiledlayout(n_plots, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    xlabel(t_layout, x_label);

    axes_handles   = gobjects(n_plots, 1);
    legend_handles = gobjects(length(unique_idx), 1);

    % Build normalized x per segment: each seg maps its points to [i-1, i]
    seg_x_norm = cell(n_segs, 1);
    tick_pos   = zeros(1, n_segs + 1); % boundary positions in normalized space
    tick_labels= cell(1,  n_segs + 1);
    for i = 1:n_segs
        x_raw = seg_x{i} * x_scale;
        % linearly map [x_raw(1), x_raw(end)] -> [i-1, i]
        x0 = x_raw(1); x1 = x_raw(end);
        if x1 > x0
            seg_x_norm{i} = (i-1) + (x_raw - x0) / (x1 - x0);
        else
            seg_x_norm{i} = linspace(i-1, i, length(x_raw))';
        end
        tick_pos(i)   = i - 1;
        tick_labels{i}  = fmt_axis_val(x0);
    end
    tick_pos(end)   = n_segs;
    tick_labels{end} = fmt_axis_val(seg_x{end}(end) * x_scale);

    for p = 1:n_plots
        axes_handles(p) = nexttile;
        hold on;

        for i = 1:n_segs
            c    = seg_colors(char(seg_labels(i)));
            x    = seg_x_norm{i};
            seg_data = plot_data_fn(i);
            y    = seg_data{p}{1};
            h_line = plot(x, y, '-', 'Color', c, 'LineWidth', 1.5);

            if p == 1
                uid = find(unique_idx == i, 1);
                if ~isempty(uid)
                    legend_handles(uid) = h_line;
                end
            end
        end

        % Segment dividers
        yl = ylim;
        for i = 1:n_segs-1
            xline(i, '--', 'Color', [0.6 0.6 0.6], 'LineWidth', 0.8, 'Alpha', 0.6);
        end

        set(axes_handles(p), 'XTick', tick_pos, 'XTickLabel', []);
        ref_data = plot_data_fn(1);
        ylabel(ref_data{p}{2});
        if p < n_plots
            set(axes_handles(p), 'XTickLabel', []);
        end
    end

    % Only show tick labels on bottom axis
    set(axes_handles(end), 'XTickLabel', tick_labels);

    % % Segment name labels along top of top axis — placed at normalized midpoints
    % axes(axes_handles(1));
    % for i = 1:n_segs
    %     text(i - 0.5, 1.02, seg_labels(i), ...
    %         'Units', 'data', 'HorizontalAlignment', 'center', ...
    %         'FontSize', 7, 'FontWeight', 'bold', ...
    %         'Clipping', 'off', 'Units', 'normalized'... 
    %     );
    % end
    % override: use data units for x, normalized won't give correct horizontal position
    % re-do with data units properly:
    % Segment name labels along top of top axis — placed at normalized midpoints
    axes(axes_handles(1));
    yl = ylim;
    y_label_pos = yl(2) + 0.04 * diff(yl);
    for i = 1:n_segs
        text(i - 0.5, y_label_pos, seg_labels(i), ...
            'HorizontalAlignment', 'center', 'FontSize', 9, ...
            'FontWeight', 'bold', 'Clipping', 'off');
    end

    linkaxes(axes_handles, 'x');
    xlim(axes_handles(1), [0, n_segs]); % linkaxes propagates this to all

    leg = legend(axes_handles(1), legend_handles, seg_labels(unique_idx), ...
        'Location', 'northeastoutside', 'Box', 'off');
    leg.Layout.Tile = 'east';
end
function s = fmt_axis_val(x)
    if abs(x) < 10
        s = sprintf('%.2f', x);
    elseif abs(x) < 100
        s = sprintf('%.1f', x);
    else
        s = sprintf('%.0f', x);
    end
end