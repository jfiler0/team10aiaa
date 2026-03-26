function interpObj = build_engine_lookup(engine_name)

% initially written by a human then improved with claude

% Builds a spline-based lookup for (Mach, Altitude, Throttle) -> Thrust / TSFC
% Throttle is normalized: 0–0.9 = dry, 0.9–1.0 = afterburner (linear in each regime)
% Supports vector/matrix inputs via griddedInterpolant

    funcDir      = fileparts(mfilename('fullpath'));
    sweepFilePath = fullfile(funcDir, "NPSS_Sweeps", engine_name + '.mat');

    if ~isfile(sweepFilePath)
        error("NPSS Sweep for engine '%s' does not exist at: '%s'", engine_name, sweepFilePath);
    end

    sweepFile = load(sweepFilePath);
    data      = sweepFile.DataTable;

    % ------------------------------------------------------------------ %
    %  Step 1 — Compute normalised throttle for every data point          %
    % ------------------------------------------------------------------ %
    max_military = data.PLA == 100;
    max_ab       = data.PLA == 150;

    % Natural-neighbour scattered interpolants for mil / AB reference thrust
    F_mil = scatteredInterpolant( ...
        data.("Mach Number")(max_military), ...
        data.Altitude(max_military), ...
        data.Thrust(max_military), 'natural', 'linear');

    F_ab = scatteredInterpolant( ...
        data.("Mach Number")(max_ab), ...
        data.Altitude(max_ab), ...
        data.Thrust(max_ab), 'natural', 'linear');

    mach = data.("Mach Number");
    alt  = data.Altitude;

    mil_thrust = F_mil(mach, alt);
    ab_thrust  = F_ab(mach, alt);

    dry_mask = data.PLA <= 100;
    data.throttle = zeros(height(data), 1);
    data.throttle( dry_mask) = 0.9 .* data.Thrust( dry_mask) ./ mil_thrust( dry_mask);
    data.throttle(~dry_mask) = 0.9 + 0.1 .* ...
        (data.Thrust(~dry_mask) - mil_thrust(~dry_mask)) ./ ...
        (ab_thrust(~dry_mask)   - mil_thrust(~dry_mask));

    % ------------------------------------------------------------------ %
    %  Step 2 — Scattered interpolants (natural) to fill the broken grid  %
    % ------------------------------------------------------------------ %
    F_thrust_sc = scatteredInterpolant(mach, alt, data.throttle, data.Thrust, 'natural', 'linear');
    F_tsfc_sc   = scatteredInterpolant(mach, alt, data.throttle, data.TSFC,   'natural', 'linear');

    % ------------------------------------------------------------------ %
    %  Step 3 — Resample onto a clean regular grid                        %
    % ------------------------------------------------------------------ %
    n_mach     = 60;
    n_alt      = 60;
    n_throttle = 40;

    mach_vec     = linspace(min(mach),           max(mach),           n_mach);
    alt_vec      = linspace(min(alt),            max(alt),            n_alt);
    throttle_vec = linspace(0,                   1,                   n_throttle);

    [M, A, T] = ndgrid(mach_vec, alt_vec, throttle_vec);

    thrust_grid = F_thrust_sc(M, A, T);
    tsfc_grid   = F_tsfc_sc(M, A, T);

    % ------------------------------------------------------------------ %
    %  Step 4 — 3-D Gaussian smoothing to remove noise                   %
    %  Sigma of 1 grid-cell; tune up if the surface still looks rough    %
    % ------------------------------------------------------------------ %
    sigma = 1.0;
    thrust_grid = imgaussfilt3(thrust_grid, sigma);
    tsfc_grid   = imgaussfilt3(tsfc_grid,   sigma);

    % ------------------------------------------------------------------ %
    %  Step 5 — Spline griddedInterpolant (supports vector inputs)       %
    % ------------------------------------------------------------------ %
    interpObj      = struct();
    interpObj.TA   = griddedInterpolant({mach_vec, alt_vec, throttle_vec}, thrust_grid, 'spline');
    interpObj.TSFC = griddedInterpolant({mach_vec, alt_vec, throttle_vec}, tsfc_grid,   'spline');
end