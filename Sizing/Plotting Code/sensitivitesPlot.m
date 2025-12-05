function sensitivitesPlot(plane, values_to_change, graphSize, missionList, constrainFun, N)

    % A graphSize of 2 will go from 0.5 * opt to 2 * opt. Don't go less than 1
    % values_to_change should be a cell array of constructors , names

    plane_save = plane; % This is x0
    v0 = plane_save.calcUnitCost(); % x0 cost

    [~, g_names] = constraints_rfp(plane_save, missionList);

    num_constraints = length(g_names);
    colors = jet(num_constraints);

    progressbar('Sensitivities')

    for i = 1:height(values_to_change)
        const_iden = values_to_change{i, 1}; % Constructor identifier
        const_name = values_to_change{i, 2}; % Consturcot name

        plane = plane_save;
        x0 = plane_save.(const_iden);
        
        x_vec = linspace(x0/graphSize, x0*graphSize, N);

        cost_vec = zeros(size(x_vec));
        g_mat = zeros([num_constraints N]);
        
        for j = 1:N

            progressbar( (N*(i-1) + j)/(height(values_to_change)*N) )

            plane.(const_iden) = x_vec(j);
            plane = plane.updateDerivedVariables();
            cost_vec(j) = plane.calcUnitCost();
            [g_vec, ~] = constraints_rfp(plane, missionList);
            g_mat(:, j) = g_vec;
        end

        figure('Name', const_name);

        plot(x_vec, cost_vec, 'k-', DisplayName="Cost")
        hold on
        plot(x0, v0, 'yo', 'MarkerFaceColor','y','MarkerSize',10, 'DisplayName', sprintf("X0, %4g", x0)); % optimized point
        xline(x0, '--', HandleVisibility='off')
        xlabel(const_name)
        ylabel("Cost [millions]")

        yyaxis right
        ylabel("Constraint Violation")
        yline(0, '--', HandleVisibility='off')

        for k = 1:num_constraints
            plot(x_vec, g_mat(k, :), '-', DisplayName=g_names(k), Color=colors(k, :))
        end

        axis tight

        g_max = max(max(g_mat));
        g_min = min(min(g_mat));

        ylim([max(-0.5, g_min) min(0.5, g_max)])

        title(sprintf("%s Sensitivity to %s", plane.name, const_name))
        legend(Location="eastoutside")

    end

    progressbar(1)

end