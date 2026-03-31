initialize
matlabSetup
build_kevin_cad

% INITIAL OBJECTS TO LOAD
build_default_settings
settings = readSettings();
geom = loadAircraft("kevin_cad", settings);

X0 = 1; % no scale applied - just evaluate base design
% [obj, output] = objective1(X0, geom, settings);

fun = @(X) objective1(X, geom, settings);

opts = optimoptions('fminunc', ...
    'StepTolerance',      1e-4,  ... % default 1e-6 — coarser steps given noisy inner loops
    'FunctionTolerance',  1e-4,  ... % default 1e-6
    'OptimalityTolerance',1e-5,  ... % default 1e-6 — KKT gradient condition
    'FiniteDifferenceStepSize', 1e-4, ... % default sqrt(eps) ≈ 1.5e-8 — much larger for nested solvers
    'MaxFunctionEvaluations', 500, ...
    'Display', 'iter');

xs = fminunc(fun, X0, opts)

[~, output] = objective1(xs, geom, settings);

[v_land, glide_angle, ~] = compute_landing_speed(output.perf, 1)

ms2kt(v_land)