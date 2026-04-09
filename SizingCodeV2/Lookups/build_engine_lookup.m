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

    % ------------------------------------------------------------------ %
    %  Step 1 — Gaussian kernel smooth on the raw scattered points        %
    %  Coordinates are normalised before distance computation so that     %
    %  mach, alt, and PLA axes contribute equally                         %
    %  sigma controls smoothing width in normalised units (0-1 per axis)  %
    % ------------------------------------------------------------------ %
    sigma_scatter = 0.1;   % tune: larger = more smoothing

    coords = [mach, alt, pla];
    coords_norm = (coords - min(coords)) ./ (max(coords) - min(coords));

    % Pairwise squared distances in normalised space — (n_pts x n_pts)
    D2 = sum((permute(coords_norm, [1 3 2]) - permute(coords_norm, [3 1 2])).^2, 3);
    W  = exp(-D2 / (2 * sigma_scatter^2));   % Gaussian weights

    % Normalised weighted average for each output quantity
    W_sum          = sum(W, 2);
    thrust = lb2N(data.Thrust); % conversion
    thrust_smooth  = (W * thrust) ./ W_sum;
    tsfc_smooth    = (W * data.TSFC)   ./ W_sum;

    % ------------------------------------------------------------------ %
    %  Step 2 — Scattered interpolants from smoothed data                 %
    % ------------------------------------------------------------------ %
    F_thrust = scatteredInterpolant(mach, alt, pla, thrust_smooth, 'natural', 'linear');
    F_tsfc   = scatteredInterpolant(mach, alt, pla, tsfc_smooth,   'natural', 'linear');

    % ------------------------------------------------------------------ %
    %  Regular Mach/Alt grid (shared by all slices)                       %
    % ------------------------------------------------------------------ %
    n_mach   = 40;
    n_alt    = 40;
    mach_vec = linspace(min(mach), max(mach), n_mach);
    alt_vec  = linspace(min(alt),  max(alt),  n_alt);
    [M, A]   = ndgrid(mach_vec, alt_vec);

    % ------------------------------------------------------------------ %
    %  Step 3 — Thrust: 3 boundary slices, spline in Mach/Alt            %
    % ------------------------------------------------------------------ %
    pla_min = min(pla);

    thrust_idle = eval_slice(F_thrust, M, A, pla_min);
    thrust_mil  = eval_slice(F_thrust, M, A, 100);
    thrust_ab   = eval_slice(F_thrust, M, A, 150);

    I_T_idle = griddedInterpolant({mach_vec, alt_vec}, thrust_idle, 'spline');
    I_T_mil  = griddedInterpolant({mach_vec, alt_vec}, thrust_mil,  'spline');
    I_T_ab   = griddedInterpolant({mach_vec, alt_vec}, thrust_ab,   'spline');

    % ------------------------------------------------------------------ %
    %  Step 4 — TSFC: stack of 2D slices across PLA                      %
    % ------------------------------------------------------------------ %
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

        tsfc_slices{k} = griddedInterpolant({mach_vec, alt_vec}, tsfc_k, 'spline');
    end

    throttle_knots = sort(throttle_knots);

    % ------------------------------------------------------------------ %
    %  Output                                                             %
    % ------------------------------------------------------------------ %
    interpObj.TA   = @(m, a, t) query_thrust(m, a, t, I_T_idle, I_T_mil, I_T_ab);
    interpObj.TSFC = @(m, a, t) query_tsfc(  m, a, t, tsfc_slices, throttle_knots);

    devObj = struct();

    devObj.npss.mach = mach; % mach inputs from npss
    devObj.npss.alt = alt; % altitude inputs from npss (in m)
    devObj.npss.pla = pla; % throttle inputs from npss (0-150)
    devObj.npss.thrust = thrust; % thrust output from npss (N)
    devObj.npss.tsfc = data.TSFC; % tsfc output from npss (kg.N/s)

    devObj.npss.thrust_smooth = thrust_smooth; % gaussian smoothing applied
    devObj.npss.tsfc_smooth = tsfc_smooth; % gaussian smoothing applied

    devObj.gridded.mach = mach_vec; % new machs to interp to
    devObj.gridded.alt = alt_vec; % new machs to interp to
    
end


% ===================================================================== %
%  Helpers                                                               %
% ===================================================================== %

function grid = eval_slice(F, M, A, pla_val)
    % No grid smoothing needed — smoothing was done on the raw data
    grid = F(M, A, pla_val * ones(size(M)));
end

% --------------------------------------------------------------------- %
function thrust = query_thrust(mach, alt, throttle, I_idle, I_mil, I_ab)
    sz       = size(mach);
    mach     = mach(:);  alt = alt(:);  throttle = throttle(:);
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
function tsfc = query_tsfc(mach, alt, throttle, slices, knots)
    sz       = size(mach);
    mach     = mach(:);  alt = alt(:);  throttle = throttle(:);
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

    below = throttle < knots(1);
    above = throttle > knots(end);

    if any(below)
        slope = (tsfc_vals(:,2) - tsfc_vals(:,1)) / (knots(2) - knots(1));
        tsfc_out(below) = tsfc_vals(below,1) + slope(below) .* (throttle(below) - knots(1));
    end

    if any(above)
        slope = (tsfc_vals(:,end) - tsfc_vals(:,end-1)) / (knots(end) - knots(end-1));
        tsfc_out(above) = tsfc_vals(above,end) + slope(above) .* (throttle(above) - knots(end));
    end

    tsfc = reshape(tsfc_out, sz);
end