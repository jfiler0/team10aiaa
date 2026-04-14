function plot_performance(geom, perf, N)
    perf.model.cond = generateCondition(geom, 0, 0.3, 1, 0.5, 0.75);
    perf.model.clear_mem; perf.clear_data();

    M_vec = linspace(0.3, 2, N);
    perf.model.cond = generateCondition(geom, perf.model.cond.h.v, M_vec, perf.model.cond.n.v, perf.model.cond.W.v, perf.model.cond.throttle.v);

    % Drag Coefficent
    figure('Name', "CD")

    CD_vec = perf.CD;

    plot(M_vec, CD_vec)
    xlabel("Mach Number")
    ylabel("CD")
    axis tight; grid on;
    title("Drag Coefficent")

    % Lift Coefficent
    figure('Name', "CL")
    plot(M_vec, perf.model.cond.CL.v)
    xlabel("Mach Number")
    ylabel("CL")
    axis tight; grid on;
    title("Lift Coefficent")

    figure('Name', "Lift over Drag")

    plot(M_vec, perf.LD)
    xlabel("Mach Number")
    ylabel("LD")
    axis tight; grid on;
    title("Lift over Drag")
end