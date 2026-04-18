function [interpObj, devObj] = build_engine_lookup(sweepFilePath)
% Builds a lookup for (Mach, Altitude, Throttle) -> Thrust / TSFC
%
% Thrust: piecewise-linear in throttle (exact by construction), spline in Mach/Alt
%   throttle = 0   -> idle (min PLA)
%   throttle = 0.9 -> mil power (PLA 100)
%   throttle = 1.0 -> max AB  (PLA 150)
%
% TSFC: not linear with throttle, so stacked 2D spline slices across PLA
%       with vectorised piecewise-linear blend in the throttle dimension

    if ~isfile(sweepFilePath)
        error("NPSS Sweep does not exist: '%s'\n Has the NPSS run been completed? Otherwise switch back to PROP_BASIC for this engine configuration.", sweepFilePath);
    end

    sweepFile = load(sweepFilePath);
    data      = sweepFile.DataTable;
    mach = data.("Mach Number");
    alt  = ft2m(data.Altitude);
    pla  = data.PLA;

    sigma_scatter = 0.15;

    coords = [mach, alt, pla];
    coords_norm = (coords - min(coords)) ./ (max(coords) - min(coords));

    D2 = sum((permute(coords_norm, [1 3 2]) - permute(coords_norm, [3 1 2])).^2, 3);
    W  = exp(-D2 / (2 * sigma_scatter^2));

    W_sum          = sum(W, 2);
    thrust = lb2N(data.Thrust);
    thrust_smooth  = (W * thrust) ./ W_sum;
    tsfc_smooth    = (W * data.TSFC)   ./ W_sum;

    F_thrust = scatteredInterpolant(mach, alt, pla, thrust_smooth, 'linear', 'linear');
    F_tsfc   = scatteredInterpolant(mach, alt, pla, tsfc_smooth,   'linear', 'linear');

    n_mach   = 40;
    n_alt    = 40;
    mach_vec = linspace(min(mach), max(mach), n_mach);
    alt_vec  = linspace(min(alt),  max(alt),  n_alt);
    [M, A]   = ndgrid(mach_vec, alt_vec);

    pla_min = min(pla);

    thrust_idle = eval_slice(F_thrust, M, A, pla_min);
    thrust_mil  = eval_slice(F_thrust, M, A, 100);
    thrust_ab   = eval_slice(F_thrust, M, A, 150);

    I_T_idle = griddedInterpolant({mach_vec, alt_vec}, thrust_idle, 'makima');
    I_T_mil  = griddedInterpolant({mach_vec, alt_vec}, thrust_mil,  'makima');
    I_T_ab   = griddedInterpolant({mach_vec, alt_vec}, thrust_ab,   'makima');

    pla_tsfc = unique([linspace(pla_min, 100, 4), linspace(100, 150, 4)]);
    n_slices = length(pla_tsfc);

    tsfc_slices    = cell(n_slices, 1);
    throttle_knots = zeros(n_slices, 1);

    for k = 1:n_slices
        pla_k    = pla_tsfc(k);
        tsfc_k   = eval_slice(F_tsfc,   M, A, pla_k);
        thrust_k = eval_slice(F_thrust, M, A, pla_k);

        if pla_k <= 100
            thr_k = 0.9 .* thrust_k ./ thrust_mil;
        else
            thr_k = 0.9 + 0.1 .* (thrust_k - thrust_mil) ./ (thrust_ab - thrust_mil);
        end
        throttle_knots(k) = mean(thr_k(:), 'omitnan');

        tsfc_slices{k} = griddedInterpolant({mach_vec, alt_vec}, tsfc_k, 'makima');
    end

    throttle_knots = sort(throttle_knots);

    mach_bounds = [min(mach_vec), max(mach_vec)];
    alt_bounds  = [min(alt_vec),  max(alt_vec)];

    interpObj.TA   = @(m, a, t) query_thrust(m, a, t, I_T_idle, I_T_mil, I_T_ab, mach_bounds, alt_bounds);
    interpObj.TSFC = @(m, a, t) query_tsfc(  m, a, t, tsfc_slices, throttle_knots, mach_bounds, alt_bounds);

    devObj = struct();

    devObj.npss.mach = mach;
    devObj.npss.alt = alt;
    devObj.npss.pla = pla;
    devObj.npss.thrust = thrust;
    devObj.npss.tsfc = data.TSFC;

    devObj.npss.thrust_smooth = thrust_smooth;
    devObj.npss.tsfc_smooth = tsfc_smooth;

    devObj.gridded.mach = mach_vec;
    devObj.gridded.alt = alt_vec;  
end


% ===================================================================== %
%  Helpers                                                               %
% ===================================================================== %

function grid = eval_slice(F, M, A, pla_val)
    grid = F(M, A, pla_val * ones(size(M)));
end

% --------------------------------------------------------------------- %
function thrust = query_thrust(mach, alt, throttle, I_idle, I_mil, I_ab, mach_bounds, alt_bounds)
    sz       = size(mach);
    mach     = min(max(mach(:),     mach_bounds(1)), mach_bounds(2));
    alt      = min(max(alt(:),      alt_bounds(1)),  alt_bounds(2));
    throttle = min(max(throttle(:), 0),              1);
    thrust   = zeros(numel(mach), 1);

    mil_mask = throttle <= 0.9;
    ab_mask  = ~mil_mask;

    if any(mil_mask)
        alpha = throttle(mil_mask) / 0.9;
        thrust(mil_mask) = I_idle(mach(mil_mask), alt(mil_mask)) .* (1 - alpha) ...
                         + I_mil( mach(mil_mask), alt(mil_mask)) .*      alpha;
    end

    if any(ab_mask)
        alpha = (throttle(ab_mask) - 0.9) / 0.1;
        thrust(ab_mask) = I_mil(mach(ab_mask), alt(ab_mask)) .* (1 - alpha) ...
                        + I_ab( mach(ab_mask), alt(ab_mask)) .*      alpha;
    end

    thrust = reshape(thrust, sz);
end

% --------------------------------------------------------------------- %
function tsfc = query_tsfc(mach, alt, throttle, slices, knots, mach_bounds, alt_bounds)
    sz       = size(mach);
    mach     = min(max(mach(:),     mach_bounds(1)), mach_bounds(2));
    alt      = min(max(alt(:),      alt_bounds(1)),  alt_bounds(2));
    throttle = min(max(throttle(:), knots(1)),       knots(end));
    n_pts    = numel(mach);
    n_slices = length(slices);

    tsfc_vals = zeros(n_pts, n_slices);
    for k = 1:n_slices
        tsfc_vals(:, k) = slices{k}(mach, alt);
    end

    tsfc_out = zeros(n_pts, 1);

    for k = 1:(n_slices - 1)
        mask = throttle >= knots(k) & throttle < knots(k+1);
        if any(mask)
            alpha = (throttle(mask) - knots(k)) / (knots(k+1) - knots(k));
            tsfc_out(mask) = tsfc_vals(mask, k)   .* (1 - alpha) ...
                           + tsfc_vals(mask, k+1) .*      alpha;
        end
    end

    edge = throttle >= knots(end);
    tsfc_out(edge) = tsfc_vals(edge, end);

    tsfc = reshape(tsfc_out, sz);
end