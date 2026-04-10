function drag_ribbon_plot(perf, h0, N, W)
    % perf -> the model/geometry to be using
    % h0 -> altitude to run at
    % N -> mach number resolution
    % W -> weight to run
    
    M_vec = linspace(0.3, 2, N);

    perf.model.cond = levelFlightCondition(perf, h0, M_vec, W, perf.model.settings.codes.MV_DEC_MACH);
    perf.clear_data(); perf.model.clear_mem();

    Cd0_vec = perf.model.CD0; % parasite drag
    Cdi_vec = perf.model.CDi; % induced drag
    Cdw_vec = perf.model.CDw; % wave drag
    Cdp_vec = perf.model.CDp; % payload drag

    LD = perf.LD;
    range_term = 200 * perf.mdotf ./ perf.model.cond.vel.v;

    Y = [Cd0_vec ; Cdi_vec ; Cdw_vec ; Cdp_vec];

    area(M_vec, Y')
    axis tight
    ylim([0, 0.1])
    xlabel("Mach Number");
    ylabel("Drag Coefficent")
    hold on;
    yyaxis right;
    plot(M_vec, LD)
    plot(M_vec, range_term)
    ylabel("Lift/Drag OR 200 mdotf[kg/s] / v[m/s]");
    legend({'Parasite', 'Induced', 'Wave', 'Payload','Lift/Drag', 'Range Term'})
    grid on
    title(sprintf("Drag Ribbon Plot for h=%.0f ft", m2ft(h0)) )
end