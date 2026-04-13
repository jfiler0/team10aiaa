initialize
matlabSetup
build_kevin_cad % editing this geometry as it already holds to most constraints

% INITIAL OBJECTS TO LOAD
build_default_settings
settings = readSettings();

settings.WF_ratio = 0.6; % important override here

geom = loadAircraft("kevin_cad", settings); % note that this included loading prop which is why it is disabled in the loop
model = model_class(settings, geom);

%% MISSIONS TO RUN
Air2Air_700nm = { ...
    missionSeg("TAKEOFF", 'FIXED_WF', [0.98, 5]), ... % basic takeoff
    missionSeg("CLIMB_1", 'CRUISE', nm2m(50), [NaN, NaN], [0, ft2m(10000)] ), ... % Climb to 10kf in 50nm
    missionSeg("CRUISE_1", 'CRUISE', nm2m(650),[350,NaN]), ... % Unconsrained cruise for 700nm
    missionSeg("LOITER", 'LOITER', 20, [NaN, NaN], [ft2m(10000), NaN] ), ... % maintain 10kf for 20 minutes
    missionSeg("COMBAT", 'COMBAT', [8, 3, 1, 2, 3], [NaN, NaN], [ft2m(10000), NaN] ), ... %8 minutes of combat, full throttle, holing 3 Gs. Deploy racks 1,2,3
    missionSeg("CLIMB_2", 'CRUISE', nm2m(50), [NaN, NaN], [0, ft2m(10000)] ), ... % Climb to 10kf in 50nm
    missionSeg("CRUISE_2", 'CRUISE', nm2m(650)), ... % Unconsrained cruise for 700nm
    missionSeg("APPROACH", 'LOITER', 5, [NaN, NaN], [ft2m(10000), 0] ), ... % descend from 10kf to sealevel in 5 minutes
    missionSeg("LANDING", 'FIXED_WF', [0.98, 5])}; % basic landing/taxi

writeMissionStruct(Air2Air_700nm, "OPM_Air2Air_700nm",  ["AIM-9X" "AIM-120" "AIM-120" "AIM-120" "AIM-120" "AIM-120" "AIM-120" "AIM-9X"]);

Air2Gnd_700nm = { ...
    missionSeg("TAKEOFF", 'FIXED_WF', [0.98, 5]), ... % basic takeoff
    missionSeg("CLIMB_1", 'CRUISE', nm2m(50), [NaN, NaN], [0, ft2m(10000)] ), ... % Climb to 10kf in 50nm
    missionSeg("CRUISE_1", 'CRUISE', nm2m(600)), ... % Unconsrained cruise for 700nm
    missionSeg("DESCENT", 'CRUISE', nm2m(50), [NaN, 250], [NaN, 200] ), ...
    missionSeg("INTERDICTION", 'CRUISE', nm2m(20), [250, NaN], [200, NaN] ), ...
    missionSeg("COMBAT", 'COMBAT', [8, 3, 1, 2, 3], [NaN, NaN], [200, NaN] ), ... %8 minutes of combat, full throttle, holing 3 Gs. Deploy racks 1,2,3
    missionSeg("CLIMB OUT", 'CRUISE', nm2m(50), [250, NaN], [1000, ft2m(10000)] ), ...
    missionSeg("CRUISE_2", 'CRUISE', nm2m(650)), ... % Unconsrained cruise for 700nm
    missionSeg("APPROACH", 'LOITER', 5, [NaN, NaN], [ft2m(10000), 0] ), ... % descend from 10kf to sealevel in 5 minutes
    missionSeg("LANDING", 'FIXED_WF', [0.98, 5])}; % basic landing/taxi

writeMissionStruct(Air2Gnd_700nm, "OPM_Air2Gnd_700nm",  ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"]);

%% INITIAL GUESS

% X(1) - MTOW (N)
% X(2) - Wing Root Chord (m)
% X(3) - Wing Span (m)
% X(4) - Wing Tip Chord (m)

X0 = [lb2N(58000) 6.1 ft2m(49) 1.5]; xs = X0;

fun = @(X) objective2(X, model, geom, settings);
% 
% %% OPTIMIZE
% % Normalize X so fmincon sees O(1) variables
% X_scale = abs(X0);
% 
% fun_norm = @(X_n) objective2(X_n .* X_scale, model, geom, settings);
% 
% X0_n = X0 ./ X_scale;   % all ones at start
% lb_n = [lb2N(30000), 1.5,  5, 0.1] ./ X_scale;
% ub_n = [lb2N(120000), 9.0, 20, 5] ./ X_scale;   % wider chord bound
% 
% opts = optimoptions('fmincon', ...
%     'Algorithm',                'sqp',  ...
%     'Display',                  'iter', ...
%     'FiniteDifferenceStepSize', 1e-3,   ...  % 5% in normalized space = meaningful for all vars
%     'StepTolerance',            1e-4,   ...
%     'FunctionTolerance',        1e-5,   ...
%     'OptimalityTolerance',      1e-5,   ...
%     'MaxFunctionEvaluations',   300);
% 
% tic
% xs_n = fmincon(fun_norm, X0_n, [], [], [], [], lb_n, ub_n, [], opts);
% xs   = xs_n .* X_scale;

%% REPORT OUT
[~, output] = objective2(xs, model, geom, settings);

[v_land, glide_angle, ~] = compute_landing_speed(output.perf, 1);

fprintf("MTOW = %.0f lb. root = %.2f m. span = %.2f m. sweep = %.2f deg .Landing speed of %.4f kt (against the cosntraint of 145). Process took %.3f sec\n", N2lb(xs(1)), xs(2), xs(3), xs(4), ms2kt(v_land), toc)

displayAircraftGeom(output.geom)

output.geom.name.v = "0412_Optimization";
output.geom.id.v = "0412_Optimization";
writeAircraftFile(output.geom)

T = table();
T.("Constraint Name") = output.g_names';
T.("Constraint Value") = output.g_vec';
T.("Target Value") = output.target';
T.("Computed Value") = output.value';

disp(T);

T = table();
T.("Variable Name") = ["MTOW [lb]", "Root Chord [m]", "Span [m]", "Tip Chord [m]"]';
T.("Varible Values") = [N2lb(xs(1)), xs(2), xs(3), xs(4)]';

disp(T);

N = 20;
sweep_1d(fun, xs, 1, linspace(lb2N(50000), lb2N(120000), N));
sweep_1d(fun, xs, 2, linspace(4, 10, N));
sweep_1d(fun, xs, 3, linspace(10, 20, N));
sweep_1d(fun, xs, 4, linspace(0.5, 6, N));

% drag_ribbon_plot(output.perf, 6000, 200, 0.5)

function sweep_1d(fun, X0, idx, range)
    [~, output_x0] = fun(X0);
    n_con   = length(output_x0.g_vec);
    n_sweep = length(range);

    g_mat = zeros(n_con, n_sweep);

    for i = 1:n_sweep
        xs      = X0;
        xs(idx) = range(i);
        [~, output] = fun(xs);
        g_mat(:, i) = output.g_vec;
    end

    % ------------------------------------------------------------------ %
    %  Axis limits — driven by active constraints only                    %
    % ------------------------------------------------------------------ %
    margin      = 0.3;
    active_con  = any(g_mat > -margin, 2);
    g_active_vals = g_mat(active_con, :);

    if isempty(g_active_vals)
        g_ylim = [min(g_mat(:)) - 0.1, max(g_mat(:)) + 0.1];
    else
        g_pad  = 0.15 * (max(g_active_vals(:)) - min(g_active_vals(:)) + 1e-6);
        g_ylim = [min(g_active_vals(:)) - g_pad, max(g_active_vals(:)) + g_pad];
        g_ylim(1) = min(g_ylim(1), -0.5);
        g_ylim(2) = max(g_ylim(2),  0.2);
    end

    % ------------------------------------------------------------------ %
    %  Plot                                                               %
    % ------------------------------------------------------------------ %
    figure('Position', [100 100 900 450]);
    hold on;

    colors = lines(n_con);

    for k = 1:n_con
        if active_con(k)
            lw = 2.0; ls = '-';
        else
            lw = 0.8; ls = '--';
        end
        plot(range, g_mat(k,:), ls, 'Color', colors(k,:), 'LineWidth', lw, ...
            'DisplayName', output_x0.g_names(k));
    end

    % Feasibility boundary — no DisplayName so it won't appear in legend
    yline(0, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');

    % X0 marker
    xline(X0(idx), '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.2, ...
        'Label', 'X_0', 'LabelVerticalAlignment', 'bottom', ...
        'HandleVisibility', 'off');

    ylim(g_ylim);
    xlim([range(1), range(end)]);
    ylabel('Constraint g   (g $\leq$ 0 feasible)');
    xlabel(sprintf('X(%d)', idx));
    title(sprintf('1D Constraint Sweep , Variable %d', idx));
    grid on;
    legend('Location', 'best', 'NumColumns', 2);
end