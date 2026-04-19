function drag_bars(perf, h_vec, M_vec, W)
    % perf  -> the model/geometry to use
    % h_vec -> vector of altitudes [m]
    % M_vec -> vector of Mach numbers to evaluate (e.g. [0.5 0.8 1.0 1.2 1.6])
    % W     -> weight [N]

    nH = length(h_vec);
    nRow = ceil(sqrt(nH));
    nCol = ceil(nH / nRow);

    colors = [0.00 0.45 0.74;   % Payload - blue
              0.93 0.49 0.19;   % Parasite - orange
              0.98 0.90 0.36;   % Induced - yellow
              0.72 0.27 0.91];  % Wave - magenta

    figure("Name","Drag Stack - Flight Envelope")
    ax = gobjects(nH,1);
    for i = 1:nH
        h0 = h_vec(i);
        perf.model.cond = levelFlightCondition(perf, h0, M_vec, W, ...
                            perf.model.settings.codes.MV_DEC_MACH);
        perf.clear_data(); perf.model.clear_mem();

        Cd0_vec = perf.model.CD0; % parasite drag
        Cdi_vec = perf.model.CDi; % induced drag
        Cdw_vec = perf.model.CDw; % wave drag
        Cdp_vec = perf.model.CDp; % payload drag

Y = [Cdp_vec(:), Cd0_vec(:), Cdi_vec(:), Cdw_vec(:)];        CD_total = sum(Y, 2);

        ax(i) = subplot(nRow, nCol, i);
        hb = bar(M_vec, Y, 'stacked', 'BarWidth', 0.7, ...
                 'EdgeColor', 'k', 'LineWidth', 0.4);
        for k = 1:4, hb(k).FaceColor = colors(k,:); end

        % total C_D label above each bar
        text(M_vec, CD_total, arrayfun(@(v) sprintf('%.4f', v), CD_total, ...
             'UniformOutput', false), ...
             'HorizontalAlignment','center', 'VerticalAlignment','bottom', ...
             'FontSize', 14);

        xticks(M_vec);
        xlabel("Mach Number");
        ylabel("Drag Coefficient");
        title(sprintf("h = %.0f ft", m2ft(h0)), 'FontSize', 24);
        theme(gcf, 'light');
        grid on;

        if i == 1
            legend({'Payload','Parasite','Induced','Wave'}, 'Location','best');
        end
    end

    % shared y-axis so altitudes are visually comparable
    linkaxes(ax, 'y');
    ylim(ax(1), [0, max(ylim(ax(1)))*1.1]);
end