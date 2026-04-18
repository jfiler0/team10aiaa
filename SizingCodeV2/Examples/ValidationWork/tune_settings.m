matlabSetup();

fun = @(X) settings_tuning(X, false);

%     CD0,       CDi,   CDw, CLa,   CDp, TA_scale, TSFC_Scale, WE_scale, WF_scale
X0 = [1.1743,  0.8929,  1.7,  1.0,  1.244,    0.9,    1.554,    0.9786,  0.44]; xs = X0;
X0 = [1.26,      1,     1.85, 1.05,  1.35,    0.82,    1.7,    1.03,     0.41]; xs = X0;
X0 = [1.1,      0.85,     1.75, 1.08,  1.2,    0.93,    1.5,    0.93,     0.43]; xs = X0;
X0 = [1.2,      0.93,     1.8, 1.05,  1.3,    0.85,    1.6,    0.96,     0.42]; xs = X0;

var_names = {'CD0', 'CDi', 'CDw', 'CLa','CDp','TA','TSFC','WE','WF'};

% lb = 0.5* ones(size(X0));
% ub = 2* ones(size(X0));

lb = X0*1.2;
up = X0*0.8;

% ------------------------------------------------------------------ %
%  Step 1 — 1D sweep along each variable from X0 to see sensitivity  %
%  This tells you which variables actually matter and by how much     %
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

% opts = optimoptions('patternsearch', ...
%     'Display',           'iter', ...
%     'InitialMeshSize',   0.15,   ...   % this one actually exists
%     'MeshTolerance',     1e-2,   ...
%     'FunctionTolerance', 1e-2,   ...
%     'MaxFunctionEvaluations', 300);
% 
% tic
% xs = patternsearch(fun, X0, [], [], [], [], lb, ub, [], opts);
% toc
% xs
settings_tuning(xs, true);

%    TSFC    CDp    CDw
% XS = [0.7015 0.325 1.9872]; % 79.55
% XS = [0.7015 0.4 1.9872]; % 96.78
% XS = [1 0 1]; % ferry range 3196
% XS = [1.5 1 1.5]; % ferry range 

% settings_tuning(X0, true)