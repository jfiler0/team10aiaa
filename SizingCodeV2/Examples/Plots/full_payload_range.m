function full_payload_range(perf)
    loadouts = {{["AIM-9X" "Mk-83" "Mk-83" "" "" "" "Mk-83" "Mk-83" "AIM-9X"], @eval_air2gnd, 50, "Strike"}, ...
        {["AIM-9X" "Mk-83" "Mk-83" "" "FPU-12" "" "Mk-83" "Mk-83" "AIM-9X"], @eval_air2gnd, 50, "Strike (1 Tank)"}, ...
        {["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "" "FPU-12" "Mk-83" "Mk-83" "AIM-9X"], @eval_air2gnd, 50, "Strike (2 Tank)"}, ...
        {["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9X"], @eval_air2gnd, 50, "Strike (3 Tank)"}, ...
        {["AIM-9X" "AIM-120" "AIM-120" "" "" "" "AIM-120" "AIM-120" "AIM-9X"], @eval_air2air, 2, "Combat"}, ...
        {["AIM-9X" "AIM-120" "AIM-120" "" "FPU-12" "" "AIM-120" "AIM-120" "AIM-9X"], @eval_air2air, 2, "Combat (1 Tank)"}, ...
        {["AIM-9X" "AIM-120" "AIM-120" "FPU-12" "" "FPU-12" "AIM-120" "AIM-120" "AIM-9X"], @eval_air2air, 2, "Combat (2 Tank)"}, ...
        {["AIM-9X" "AIM-120" "AIM-120" "FPU-12" "FPU-12" "FPU-12" "AIM-120" "AIM-120" "AIM-9X"], @eval_air2air, 2, "Combat (3 Tank)"}, ...
        {["" "" "" "" "" "" "" "" ""], @eval_ferry, 0, "Ferry"}, ...
        {["" "" "" "" "FPU-12" "" "" "" ""], @eval_ferry, 0, "Ferry (1 Tank)"}, ...
        {["" "" "" "FPU-12" "" "FPU-12" "" "" ""], @eval_ferry, 0, "Ferry (2 Tank)"}, ...
        {["" "" "" "FPU-12" "FPU-12" "FPU-12" "" "" ""], @eval_ferry, 0, "Ferry (3 Tank)"}};
    groups = [1:4; 5:8; 9:12];
    radius_nm_vec = zeros([length(loadouts), 1]);
    payload_weight_N = radius_nm_vec;
    progressbar(0);
    for i = 1:length(loadouts)
        perf_local = perf;
        radius_nm_vec(i) = get_mission_range(loadouts{i}{2}, loadouts{i}{3}, perf_local, loadouts{i}{1});
        perf_local.model.geom = setLoadout(perf_local.model.geom, loadouts{i}{1});
        payload_weight_N(i) = perf_local.model.geom.weights.loaded.v;
        progressbar(i / length(loadouts));
    end
    progressbar(1);
    group_max_payload = max(payload_weight_N(groups), [], 2);
    [~, sort_idx] = sort(group_max_payload, 'descend');
    groups = groups(sort_idx, :);
    N_group = height(groups);
    figure(Name="Payload Range");
    hold on;
    base_colors = [
        0.122  0.471  0.706;  % steel blue
        0.839  0.153  0.157;  % brick red
        0.172  0.627  0.172;  % mid green
        0.580  0.404  0.741;  % purple
        0.549  0.337  0.294;  % brown
        0.890  0.467  0.761;  % pink-magenta
        0.498  0.498  0.498;  % grey
        0.737  0.741  0.133;  % olive
    ];
    colors = base_colors(1:N_group, :);
    markers = {'o', 's', '^', 'd'};  % no tank / 1 / 2 / 3 tank
    N_pts = width(groups);
    hLines = gobjects(N_group, 1);
    for j = 1:N_group
        idx = groups(j, :);
        x = radius_nm_vec(idx);
        y = N2lb(payload_weight_N(idx));
        % Plot the connecting line without markers, legend entry here
        hLines(j) = plot(x, y, '-', 'Color', colors(j,:), 'LineWidth', 1.5, ...
            'DisplayName', loadouts{idx(1)}{4});  % base name e.g. "Strike"
        % Overlay each point with its own marker, no legend entry
        for k = 1:N_pts
            plot(x(k), y(k), markers{k}, 'Color', colors(j,:), ...
                'MarkerFaceColor', colors(j,:), 'MarkerSize', 7, ...
                'HandleVisibility', 'off');
        end
    end
    % Ghost entries for tank count symbols
    tank_labels = {'No Tanks', '1 Tank', '2 Tanks', '3 Tanks'};
    hGhost = gobjects(N_pts, 1);
    for k = 1:N_pts
        hGhost(k) = plot(nan, nan, markers{k}, 'Color', [0.2 0.2 0.2], ...
            'MarkerFaceColor', [0.2 0.2 0.2], 'MarkerSize', 7, ...
            'DisplayName', tank_labels{k});
    end
    
    legend([hLines; hGhost], 'Location', 'northeast');
    % xline(700, 'k:', LineWidth=2, DisplayName = "RFP Req")
    xlabel('Combat Radius [nm]');
    ylabel('Loaded Weight [lb]');
    title('Payload-Range Diagram');
    grid on;
    hold off;

    xlim([700 1200])
end

function range_nm = get_mission_range(fun, input, perf, loadout)
    try
        range_nm = fzero(@(R) eval_res(perf, fun, R, input, loadout), 100);
    catch exception
        range_nm = NaN;
    end
    function res = eval_res(perf, fun, range_nm, input, loadout)
        [W_final, empty_weight] = fun(perf, range_nm, input, loadout);
        res = W_final - empty_weight;
    end
end