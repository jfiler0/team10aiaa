function dragPolarPlot(plane)

    N = 200; % Num points per line

    M_vec = [0.2 0.95 1.2 1.3 1.5];
    colors = jet(length(M_vec));

    figure('Name',"Drag Polar");
    hold on;

    for i = 1:length(M_vec)
        M = M_vec(i);

        [CL_max_clean, ~, ~] = plane.calcCL(M);
        CL_vec = linspace(-0.5, CL_max_clean, N);
        CD_vec = zeros(size(CL_vec));

        if any(~isfinite(CD_vec))
            warning("Non-finite CD values for M=%.2f", M)
            disp([CL_vec(:) CD_vec(:)])
        end

        for j = 1:length(CL_vec)
            [CD_vec(j), ~, ~, ~, ~] = plane.calcCD(CL_vec(j), M);
        end
        plot(CD_vec, CL_vec, 'Color', colors(i, :), DisplayName=sprintf("$M=%.3g", M));

    end

    xlabel("CD");
    ylabel("CL");
    title("Drag Polar Plot for " + plane.name);
    grid on;
    legend(Location="southeast")
    xlim([0 0.5])

end