function supersonic_airfoil_cg()
% SUPERSONIC_AIRFOIL_CG
%
%   Solves the hypersonic airfoil drag-minimization problem using the
%   custom CG + Armijo optimizer (cg_armijo.m) and compares the result
%   against MATLAB's built-in fminunc.
%
%   Requires:
%     cg_armijo.m            — custom optimizer (same directory)
%     supersonic_airfoil_claude.m  — original file for shared helpers
%       (matlabSetup, foilData, panelCp, etc. must be on the path)
%
%   Usage:
%     supersonic_airfoil_cg()        % runs both solvers, shows comparison

matlabSetup   

% ── Problem parameters (must match supersonic_airfoil_claude.m) ──────────
L            = 1;
N            = 9;
Nr           = 50;
t_max_center = L / 20;
target_cl    = 0.07;
min_area     = 0.05;
alpha_aero   = 5;        % angle of attack, degrees
M_inf        = 7;        % freestream Mach

x_ctrl = linspace(0, L, N+2);
xr     = linspace(0, L, Nr+2);

% Parabolic max-thickness envelope
t_max_vec_fn = @(xc) (t_max_center/0.25) * (0.25 - (xc - 0.5).^2);
t_max_refined = t_max_vec_fn(xr(2:Nr+1)/L);

% ── Initial design vector ─────────────────────────────────────────────────
yt0 = t_max_vec_fn(x_ctrl(2:N+1)/L);
t0  = 2 * yt0;
D0  = [yt0, t0];

fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║     Supersonic Airfoil Optimizer — CG + Armijo vs fminunc   ║\n');
fprintf('╠══════════════════════════════════════════════════════════════╣\n');
fprintf('║  M = %.0f   α = %.0f°   target CL = %.2f   Amin = %.2f     ║\n', ...
        M_inf, alpha_aero, target_cl, min_area);
fprintf('║  N = %d control pts   Nr = %d panels   dim(D) = %d           ║\n', ...
        N, Nr, length(D0));
fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');

% Evaluate initial point
out0 = obj_fn(D0);
fprintf('Initial design:  f = %.5f  |  CL = %.4f  |  CDp = %.4f  |  area = %.4f\n\n', ...
        out0.obj, out0.data.Cl, out0.data.Cdp, out0.data.area);

%  SOLVER 1: fminunc  (baseline — matches supersonic_airfoil_claude.m)

fprintf('════════════════════════════════════════════════════════════════\n');
fprintf('  SOLVER 1: fminunc (BFGS, quasi-Newton)\n');
fprintf('════════════════════════════════════════════════════════════════\n');

fminunc_opts = optimoptions('fminunc', ...
    'Display',          'iter', ...
    'MaxIterations',    300, ...
    'OptimalityTolerance', 1e-5, ...
    'OutputFcn',        @(x,o,s) printFminuncIter(x, o, s));

t_start = tic;
D_bfgs  = fminunc(@(D) obj_fn(D).obj, D0, fminunc_opts);
t_bfgs  = toc(t_start);

out_bfgs = obj_fn(D_bfgs);
fprintf('\n  fminunc result:\n');
print_result(out_bfgs, t_bfgs, target_cl, min_area);


%  SOLVER 2: Custom CG + Armijo  (Algorithm 1)

fprintf('════════════════════════════════════════════════════════════════\n');
fprintf('  SOLVER 2: Custom CG + Armijo Backtracking (Algorithm 1)\n');
fprintf('════════════════════════════════════════════════════════════════\n');

cg_opts.max_iter   = 300;
cg_opts.tol_grad   = 1e-5;
cg_opts.tol_step   = 1e-9;
cg_opts.tol_obj    = 1e-10;
cg_opts.fd_h       = 1e-5;
cg_opts.fd_type    = 'central';    % O(h^2); switch to 'forward' to halve evals
cg_opts.armijo_c   = 1e-4;        % from Algorithm 1
cg_opts.armijo_rho = 0.5;         % from Algorithm 1
cg_opts.armijo_a0  = 1.0;         % from Algorithm 1
cg_opts.restart_n  = 2 * N;       % restart every 2N steps (one full cycle)
cg_opts.display    = 'iter';

t_start  = tic;
[D_cg, cg_hist] = cg_armijo(@(D) obj_fn(D).obj, D0(:), cg_opts);
t_cg     = toc(t_start);

out_cg = obj_fn(D_cg);
fprintf('\n  CG + Armijo result:\n');
print_result(out_cg, t_cg, target_cl, min_area);
fprintf('  Function evals: %d\n', cg_hist.n_feval);


%  COMPARISON TABLE

fprintf('\n════════════════════════════════════════════════════════════════\n');
fprintf('  COMPARISON TABLE\n');
fprintf('════════════════════════════════════════════════════════════════\n');
fprintf('  %-18s  %12s  %12s  %12s\n', 'Metric', 'Initial', 'fminunc', 'CG+Armijo');
fprintf('  %s\n', repmat('─', 1, 60));

metrics = {
    'Objective',    out0.obj,         out_bfgs.obj,         out_cg.obj;
    'CL',           out0.data.Cl,     out_bfgs.data.Cl,     out_cg.data.Cl;
    'CDp',          out0.data.Cdp,    out_bfgs.data.Cdp,    out_cg.data.Cdp;
    'L/D',          out0.data.Cl/out0.data.Cdp, ...
                    out_bfgs.data.Cl/out_bfgs.data.Cdp, ...
                    out_cg.data.Cl/out_cg.data.Cdp;
    'Area',         out0.data.area,   out_bfgs.data.area,   out_cg.data.area;
    'h1 (CL err)',  out0.h1,          out_bfgs.h1,          out_cg.h1;
    'g1 (area)',    out0.g1,          out_bfgs.g1,           out_cg.g1;
    'g2 (thick)',   out0.g2,          out_bfgs.g2,           out_cg.g2;
    'Wall time (s)',NaN,              t_bfgs,                t_cg;
};

for i = 1:size(metrics, 1)
    label  = metrics{i,1};
    v_init = metrics{i,2};
    v_bfgs = metrics{i,3};
    v_cg   = metrics{i,4};
    if isnan(v_init)
        fprintf('  %-18s  %12s  %12.4f  %12.4f\n', label, '—', v_bfgs, v_cg);
    else
        fprintf('  %-18s  %12.5f  %12.5f  %12.5f\n', label, v_init, v_bfgs, v_cg);
    end
end



%  PLOTS

plot_convergence(cg_hist);
plot_airfoil_comparison(out_bfgs, out_cg, xr);
plot_airfoil_detail(out_cg, 'CG + Armijo', xr, x_ctrl, N);

%  NESTED FUNCTIONS — share workspace variables (L, N, Nr, etc.)

    % ── Geometry ────────────────────────────────────────────────────────
    function [ytc, ybc] = get_foil_coords(D)
        D = D(:)';           % force row vector — cg_armijo passes a column
        yt_inner = D(1:N);
        t_inner  = abs(D(N+1:2*N));
        yb_inner = yt_inner - t_inner;

        yt_full = [0, yt_inner, 0];
        yb_full = [0, yb_inner, 0];

        ytc = spline(x_ctrl, yt_full, xr);
        ybc = spline(x_ctrl, yb_full, xr);
    end

    % ── Objective + constraints ──────────────────────────────────────────
    function out = obj_fn(D)
        out = struct();
        [yt, yb] = get_foil_coords(D);

        % Aerodynamic analysis (calls foilData from supersonic_airfoil_claude.m)
        out.data = foilData(xr, yt, yb, alpha_aero, M_inf, D);

        % Constraints (Eqs. 13-16 from the report)
        h1 = abs((out.data.Cl - target_cl) / target_cl);
        g1 = 1 - out.data.area / min_area;

        thickness = yt - yb;
        g2 = norm(max(0, t_max_refined - thickness(2:Nr+1)) / t_max_center);

        out.h1  = h1;
        out.g1  = g1;
        out.g2  = g2;

        % Penalty objective: Eq. 17
        R      = 100;
        penalty = R * max([h1, g1, g2, 0]);
        out.obj = out.data.Cdp + penalty;
    end

    % ── fminunc iteration printer ────────────────────────────────────────
    function stop = printFminuncIter(~, optimValues, state)
        stop = false;
        if strcmp(state, 'iter')
            fprintf('  Iter %3d | f = %.6g | step = %.3g | |grad| = %.3g\n', ...
                optimValues.iteration, optimValues.fval, ...
                optimValues.stepsize, optimValues.firstorderopt);
        end
    end

end % ── main function ────────────────────────────────────────────────────

%  STANDALONE PLOTTING FUNCTIONS

function print_result(out, t_wall, target_cl, min_area)
    fprintf('    Objective   : %.6f\n',  out.obj);
    fprintf('    CL          : %.5f  (target %.2f)\n', out.data.Cl, target_cl);
    fprintf('    CDp         : %.5f\n',  out.data.Cdp);
    fprintf('    L/D         : %.3f\n',  out.data.Cl / out.data.Cdp);
    fprintf('    Area        : %.5f  (min %.2f)\n', out.data.area, min_area);
    fprintf('    h1 (CL err) : %.5f\n',  out.h1);
    fprintf('    g1 (area)   : %.5f\n',  out.g1);
    fprintf('    g2 (thick)  : %.5f\n',  out.g2);
    fprintf('    Wall time   : %.1f s\n', t_wall);
end

function plot_convergence(hist)
% Plots objective and gradient norm histories for CG + Armijo

    figure('Name', 'CG Convergence History', 'Position', [100 100 1000 420]);

    iters = 0 : hist.n_iter;

    subplot(1, 2, 1);
    semilogy(iters, hist.f, 'r-o', 'MarkerSize', 5, 'LineWidth', 1.6);
    xlabel('Iteration'); ylabel('Objective value');
    title('Objective Convergence — CG + Armijo');
    grid on;

    subplot(1, 2, 2);
    semilogy(iters, hist.gnorm, 'b-s', 'MarkerSize', 5, 'LineWidth', 1.6);
    hold on;
    yline(1e-5, 'k--', 'LineWidth', 1, 'Label', 'tol');
    xlabel('Iteration'); ylabel('||\nabla f||');
    title('Gradient Norm — CG + Armijo');
    grid on;

    sgtitle('CG + Armijo: Convergence');
end

function plot_airfoil_comparison(out_bfgs, out_cg, xr)
% Side-by-side airfoil shapes for both solvers

    figure('Name', 'Optimized Airfoil Comparison', 'Position', [100 580 1200 400]);

    solvers = {out_bfgs, out_cg};
    labels  = {'fminunc (BFGS)', 'CG + Armijo'};
    colors  = {[0.2 0.4 0.8], [0.8 0.2 0.2]};

    for s = 1:2
        subplot(1, 2, s);
        data = solvers{s}.data;
        c    = colors{s};

        fill([xr, fliplr(xr)], [data.yt, fliplr(data.yb)], c, ...
             'FaceAlpha', 0.18, 'EdgeColor', c, 'LineWidth', 2);
        hold on;

        axis equal; grid on;
        xlabel('x / L'); ylabel('y / L');
        title(sprintf('%s\nC_L = %.4f  C_{Dp} = %.4f  L/D = %.2f', ...
              labels{s}, data.Cl, data.Cdp, data.Cl/data.Cdp));
        xlim([-0.02, 1.02]);
    end

    sgtitle('Optimized Airfoil Shapes: fminunc vs CG + Armijo');
end

function data = foilData(x, yt, yb, alpha, M, D)
    data = struct();
    % save inputs
    data.D = D;
    data.x = x;
    data.yt = yt;
    data.yb = yb;
    data.alpha = alpha;
    data.M = M;

    data.coords = [x , flip(x(2:end-1)) ; yt , flip(yb(2:end-1))]; % nice for polygon area
    data.area = polyarea(data.coords(1,:), data.coords(2,:)); % internal "volume"

    % get panel areas and normal vectors
    [data.At, data.Nvt] = panelInfo(x, yt, 1);
    [data.Ab, data.Nvb] = panelInfo(x, yb, 0);

    data.A = [data.At , data.Ab];
    data.Nv = [data.Nvt, data.Nvb];

    % compute Cp distrubution
    data.Cpt = panelCp(data.Nvt, alpha, M);
    data.Cpb = panelCp(data.Nvb, alpha, M);

    data.Cp = [data.Cpt, data.Cpb];

    % center points
    data.xm = 0.5*(x(1:end-1) + x(2:end));
    data.ytm = 0.5*(yt(1:end-1) + yt(2:end));
    data.ybm = 0.5*(yb(1:end-1) + yb(2:end));
    data.coords_m = [data.xm, data.xm ; data.ytm, data.ybm]; % coords of just the center points

    % normalization info
    data.L = max(x) - min(x);
    data.A_ref = data.L;

    % get coefficents
    C     = -(data.Nvt*(data.Cpt.*data.At)' + data.Nvb*(data.Cpb.*data.Ab)') / data.A_ref;
    data.Cn    = C(2);
    data.Ca    = C(1);
    data.Cl    = data.Cn*cosd(alpha) - data.Ca*sind(alpha);
    data.Cdp   = data.Ca*cosd(alpha) + data.Cn*sind(alpha);

    % Position vectors from LE to panel midpoints
    r = data.coords_m;                               % [2 x N]
    
    % Force per unit span on each panel: Cp * A * Nv (inward normal = -Nv for force)
    dF = -data.Cp .* data.A .* data.Nv;             % [2 x N]
    
    % 2D cross product r x dF = rx*dFy - ry*dFx (positive nose-up)
    data.Cm_LE = sum(r(1,:).*dF(2,:) - r(2,:).*dF(1,:)) / (data.A_ref * data.L); % counterclockwise
    data.X_cp = data.Cm_LE / data.Cl;

    % More drag functions
    data.Cdw = waveD_Hayes(data.x, data.yt, data.yb, data.A_ref);

    % using atmosphere at 30,000 meters
    % Re = rho * vel * L / mu
    a = 301.7; % m/s
    vel = a * M;
    rho = 1.225 * 0.01503;
    mu = 80.134E-5;
    Re = rho * vel * data.L / mu;

    data.Cdf = skinFriction(data.x, data.yt, data.yb, M, Re, data.A_ref);

    % choose which data inputs to take
    data.Cd_tot = max([data.Cdw, data.Cdp]) + data.Cdf;

    % evaluate thickness
    data.thickness = data.yt - data.yb;
end

function plot_airfoil_detail(out, solver_label, xr, x_ctrl, N)
% Full two-panel figure (shape + Cp distribution) for one solution,
% styled to match the report's Figure 3.

    data = out.data;
    cmap = cool(256);
    Cp_all = [data.Cpt, data.Cpb];
    Cp_lo  = min(Cp_all);
    Cp_hi  = max(Cp_all);

    function rgb = cpColor(v)
        idx = round(1 + 255*(v - Cp_lo) / max(Cp_hi - Cp_lo, 1e-10));
        idx = max(1, min(256, idx));
        rgb = cmap(idx, :);
    end

    figure('Name', ['Airfoil Detail — ' solver_label], ...
           'Position', [200 100 800 650]);

    % ── Subplot 1: airfoil coloured by Cp ─────────────────────────────
    subplot(2, 1, 1); hold on;
    for k = 1 : length(data.Cpt)
        line([xr(k), xr(k+1)], [data.yt(k), data.yt(k+1)], ...
             'Color', cpColor(data.Cpt(k)), 'LineWidth', 3);
        line([xr(k), xr(k+1)], [data.yb(k), data.yb(k+1)], ...
             'Color', cpColor(data.Cpb(k)), 'LineWidth', 3);
    end
    line([xr(1),   xr(1)  ], [data.yt(1),   data.yb(1)  ], 'Color', [.4 .4 .4], 'LineWidth', 1);
    line([xr(end), xr(end)], [data.yt(end), data.yb(end)], 'Color', [.4 .4 .4], 'LineWidth', 1);

    colormap(gca, cmap); clim([Cp_lo, Cp_hi]);
    cb = colorbar; cb.Label.String = 'C_p';
    axis equal; grid on;
    xlabel('x / L'); ylabel('y / L');
    title(sprintf('Airfoil — %s   (α = 5°, M = 7)', solver_label));

    % ── Subplot 2: Cp distribution ────────────────────────────────────
    subplot(2, 1, 2); hold on;
    xm = 0.5*(xr(1:end-1) + xr(2:end));
    plot(xm, data.Cpt, 'b.-', 'MarkerSize', 9, 'LineWidth', 1.4, 'DisplayName', 'C_p top');
    plot(xm, data.Cpb, 'r.-', 'MarkerSize', 9, 'LineWidth', 1.4, 'DisplayName', 'C_p bottom');
    fill([xm, fliplr(xm)], [data.Cpb, fliplr(data.Cpt)], [0.85 0.85 1], ...
         'FaceAlpha', 0.3, 'EdgeColor', 'none', 'HandleVisibility', 'off');

    set(gca, 'YDir', 'reverse');
    grid on;
    xlabel('x / L'); ylabel('C_p');
    title('Pressure Coefficient Distribution');
    legend('Location', 'northeast');

    text(0.97, 0.05, ...
         sprintf('  C_L = %+.4f\n  C_{Dp} = %+.4f\n  L/D = %+.2f  ', ...
                 data.Cl, data.Cdp, data.Cl/data.Cdp), ...
         'Units', 'normalized', 'HorizontalAlignment', 'right', ...
         'VerticalAlignment', 'bottom', 'FontSize', 10, 'FontName', 'Courier', ...
         'BackgroundColor', [1 1 1 0.85], 'EdgeColor', [0.5 0.5 0.5], 'Margin', 5);
end

function [A, Nv] = panelInfo(x, y, is_top)
    % A -> area/depth for each panel
    % N -> 2 element normal vector with x downstream and y up
    %   * both are one element less than x and y

    % is_top (0/1) to designate normal vector

    A = sqrt( (x(1:end-1) - x(2:end)).^2 + (y(1:end-1) - y(2:end)).^2 ); % area from panel lengths
        % can use for normalization

    Nv = [y(1:end-1) - y(2:end) ; x(2:end) - x(1:end-1)]./A;

    if ~is_top
        Nv = -Nv; % need to flip if on the bottop
    end
end

function Cp = panelCp(Nv, alpha, M)
% Hybrid tangent-wedge / Prandtl-Meyer panel pressure coefficient.
%
% Compression panels  (theta > 0): tangent-wedge oblique shock relations.
%   If theta exceeds the detachment limit, falls back to modified Newtonian
%   (DeJarnette Cp_max * sin^2) which is appropriate for blunt/detached cases.
%
% Expansion panels    (theta < 0): Prandtl-Meyer isentropic expansion from
%   freestream.  Replaces the hard zero of pure Newtonian, giving a smooth,
%   physically-based Cp on the leeward surface.
%
% Inputs
%   Nv    [2 x N]  unit outward normal vectors (x downstream, y up)
%   alpha [scalar] angle of attack, degrees
%   M     [scalar] freestream Mach number  (must be > 1)
%
% Output
%   Cp    [1 x N]  pressure coefficient on each panel

    gam = 1.4;

 
    dir   = [cosd(alpha); sind(alpha)];          % [2x1]
    cosA  = dir' * Nv;                           % [1xN], dot with outward normal
    % angle between flow and normal; subtract 90 deg to get surface deflection
    theta = acos(max(-1, min(1, cosA))) - pi/2;  % [1xN], radians
    %  theta > 0  -> compression (flow pushed into surface)
    %  theta < 0  -> expansion   (flow turns away from surface)

    Cp = zeros(1, length(theta));

    % Modified-Newtonian Cp_max (DeJarnette) — used as fallback
    K      = sqrt(M^2 - 1);
    Cp_max = 1 + ((gam+1)*K^2 + 2) * log((gam+1)/2 + 1/K^2) ...
                 / ((gam-1)*K^2 + 2);

    % Freestream Prandtl-Meyer function nu_inf (radians)
    nu_inf = prandtlMeyerNu(M, gam);

    % Maximum deflection angle for an attached shock at this Mach number
    theta_max = maxDeflectionAngle(M, gam);   % radians

    for i = 1:length(theta)
        th = theta(i);

        if th >= 0

            if th >= theta_max
                % Detached shock — oblique shock equations have no real
                % solution.  Fall back to modified Newtonian; it is
                % calibrated to stagnation and handles blunt geometries
                % reasonably.  Avoids NaN / hard discontinuity.
                Cp(i) = Cp_max * sin(th)^2;
            else
                % Solve theta-beta-M for weak-shock beta
                beta = solveBeta(th, M, gam);          % shock angle, rad

                % Normal component of Mach upstream of shock
                Mn1  = M * sin(beta);

                % Normal shock pressure ratio p2/p1
                p2p1 = 1 + 2*gam/(gam+1) * (Mn1^2 - 1);

                % Cp from pressure ratio
                q_inf = 0.5 * gam * M^2;              % dynamic pressure ratio
                Cp(i) = (p2p1 - 1) / q_inf;
            end

        else
            % ---------------------------------------------------------- %
            %  Expansion: Prandtl-Meyer isentropic expansion              %
 
            nu2 = nu_inf + abs(th);                    % expanded PM function

            % Invert nu -> M2. nu_max for gam=1.4 is ~130.45 deg.
            % Clamp to avoid requesting supersonic turn beyond physical limit.
            nu_max = pi/2 * (sqrt((gam+1)/(gam-1)) - 1);
            nu2    = min(nu2, 0.9999 * nu_max);

            M2     = invertPrandtlMeyer(nu2, gam);

            % Isentropic pressure ratio p/p0
            p0_over_p  = @(Mx) (1 + (gam-1)/2 * Mx^2)^(gam/(gam-1));
            p2p1       = p0_over_p(M) / p0_over_p(M2);   % p2/p1, < 1

            q_inf = 0.5 * gam * M^2;
            Cp(i) = (p2p1 - 1) / q_inf;                   % negative, smooth
        end
    end
end

function nu = prandtlMeyerNu(M, gam)
    r   = sqrt((gam+1)/(gam-1));
    nu  = r * atan(sqrt((gam-1)/(gam+1) * (M^2-1))) - atan(sqrt(M^2-1));
end

function M = invertPrandtlMeyer(nu_target, gam)
    % Initial guess via Hall (1962) approximation
    A  = (gam+1)/(gam-1);
    nu_max = pi/2 * (sqrt(A) - 1);
    X  = nu_target / nu_max;
    M  = 1 + 1.2276*X + 0.4919*X^2 + 2.4009*X^3 - 5.2313*X^4 + 4.0754*X^5;
    M  = max(1.001, M);

    % Newton refinement  (typically 3-5 iterations)
    for k = 1:20
        nu_k   = prandtlMeyerNu(M, gam);
        dnu_dM = sqrt(M^2-1) / (M * (1 + (gam-1)/2 * M^2));   % analytical deriv
        dM     = (nu_target - nu_k) / dnu_dM;
        M      = M + dM;
        M      = max(1.001, M);
        if abs(dM) < 1e-10; break; end
    end
end

function theta_max = maxDeflectionAngle(M, gam)
    % Sweep beta from Mach angle to 89 deg; theta peaks then falls
    mu   = asin(1/M);                            % Mach angle
    bvec = linspace(mu + 1e-4, pi/2 - 1e-4, 2000);
    th   = thetaFromBeta(bvec, M, gam);
    theta_max = max(th);
end

function th = thetaFromBeta(beta, M, gam)
    th = atan2( 2*cot(beta).*(M^2*sin(beta).^2 - 1), ...
                M^2*(gam + cos(2*beta)) + 2 );
    th = max(th, 0);   % enforce non-negative (weak-shock branch)
end

function beta = solveBeta(theta, M, gam)
    mu = asin(1/M);                % lower bound: Mach angle (beta at theta=0+)

    % Find beta_at_theta_max to use as upper bound
    bvec  = linspace(mu + 1e-6, pi/2 - 1e-6, 4000);
    th    = thetaFromBeta(bvec, M, gam);
    [~, idx] = max(th);
    beta_hi = bvec(idx);           % beta corresponding to theta_max

    % Bisection on  f(beta) = theta(beta) - theta_target
    blo = mu + 1e-8;
    bhi = beta_hi;
    for k = 1:60
        bmid = 0.5*(blo + bhi);
        f    = thetaFromBeta(bmid, M, gam) - theta;
        if f > 0
            bhi = bmid;
        else
            blo = bmid;
        end
        if (bhi - blo) < 1e-12; break; end
    end
    beta = 0.5*(blo + bhi);
end

function Cdw = waveD_Hayes(x, yt, yb, A_ref)
    S = yt - yb;

    % Enforce physical constraints before computing
    S = max(S, 0);                                 % no negative thickness

    % Smooth S before differentiating — gradient of noisy S'' is unreliable
    % on weird geometries. Simple 3-point moving average is enough.
    S = pleaseWork(S);

    % Non-uniform spacing safe second derivative
    N   = length(x);
    Spp = zeros(1, N);
    for k = 2:N-1
        h1 = x(k)   - x(k-1);
        h2 = x(k+1) - x(k);
        Spp(k) = 2*(S(k+1)/h2 - S(k)*(1/h1 + 1/h2) + S(k-1)/h1) / (h1 + h2);
    end
    % Endpoints: natural spline condition (S'' = 0 at LE and TE)
    % This is physically correct — thickness tapers to zero at both ends
    Spp(1) = 0;
    Spp(N) = 0;

    % Hayes double integral — vectorized
    [Xi, Xj]   = meshgrid(x, x);
    [Si, Sj]   = meshgrid(Spp, Spp);
    dist        = abs(Xi - Xj);
    off_diag    = dist > 0;                        % exclude i==j

    dx_avg = (x(end) - x(1)) / (N - 1);           % representative spacing for quadrature
    I = sum(sum(Si .* Sj .* log(dist + ~off_diag) .* off_diag)) * dx_avg^2;

    Cdw = max(-I / (2*pi*A_ref), 0);              % clamp — negative wave drag is unphysical
end

function Ss = pleaseWork(S)
    % Simple 3-point moving average, preserving endpoints
    Ss      = S;
    Ss(2:end-1) = (S(1:end-2) + S(2:end-1) + S(3:end)) / 3;
end

function Cdf = skinFriction(x, yt, yb, M, Re_L, A_ref)
    % Wetted area per unit span (arc length of both surfaces)
    dx   = diff(x);
    dyt  = diff(yt);
    dyb  = diff(yb);
    S_wet = sum(sqrt(dx.^2 + dyt.^2)) + sum(sqrt(dx.^2 + dyb.^2));

    % Compressible turbulent Cf via Van Driest II (or simple Eckert reference temp)
    % Simple Eckert reference temperature correction:
    Tw_ratio = 1;
    T_ratio = 1 + 0.035*M^2 + 0.45*(Tw_ratio - 1);  % Tw_ratio = Twall/T_inf, use 1 for adiabatic
    Re_star = Re_L / T_ratio;                          % reference Reynolds number

    % Turbulent flat plate (Schlichting):
    Cf_star = 0.074 / Re_star^0.2;                    % turbulent
    % or laminar:  Cf_star = 1.328 / sqrt(Re_star);

    % Scale to your reference area
    Cdf = Cf_star * S_wet / A_ref;
end