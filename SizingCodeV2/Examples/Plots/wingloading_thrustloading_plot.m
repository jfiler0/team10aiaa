function wingloading_thrustloading_plot()

    %% ================================
    %% SETUP
    %% ================================

    file_name = "HellstingerV3";
    settings = readSettings();

    geom = readAircraftFile(file_name);
    geom = updateGeom(geom, settings, true);
    geom = setLoadout(geom, ["","","","","","","",""]);

    model = model_class(settings, geom);
    base_geom = geom;

    mtow0 = geom.weights.mtow.v;

    delta = 0.1;
    N = 35;

    MTOW_vec  = linspace(mtow0*(1-delta), mtow0*(1+delta), N);
    scale_vec = linspace(1-delta, 1+delta, N);

    [MTOW, SCALE] = meshgrid(MTOW_vec, scale_vec);

    %% ================================
    %% STORAGE
    %% ================================

    WS       = zeros(N,N);
    TW       = zeros(N,N);
    obj_grid = zeros(N,N);

    G     = [];
    names = [];

    %% ================================
    %% COARSE GRID EVALUATION
    %% ================================

    progressbar(0);
    for i = 1:N
        for j = 1:N

            progressbar( ((i-1)*N + j) / (N*N) );   % FIX: was (i*N+j)/(N*N) → exceeded 1

            mtow  = MTOW(i,j);
            scale = SCALE(i,j);

            [obj, output] = objective4(mtow, scale, model, base_geom);

            geom_i = output.geom;
            perf_i = output.perf;

            % --- Wing Loading ---
            WS(i,j) = mtow / geom_i.wing.area.v;

            % --- Thrust Loading ---
            perf_i.clear_data();
            cond = levelFlightCondition(perf_i, 0, 0.0, mtow);
            perf_i.model.cond = cond;

            T = perf_i.TA;
            TW(i,j) = T / mtow;

            obj_grid(i,j) = output.cost;

            % --- Constraints ---
            if isempty(G)
                nCons = length(output.g_vec);
                G     = zeros(N, N, nCons);
                names = output.g_names;
            end

            G(i,j,:) = output.g_vec;

        end
    end

    %% ================================
    %% INTERPOLATE (SMOOTH CONTOURS)
    %% ================================

    Nf = N * 8;

    WS_f = linspace(min(WS(:)), max(WS(:)), Nf);
    TW_f = linspace(min(TW(:)), max(TW(:)), Nf);
    [WS_fine, TW_fine] = meshgrid(WS_f, TW_f);

    obj_fine = griddata(WS(:), TW(:), obj_grid(:), WS_fine, TW_fine, 'cubic');

    % FIX: fill NaNs that appear at grid edges after cubic interpolation
    obj_fine = fillmissing(obj_fine, 'linear', 1);
    obj_fine = fillmissing(obj_fine, 'linear', 2);

    % SMOOTHING: light Gaussian smooth to reduce noise in objective
    obj_fine = imgaussfilt(obj_fine, 1.3);

    nCons  = size(G, 3);
    G_fine = zeros(Nf, Nf, nCons);

    for k = 1:nCons
        gk_coarse = G(:,:,k);
        gk_fine   = griddata(WS(:), TW(:), gk_coarse(:), WS_fine, TW_fine, 'cubic');

        % FIX: fill NaNs
        gk_fine = fillmissing(gk_fine, 'linear', 1);
        gk_fine = fillmissing(gk_fine, 'linear', 2);

        % SMOOTHING: same light Gaussian on each constraint surface
        G_fine(:,:,k) = imgaussfilt(gk_fine, 1.2);
    end

    %% ================================
    %% PLOT
    %% ================================

    figure; hold on;

    % --- Constraint shading (contourf, drawn first so cost contours sit on top) ---
    colors = lines(nCons);
    hCons  = gobjects(nCons, 1);

    for k = 1:nCons

        gk = G_fine(:,:,k);

        % Shade infeasible region (g > 0) with contourf between [0, max]
        gk_clamped = max(gk, 0);                  % only positive part
        gk_max     = max(gk_clamped(:));

        if gk_max > 0
            contourf(WS_fine, TW_fine, gk_clamped, ...
                [eps, gk_max], ...                % one filled band above zero
                'FaceColor', colors(k,:), ...
                'FaceAlpha', 0.18, ...
                'EdgeColor', 'none', ...
                'HandleVisibility', 'off');
        end

    end

    % --- Objective cost contours (on top of shading) ---
    [C_cost, hCost] = contour(WS_fine, TW_fine, obj_fine, 12, 'LineWidth', 1.2);
    clabel(C_cost, hCost, 'FontSize', 8, 'Color', 'k');

    colormap(parula);
    cb = colorbar;
    cb.Label.String = 'Objective';

    % --- Constraint boundary lines + centered labels ---
    for k = 1:nCons

        gk = G_fine(:,:,k);

        % Boundary line
        [~, hLine] = contour(WS_fine, TW_fine, gk, [0 0], ...
            'LineWidth', 2, 'Color', colors(k,:));
        hLine.DisplayName = names{k};
        hCons(k) = hLine;

        % Label at centroid of contour points (robust center placement)
        Ck = contourc(WS_f, TW_f, gk, [0 0]);

        col = 1;
        all_x = [];
        all_y = [];

        % contourc packs multiple segments: [level, n; x1..xn; y1..yn]
        while col < size(Ck, 2)
            n_pts  = Ck(2, col);          % number of points in this segment
            seg_x  = Ck(1, col+1 : col+n_pts);
            seg_y  = Ck(2, col+1 : col+n_pts);
            all_x  = [all_x, seg_x];      %#ok<AGROW>
            all_y  = [all_y, seg_y];      %#ok<AGROW>
            col    = col + n_pts + 1;
        end

        if ~isempty(all_x)
            lx = mean(all_x);
            ly = mean(all_y);

            text(lx, ly, names{k}, ...
                'Color',      colors(k,:), ...
                'FontSize',   9, ...
                'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', ...
                'BackgroundColor', 'w', ...
                'EdgeColor',       'none', ...
                'Margin', 1.5);
        end

    end

    %% ================================
    %% DESIGN POINT
    %% ================================

    WS0 = mtow0 / base_geom.wing.area.v;

    perf0  = performance_class(model);
    cond0  = levelFlightCondition(perf0, 0, 0.0, mtow0);
    perf0.model.cond = cond0;

    T0  = perf0.TA;
    TW0 = T0 / mtow0;

    plot(WS0, TW0, 'ko', 'MarkerFaceColor', 'y', 'MarkerSize', 8);

    %% ================================
    %% LABELING
    %% ================================

    xlabel('Wing Loading  W/S  (N/m²)');
    ylabel('Thrust Loading  T/W');
    title('Constraint Diagram');

    legend([hCons; plot(nan, nan, 'ko', 'MarkerFaceColor', 'y')], ...
        [names, {'Design Point'}], ...
        'Location', 'bestoutside');

    grid on;
    axis tight;

    hold off;

end