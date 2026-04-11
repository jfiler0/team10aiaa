matlabSetup();
% 1.5619    0.9684    1.0605    1.0549    0.4280

%     TSFC    CDp    TA     Cdw    WE    WF
X0 = [1.5453, 0.1, 1.0649, 1.0309, 1, 0.4206];
% 1.2453    0.7000    1.0649    1.6309    0.8000    0.3831

%     TSFC    CDp    Cdw
X0 = [1.1703, 0.3250,  1.6309];
fun = @(X) settings_tuning(X, false);

% ------------------------------------------------------------------ %
%  Step 1 — 1D sweep along each variable from X0 to see sensitivity  %
%  This tells you which variables actually matter and by how much     %
% ------------------------------------------------------------------ %
% var_names = {'TSFC', 'Cdp', 'TA', 'CDw', 'WE\_scaler', 'WF'};
% n_vars    = length(X0);
% n_sweep   = 15;
% delta     = 0.15;   % ±15% around X0
% 
% figure('Position', [100 100 1400 300]);
% tiledlayout(1, n_vars, 'TileSpacing', 'compact');
% 
% for k = 1:n_vars
%     x_sweep   = linspace(X0(k)*(1-delta), X0(k)*(1+delta), n_sweep);
%     obj_sweep = zeros(size(x_sweep));
%     for j = 1:n_sweep
%         X_test    = X0;
%         X_test(k) = x_sweep(j);
%         obj_sweep(j) = fun(X_test);
%         fprintf('var %d (%s): %.4f -> obj = %.6f\n', k, var_names{k}, x_sweep(j), obj_sweep(j));
%     end
%     nexttile;
%     plot(x_sweep, obj_sweep, 'o-', LineWidth=1.5);
%     xline(X0(k), '--r');
%     xlabel(var_names{k}); ylabel('obj'); grid on;
% end
% sgtitle('Sensitivity sweep from X0');

% ------------------------------------------------------------------ %
%  Step 2 — Optimize with large initial simplex                       %
%  InitialSimplex: first row is X0, each subsequent row perturbs      %
%  one variable by a meaningful amount (not the default 5%)           %
% ------------------------------------------------------------------ %

opts = optimoptions('patternsearch', ...
    'Display',           'iter', ...
    'InitialMeshSize',   0.15,   ...   % this one actually exists
    'MeshTolerance',     1e-2,   ...
    'FunctionTolerance', 1e-2,   ...
    'MaxFunctionEvaluations', 300);

% lb = [0.7,  0.7,  0.7,  0.7,  0.2];   % tune per variable meaning
% ub = [2.0,  2.0,  2.0,  2.0,  0.8];

lb = [0.7,  0.3,  0.7];   % tune per variable meaning
ub = [2.0,  1.0,  2.0];

tic
xs = patternsearch(fun, X0, [], [], [], [], lb, ub, [], opts);
toc
xs
settings_tuning(xs, true);