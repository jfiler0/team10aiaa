matlabSetup();

X0 = [1.5453, 0.9667, 1.0649, 1.0309, 0.4206]; % TSFC, Cdp, TA, CDw, WE_scaler, WF_ratio

fun = @(X) settings_tuning(X, false);

opts = optimset('Display',       'iter', ...
                'TolX',          1e-3,   ...
                'TolFun',        1e-3,   ...
                'MaxFunEvals',   100);

tic
xs = fminsearch(fun, X0, opts);
toc

xs
settings_tuning(xs, true);