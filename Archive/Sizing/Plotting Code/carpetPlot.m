function plane = carpetPlot(plane, missionList, constrainFun, graphSize)

    progressbar('Carpet Plot')

    % -------------------------------
    % Generate coarse grid
    % -------------------------------

    MTOW_opt = plane.MTOW;
    scale_opt = 1;

    N = 15;
    MTOW_range    = linspace(MTOW_opt/graphSize, graphSize*MTOW_opt, N);
    scale_range = linspace(scale_opt/graphSize, graphSize*scale_opt, N);
    [MTOW_grid, scale_grid] = meshgrid(MTOW_range, scale_range);

    cost_grid = zeros(size(MTOW_grid));
    obj_grid = zeros(size(MTOW_grid));

    % Evaluate constraints
    [g_vec0, g_names] = constrainFun(plane, missionList);
    nCons = numel(g_vec0);
    g_grid = zeros(N, N, nCons);

    fun = @(MTOW, scale) objective_constrained(scalePlane(plane, MTOW, scale),  missionList, constrainFun);

    for i = 1:N
        for j = 1:N

            progressbar( (N*(i-1) + j)/(N*N) )

            MTOW_ij = MTOW_grid(i,j);
            sc_ij = scale_grid(i,j);

            [objf_cons, cost, g_vec] = fun(MTOW_ij, sc_ij);

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
    [C_cost, hCost] = contour(plane.MTOW ./ ( scale_grid_fine * plane.S_wing), plane.engine_T0AB ./ MTOW_grid_fine, cost_rounded, 10, 'LineWidth', 1.5);
    hLabels = clabel(C_cost, hCost, 'FontSize',10,'Color','k');
    for k = 1:numel(hLabels)
        val = str2double(hLabels(k).String);
        hLabels(k).String = sprintf('%.1f', val);
    end
    colormap(parula);
    cb = colorbar; cb.Label.String = 'Cost [Million $]';


    % Constraint contours + shading
    colors = jet(nCons);
    contourHandles = gobjects(1,nCons);

    for k = 1:nCons
        gk_fine = g_grid_fine(:,:,k);

        % Shade infeasible region (opaque, matching line color)
        mask = gk_fine > 0;
        lift = max(cost_grid_fine(:)) - k * 1e-2;   % small lift above the surface
        zShade = lift * mask;                    % mask=1 gets height k; mask=0 gets zero (ignored later)
        zShade(mask == 0) = NaN;              % only draw masked areas

        hPatch = surf(plane.MTOW ./ ( scale_grid_fine * plane.S_wing), plane.engine_T0AB ./ MTOW_grid_fine, zShade, ...
                      'FaceColor', colors(k,:), 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'HandleVisibility','off');
        
        % hPatch.Renderer = 'painters';   % forces 2D draw order
        set(gcf, 'Renderer', 'painters');

        % Constraint contour line
        [~, hLine] = contour(plane.MTOW ./ ( scale_grid_fine * plane.S_wing), plane.engine_T0AB ./ MTOW_grid_fine, gk_fine, [0 0], ...
                             'LineWidth',2,'Color',colors(k,:));
        hLine.DisplayName = g_names{k};
        contourHandles(k) = hLine;
    end

    % Plot points
    % plot(x0(1), x0(2), 'ko', 'MarkerFaceColor','k','MarkerSize',8);       % initial guess
    plot(plane.MTOW / ( scale_opt * plane.S_wing), plane.engine_T0AB ./ MTOW_opt, 'yo', 'MarkerFaceColor','y','MarkerSize',10); % optimized point

    xlabel(sprintf("W/S [N/m2], W = %.4g kN", plane.MTOW/1000)); ylabel(sprintf("T/W, T = %.4g kN", plane.engine_T0AB/1000)); 
    title('Unit Cost Contours with Constraints');
    legend([contourHandles, plot(nan,nan,'ko'), plot(nan,nan,'yo')], ...
           [g_names,  {'Design'}], 'Location','northeast');
    axis tight; grid on; hold off;

    % -------------------------------
    % 3D Surface of Penalized Objective
    % -------------------------------

    figure('Name',"3D Objective"); hold on;
    surf(plane.MTOW ./ ( scale_grid_fine * plane.S_wing), plane.engine_T0AB ./ MTOW_grid_fine, obj_grid_fine, 'EdgeColor','none');
    
    shading interp; colormap(parula); colorbar;
    xlabel(sprintf("W/S [N/m2], W = %.4g kN", plane.MTOW/1000)); ylabel(sprintf("T/W, T = %.4g kN", plane.engine_T0AB/1000)); zlabel('Penalized Objective');
    title('3D Surface of Penalized Objective');
    view(45,30); grid on; axis tight;

    % Plot points on 3D surface
    f_opt = fun(MTOW_opt, scale_opt);

    plot3(plane.MTOW / ( scale_opt * plane.S_wing), plane.engine_T0AB ./ MTOW_opt, f_opt, 'yo', 'MarkerFaceColor','y','MarkerSize',10);
    legend({'Objective Surface','Design'}, 'Location','best');
    zlim([ min(min(obj_grid_fine)) 3 * f_opt])

    hold off;

    progressbar(1)

end