function plane = sizeAircraft(plane_in, missionList, constrainFun)

    % A graphSize of 2 will go from 0.5 * opt to 2 * opt. Don't go less than 1

    x0 = [plane_in.MTOW 1];

    f = @(x) objective_constrained(x(1), x(2), plane_in, missionList, constrainFun);

    options = optimset( ...
        'Display', 'iter', ...      % Display iteration info
        'TolX', 1e-5, ...           % Tolerance on x
        'TolFun', 1e-5, ...         % Tolerance on function value
        'MaxIter', 50, ...         % Maximum iterations
        'MaxFunEvals', 1000 ...     % Maximum function evaluations
    );
    
    [x_opt, fval_opt, exitflag, output] = fminsearch(f, x0, options);

    MTOW_opt    = x_opt(1);
    scale_opt = x_opt(2);

    plane = plane_in;

    plane.span = plane_in.span * scale_opt;
    plane.c_r = plane_in.c_r * scale_opt;
    plane.c_t = plane_in.c_t * scale_opt;
    plane.MTOW = MTOW_opt;

    plane = plane.updateDerivedVariables();

    fprintf("Aicraft: %s | Sized has MTOW = %.3f lb + Wings scaled by %.5f\n", plane.name, N2lb(plane.MTOW), scale_opt)

    if(do_plot)

        progressbar('Sizing Plot')

        % -------------------------------
        % Generate coarse grid
        % -------------------------------
        N = 15;
        MTOW_range    = linspace(MTOW_opt/graphSize, graphSize*MTOW_opt, N);
        scale_range = linspace(scale_opt/graphSize, graphSize*scale_opt, N);
        [MTOW_grid, scale_grid] = meshgrid(MTOW_range, scale_range);
    
        cost_grid = zeros(size(MTOW_grid));
        obj_grid = zeros(size(MTOW_grid));;
    
        % Evaluate constraints
        [g_vec0, g_names] = constrainFun(plane_in, missionList);
        nCons = numel(g_vec0);
        g_grid = zeros(N, N, nCons);
    
        for i = 1:N
            for j = 1:N

                progressbar( (N*(i-1) + j)/(N*N) )

                MTOW_ij = MTOW_grid(i,j);
                sc_ij = scale_grid(i,j);

                % [objf_cons, cost, g_vec] = objective_constrained(MTOW, scale)
                [objf_cons, cost, g_vec] = objective_constrained(MTOW_ij, sc_ij);

                g_temp = g_vec;
                cost_grid(i,j) = cost;
                obj_grid(i,j) = objf_cons;

                for k = 1:nCons
                    g_grid(i,j,k) = g_temp(k);
                end
            end
        end
    
        % -------------------------------
        % Interpolate to fine grid
        % -------------------------------
        N_fine = N*10;
        MTOW_range_fine    = linspace(min(MTOW_range), max(MTOW_range), N_fine);
        scale_range_fine = linspace(min(scale_range), max(scale_range), N_fine);
        [MTOW_grid_fine, scale_grid_fine] = meshgrid(MTOW_range_fine, scale_range_fine);
    
        cost_grid_fine = interp2(MTOW_grid, scale_grid, cost_grid, MTOW_grid_fine, scale_grid_fine, 'spline');
        obj_grid_fine = interp2(MTOW_grid, scale_grid, obj_grid, MTOW_grid_fine, scale_grid_fine, 'spline');
        g_grid_fine = zeros(N_fine, N_fine, nCons);

        for k = 1:nCons
            g_grid_fine(:,:,k) = interp2(MTOW_grid, scale_grid, g_grid(:,:,k), MTOW_grid_fine, scale_grid_fine, 'spline');
        end
    
        % -------------------------------
        % 2D Contour Plot with Constraints
        % -------------------------------
        figure('Name', "Countour Plot"); hold on;
    
        % Cost contours (rounded)
        cost_rounded = round(cost_grid_fine,1);
        [C_cost, hCost] = contour(MTOW_grid_fine, scale_grid_fine, cost_rounded, 10, 'LineWidth', 1.5);
        hLabels = clabel(C_cost, hCost, 'FontSize',10,'Color','k');
        for k = 1:numel(hLabels)
            val = str2double(hLabels(k).String);
            hLabels(k).String = sprintf('%.1f', val);
        end
        colormap(parula);
        cb = colorbar; cb.Label.String = 'Cost [Million $]';
    
        % Constraint contours + shading
        colors = lines(nCons);
        contourHandles = gobjects(1,nCons);
    
        for k = 1:nCons
            gk_fine = g_grid_fine(:,:,k);
    
            % Shade infeasible region (opaque, matching line color)
            mask = gk_fine > 0;
            lift = max(cost_grid_fine(:)) - k * 1e-2;   % small lift above the surface
            zShade = lift * mask;                    % mask=1 gets height k; mask=0 gets zero (ignored later)
            zShade(mask == 0) = NaN;              % only draw masked areas

            hPatch = surf(MTOW_grid_fine, scale_grid_fine, zShade, ...
                          'FaceColor', colors(k,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'HandleVisibility','off');

            % hPatch.Renderer = 'painters';   % forces 2D draw order
            set(gcf, 'Renderer', 'painters');
    
            % Constraint contour line
            [~, hLine] = contour(MTOW_grid_fine, scale_grid_fine, gk_fine, [0 0], ...
                                 'LineWidth',2,'Color',colors(k,:));
            hLine.DisplayName = g_names{k};
            contourHandles(k) = hLine;
        end
    
        % Plot points
        % plot(x0(1), x0(2), 'ko', 'MarkerFaceColor','k','MarkerSize',8);       % initial guess
        plot(MTOW_opt, scale_opt, 'yo', 'MarkerFaceColor','y','MarkerSize',10); % optimized point
    
        xlabel('MTOW'); ylabel('Scale Factor'); 
        title('Unit Cost Contours with Constraints');
        legend([contourHandles, plot(nan,nan,'ko'), plot(nan,nan,'yo')], ...
               [g_names,  {'Optimal'}], 'Location','bestoutside');
        axis tight; grid on; hold off;
    
        % -------------------------------
        % 3D Surface of Penalized Objective
        % -------------------------------
    
        figure('Name',"3D Objective"); hold on;
        surf(MTOW_grid_fine, scale_grid_fine, obj_grid_fine, 'EdgeColor','none');
        shading interp; colormap(parula); colorbar;
        xlabel('MTOW'); ylabel('Scale Factor'); zlabel('Penalized Objective');
        title('3D Surface of Penalized Objective');
        view(45,30); grid on; axis tight;
        % zlim([min(min(obj_grid_fine)) f(x0)])
        % zlim([min(min(obj_grid_fine)) 0])
    
        % Plot points on 3D surface
        % plot3(x0(1), x0(2), f(x0), 'ko', 'MarkerFaceColor','k','MarkerSize',8);
        plot3(MTOW_opt, scale_opt, f(x_opt), 'yo', 'MarkerFaceColor','y','MarkerSize',10);
        % legend({'Objective Surface','Initial Guess','Optimal'}, 'Location','best');
        legend({'Objective Surface','Optimal'}, 'Location','best');
    
        hold off;

        progressbar(1)
    
    end


end