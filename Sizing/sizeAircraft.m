function plane = sizeAircraft(plane_in, missionList, constrainFun, do_plot, graphSize)

    % A graphSize of 2 will go from 0.5 * opt to 2 * opt. Don't go less than 1

    plane = plane_in; % copy it

    % Function to MAXIMIZE
    function objf = objective(WE, scale)
        plane.span = plane_in.span * scale;
        plane.c_r = plane_in.c_r * scale;
        plane.c_t = plane_in.c_t * scale;

        plane.WE = WE;

        plane = plane.updateDerivedVariables();

        objf = plane.calcUnitCost();
    end

    R = 500; % Penalty parameter

    % Objective is now negative so goal is to MINIMIZE
    function [objf_cons, cost, g_vec] = objective_constrained(WE, scale)
        cost = objective(WE, scale);
        objf =  cost;

        [g_vec, g_names] = constrainFun(plane, missionList);

        g_max = max(g_vec);

        objf_cons = objf + R * g_max;
    end

    x0 = [plane_in.WE 1];

    f = @(x) objective_constrained(x(1), x(2));

    options = optimset( ...
        'Display', 'iter', ...      % Display iteration info
        'TolX', 1e-5, ...           % Tolerance on x
        'TolFun', 1e-5, ...         % Tolerance on function value
        'MaxIter', 50, ...         % Maximum iterations
        'MaxFunEvals', 1000 ...     % Maximum function evaluations
    );
    
    [x_opt, fval_opt, exitflag, output] = fminsearch(f, x0, options);

    WE_opt    = x_opt(1);
    scale_opt = x_opt(2);

    objective(WE_opt, scale_opt); % This updates the plane object
    
    fprintf("Aicraft: %s | Sized has WE = %.3f lb + Wings scaled by %.5f", plane.name, N2lb(plane.WE), scale_opt)

    if(do_plot)

        % -------------------------------
        % Generate coarse grid
        % -------------------------------
        N = 30;
        WE_range    = linspace(WE_opt/graphSize, graphSize*WE_opt, N);
        scale_range = linspace(scale_opt/graphSize, graphSize*scale_opt, N);
        [WE_grid, scale_grid] = meshgrid(WE_range, scale_range);
    
        cost_grid = zeros(size(WE_grid));
        obj_grid = zeros(size(WE_grid));;
    
        % Evaluate constraints
        [g_vec0, g_names] = constrainFun(plane_in, missionList);
        nCons = numel(g_vec0);
        g_grid = zeros(N, N, nCons);
    
        for i = 1:N
            for j = 1:N
                WE_ij = WE_grid(i,j);
                sc_ij = scale_grid(i,j);

                % [objf_cons, cost, g_vec] = objective_constrained(WE, scale)
                [objf_cons, cost, g_vec] = objective_constrained(WE_ij, sc_ij);

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
        N_fine = N*4;
        WE_range_fine    = linspace(min(WE_range), max(WE_range), N_fine);
        scale_range_fine = linspace(min(scale_range), max(scale_range), N_fine);
        [WE_grid_fine, scale_grid_fine] = meshgrid(WE_range_fine, scale_range_fine);
    
        cost_grid_fine = interp2(WE_grid, scale_grid, cost_grid, WE_grid_fine, scale_grid_fine, 'spline');
        obj_grid_fine = interp2(WE_grid, scale_grid, obj_grid, WE_grid_fine, scale_grid_fine, 'spline');
        g_grid_fine = zeros(N_fine, N_fine, nCons);
        for k = 1:nCons
            g_grid_fine(:,:,k) = interp2(WE_grid, scale_grid, g_grid(:,:,k), WE_grid_fine, scale_grid_fine, 'spline');
        end
    
        % -------------------------------
        % 2D Contour Plot with Constraints
        % -------------------------------
        figure; hold on;
    
        % Cost contours (rounded)
        cost_rounded = round(cost_grid_fine,1);
        [C_cost, hCost] = contour(WE_grid_fine, scale_grid_fine, cost_rounded, 10, 'LineWidth', 1.5);
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
            zShade = max(cost_grid_fine(:)) * double(mask);
            zShade(~mask) = NaN;
            hPatch = surf(WE_grid_fine, scale_grid_fine, zShade, ...
                          'FaceColor', colors(k,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
            uistack(hPatch,'bottom');
    
            % Constraint contour line
            [~, hLine] = contour(WE_grid_fine, scale_grid_fine, gk_fine, [0 0], ...
                                 'LineWidth',2,'Color',colors(k,:));
            hLine.DisplayName = g_names{k};
            contourHandles(k) = hLine;
        end
    
        % Plot points
        % plot(x0(1), x0(2), 'ko', 'MarkerFaceColor','k','MarkerSize',8);       % initial guess
        plot(WE_opt, scale_opt, 'yo', 'MarkerFaceColor','y','MarkerSize',10); % optimized point
    
        xlabel('Empty Weight WE'); ylabel('Scale Factor'); 
        title('Unit Cost Contours with Constraints');
        legend([contourHandles, plot(nan,nan,'ko'), plot(nan,nan,'yo')], ...
               [g_names,  {'Optimal'}], 'Location','bestoutside');
        axis tight; grid on; hold off;
    
        % -------------------------------
        % 3D Surface of Penalized Objective
        % -------------------------------
    
        figure; hold on;
        surf(WE_grid_fine, scale_grid_fine, obj_grid_fine, 'EdgeColor','none');
        shading interp; colormap(parula); colorbar;
        xlabel('Empty Weight WE'); ylabel('Scale Factor'); zlabel('Penalized Objective');
        title('3D Surface of Penalized Objective');
        view(45,30); grid on; axis tight;
        % zlim([min(min(obj_grid_fine)) f(x0)])
        % zlim([min(min(obj_grid_fine)) 0])
    
        % Plot points on 3D surface
        % plot3(x0(1), x0(2), f(x0), 'ko', 'MarkerFaceColor','k','MarkerSize',8);
        plot3(WE_opt, scale_opt, f(x_opt), 'yo', 'MarkerFaceColor','y','MarkerSize',10);
        % legend({'Objective Surface','Initial Guess','Optimal'}, 'Location','best');
        legend({'Objective Surface','Optimal'}, 'Location','best');
    
        hold off;
    
    end


end