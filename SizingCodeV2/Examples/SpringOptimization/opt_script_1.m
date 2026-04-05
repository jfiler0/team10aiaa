% initialize
% matlabSetup
% build_kevin_cad

% INITIAL OBJECTS TO LOAD
build_default_settings
settings = readSettings();
geom = loadAircraft("kevin_cad", settings); % note that this included loading prop which is why it is disabled in the loop
model = model_class(settings, geom);

X0 = 1; % no scale applied - just evaluate base design
% [obj, output] = objective1(X0, geom, settings);

fun = @(X) objective1(X, model, geom);

opts = optimset('Display',       'iter', ...
                'TolX',          1e-3,   ...
                'TolFun',        1e-3,   ...
                'MaxFunEvals',   200);

tic
xs = fminsearch(fun, X0, opts);

[~, output] = objective1(xs, model, geom);

[v_land, glide_angle, ~] = compute_landing_speed(output.perf, 1);

fprintf("Scale wings by a factor of %.3f to get a landing speed of %.4f kt (against the cosntraint of 145). Process took %.3f sec", xs(1), ms2kt(v_land), toc)

displayAircraftGeom(output.geom)