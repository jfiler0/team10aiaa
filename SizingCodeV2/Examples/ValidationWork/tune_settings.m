matlabSetup();
settings = readSettings();

% currently 11 scalers
enabled_scalers = [0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1];
% enabled_scalers = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];

var_names = []; X0 = [];
names = fieldnames(settings.scalers);
for i = 1:length(names)
    if(enabled_scalers(i)==1)
        scale_len = length(settings.scalers.(names{i}).return_current_scalers()); % number of scalers
        for j = 1:scale_len
            if(scale_len > 1)
                var_names = [var_names, sprintf("%s [%i]", names{i}, j)];
            else
                var_names = [var_names, names{i}];
            end
        end
        X0 = [X0, settings.scalers.(names{i}).return_current_scalers()];
    end
end

fun = @(X) settings_tuning(X, false, enabled_scalers);

ub = X0*1.5;
lb = X0*0.6;

% ------------------------------------------------------------------ %
%  Step 1 — 1D sweep along each variable from X0 to see sensitivity  %
%  This tells you which variables actually matter and by how much    %
% ------------------------------------------------------------------ %
n_vars    = length(X0);
n_sweep   = 10;
delta     = 0.10;   % ±15% around X0

for k = 1:n_vars
    x_sweep   = linspace(X0(k)*(1-delta), X0(k)*(1+delta), n_sweep);
    obj_sweep = zeros(size(x_sweep));
    for j = 1:n_sweep
        X_test    = X0;
        X_test(k) = x_sweep(j);
        obj_sweep(j) = fun(X_test);
        fprintf('var %d (%s): %.4f -> obj = %.6f\n', k, var_names{k}, x_sweep(j), obj_sweep(j));
    end
    figure;
    plot(x_sweep, obj_sweep, 'o-', LineWidth=1.5);
    xline(X0(k), '--r');
    xlabel(var_names{k}); ylabel('obj'); grid on;
end
sgtitle('Sensitivity sweep from X0');

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
    'MaxFunctionEvaluations', 200);

tic
xs = patternsearch(fun, X0, [], [], [], [], lb, ub, [], opts);
toc
xs
settings_tuning(xs, true, enabled_scalers);