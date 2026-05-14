function Ds = supersonic_airfoil_sweep()
    % making this its own function we can move some functions to be internal

matlabSetup

% The starting and ending points remain fixed at (0,0) and (L,0).
% The design vector (D) is 2N long. The first half specifies the position of the top of the airfoil (not the start or end)
%   The second half specifies the thickness (the absolute value is taken) which is used to compute the bottom surface

L = 1; % meters - length of the airfoil
N = 3; % number of centeral points (total points is N + 2)
Nr = 50; % number of points after interpolation
t_max_center = L/20; % parabolic curve with t constraint going to 0 and start and end

target_cl = 0.005; % 0.07
min_area = 0.001;
alpha = 1;
M = 7;

x = linspace(0, L, N+2); % initialize point x values
xr = linspace(0, L, Nr+2); % initialize refined x values
t_max_vec = t_max(xr(2:Nr+1)/L); % used in constraints
yt0 = 1*t_max(x(2:N+1)/L); % initialize initial y values as 2x the thickness constraint
t0 = 2*yt0;
D0 = [yt0 , t0]; % starting design vector is the top coordinates , thickness

options = optimoptions('fminunc', 'Display', 'iter', 'OutputFcn', @(x,o,s) printIter(x,o,s));

%% SWEEP 1: Varying target CL
cl_vec = linspace(0.01, 0.03, 5);

figure; hold on;
colors = jet(length(cl_vec));
for i = 1:length(cl_vec)
    target_cl = cl_vec(i);
    Ds = fminunc(@fun, D0, options);
    out = obj(Ds);
    plot(out.data.xm, out.data.ytm, '-', 'Color', colors(i, :), DisplayName=sprintf("CL = %.3g", target_cl))
    plot(out.data.xm, out.data.ybm, '-', 'Color', colors(i, :), HandleVisibility='off')
end
grid on;
axis tight; axis equal;
legend('Location', "eastoutside"); xlabel("X"); ylabel("Y");
target_cl = 0.005;

%% SWEEP 2: Varying Mach Number
% M_vec = linspace(5, 15, 5);
% 
% figure; hold on;
% colors = jet(length(M_vec));
% for i = 1:length(M_vec)
%     M = M_vec(i);
%     Ds = fminunc(@fun, D0, options);
%     out = obj(Ds);
%     plot(out.data.xm, out.data.ytm, '-', 'Color', colors(i, :), DisplayName=sprintf("M = %.2f", M))
%     plot(out.data.xm, out.data.ybm, '-', 'Color', colors(i, :), HandleVisibility='off')
% end
% grid on;
% axis tight; axis equal;
% legend('Location', "eastoutside"); xlabel("X"); ylabel("Y");
% target_cl = 0.005;


% fprintf("Final OBJ val: %.4g\n", out.obj);
% fprintf("H1 = %.3g | CL = %.3f == %.3f\n", out.h1, out.data.Cl, target_cl)
% fprintf("G1 = %.3g | area = %.3f >= %.3f\n", out.g1, out.data.area, min_area)
% fprintf("G2 = %.3g | (thickness)\n", out.g2)

fprintf("\n")

function stop = printIter(x, optimValues, state)
    stop = false;
    if strcmp(state, 'iter')
        fprintf('Iter %3d | f = %.6g | step = %.3g | grad = %.3g\n', ...
            optimValues.iteration, optimValues.fval, ...
            optimValues.stepsize, optimValues.firstorderopt);
    end
end

function t = t_max(x_c)
    a = t_max_center / (0.5^2);
    t = a*0.5^2 + -a*(x_c - 0.5).^2;
end

function [ytc, ybc] = get_foil_coords(D)
    % input design vector and inherit length + N
    ytc = D(1:N);
    ybc = ytc - D( (N+1):(2*N) );

    % append 0 to both sides
    ytc = [0 , ytc, 0];
    ybc = [0 , ybc, 0]; 

    ytc = spline(x, ytc, xr);
    ybc = spline(x, ybc, xr);
end

% evaluate drag as some sort of 2d sears hack with rate of change of curvature
%       + skin friction estimation with surface area
% evaluate lift as newtonian flow approximation
% calculate internal volume for constraint

function val = fun(D)
    out = obj(D);
    val = out.obj;
end

function out = obj(D)
    out = struct();
    
    [yt, yb] = get_foil_coords(D);
    out.yt = yt; out.yb = yb;

    out.data = foilData(xr, yt, yb, alpha, M, D);

    % OBJECTIVE: Minimize CD_tot
    % CONSTRAINT TO:
    %   a target CL, a minimum area

    h1 = abs( (out.data.Cl - target_cl)/target_cl ); % equality constraint
    g1 = 1 - out.data.area/min_area;
    thickness = out.yt - out.yb;
    g2 = norm( max(0, t_max_vec - thickness(2:Nr+1))/t_max_center );

    % obj = out.data.Cd_tot;
    obj = out.data.Cdp;

    R = 10;
    obj = obj + R * max([h1, g1, g2, 0]);
    out.obj = obj;
    out.h1 = h1; out.g1 = g1; out.g2 = g2;
end

function visualizeData(data)
    % --- Colormap setup ---
    cmap   = cool(256);
    Cp_all = [data.Cpt, data.Cpb];
    Cp_lo  = min(Cp_all);
    Cp_hi  = max(Cp_all);

    function rgb = cpColor(Cp_val)
        idx = round(1 + 255*(Cp_val - Cp_lo) / max(Cp_hi - Cp_lo, 1e-10));
        idx = max(1, min(256, idx));
        rgb = cmap(idx, :);
    end

    figure;

    % =========================================================
    % Subplot 1: Airfoil with panel edges coloured by Cp
    % =========================================================
    subplot(2,1,1); hold on;

    % Draw each panel as a coloured line segment only
    for k = 1:length(data.xm)
        % Top panel
        line([data.x(k), data.x(k+1)], [data.yt(k), data.yt(k+1)], ...
             'Color', cpColor(data.Cpt(k)), 'LineWidth', 3);
        % Bottom panel
        line([data.x(k), data.x(k+1)], [data.yb(k), data.yb(k+1)], ...
             'Color', cpColor(data.Cpb(k)), 'LineWidth', 3);
    end

    % Leading and trailing edge connectors
    line([data.x(1),   data.x(1)  ], [data.yt(1),   data.yb(1)  ], 'Color', [0.4 0.4 0.4], 'LineWidth', 1);
    line([data.x(end), data.x(end)], [data.yt(end), data.yb(end)], 'Color', [0.4 0.4 0.4], 'LineWidth', 1);

    colormap(gca, cmap); clim([Cp_lo, Cp_hi]);
    cb = colorbar; cb.Label.String = 'C_p';

    axis equal; grid on;
    xlabel('$x / L$'); ylabel('$y / L$');
    title(sprintf('Airfoil - alpha = %g deg,  M = %g', data.alpha, data.M));

    % =========================================================
    % Subplot 2: Cp distribution with annotation
    % =========================================================
    subplot(2,1,2); hold on;

    plot(data.xm, data.Cpt, 'b.-', 'MarkerSize', 10, 'LineWidth', 1.4, 'DisplayName', 'C_p top');
    plot(data.xm, data.Cpb, 'r.-', 'MarkerSize', 10, 'LineWidth', 1.4, 'DisplayName', 'C_p bottom');
    fill([data.xm, fliplr(data.xm)], [data.Cpb, fliplr(data.Cpt)], [0.85 0.85 1.0], ...
         'FaceAlpha', 0.35, 'EdgeColor', 'none', 'HandleVisibility', 'off');

    set(gca, 'YDir', 'reverse');
    grid on; xlabel('$x / L$'); ylabel('$C_p$');
    title('Pressure coefficient distribution');
    legend('Location', 'northeast');

    text(0.98, 0.05, ...
         sprintf('  $C_L$ = %+.4f\n  $C_{Dp}$ = %+.4f\n  L/D   = %+.2f  ', data.Cl, data.Cdp, data.Cl/data.Cdp), ...
         'Units', 'normalized', 'HorizontalAlignment', 'right', ...
         'VerticalAlignment', 'bottom', 'FontSize', 10, 'FontName', 'Courier', ...
         'BackgroundColor', [1 1 1 0.85], 'EdgeColor', [0.5 0.5 0.5], 'Margin', 5);

    figure;
    hold on
    plot(xr, data.yt, 'r.', DisplayName="Spline Point")
    plot(xr, data.yb, 'r.', HandleVisibility='off')

    ytc = data.D(1:N);
    ybc = ytc - data.D( (N+1):(2*N) );

    plot(x(2:N+1), ytc, 'kx', DisplayName="Control Point")
    plot(x(2:N+1), ybc, 'kx', HandleVisibility='off')
    
    axis equal
    legend(Location="northwest")
    grid on; xlabel('$x / L$'); ylabel('$y / L$');

end

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

    data.Cdf = skinFriction(data.x, data.yt, data.yb, alpha, Re, data.A_ref);

    % choose which data inputs to take
    data.Cd_tot = max([data.Cdw, data.Cdp]) + data.Cdf;

    % evaluate thickness
    data.thickness = data.yt - data.yb;
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

    % ------------------------------------------------------------------ %
    %  Flow direction unit vector and panel deflection angles             %
    % ------------------------------------------------------------------ %
    dir   = [cosd(alpha); sind(alpha)];          % [2x1]
    cosA  = dir' * Nv;                           % [1xN], dot with outward normal
    % angle between flow and normal; subtract 90 deg to get surface deflection
    theta = acos(max(-1, min(1, cosA))) - pi/2;  % [1xN], radians
    %  theta > 0  -> compression (flow pushed into surface)
    %  theta < 0  -> expansion   (flow turns away from surface)

    Cp = zeros(1, length(theta));

    % ------------------------------------------------------------------ %
    %  Pre-compute reusable freestream quantities                         %
    % ------------------------------------------------------------------ %
    % Modified-Newtonian Cp_max (DeJarnette) — used as fallback
    K      = sqrt(M^2 - 1);
    Cp_max = 1 + ((gam+1)*K^2 + 2) * log((gam+1)/2 + 1/K^2) ...
                 / ((gam-1)*K^2 + 2);

    % Freestream Prandtl-Meyer function nu_inf (radians)
    nu_inf = prandtlMeyerNu(M, gam);

    % Maximum deflection angle for an attached shock at this Mach number
    theta_max = maxDeflectionAngle(M, gam);   % radians

    % ------------------------------------------------------------------ %
    %  Loop over panels                                                   %
    % ------------------------------------------------------------------ %
    for i = 1:length(theta)
        th = theta(i);

        if th >= 0
            % ---------------------------------------------------------- %
            %  Compression: tangent-wedge oblique shock                   %
            % ---------------------------------------------------------- %
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
            %                                                             %
            %  The flow turns |theta| away from the surface starting      %
            %  from freestream conditions.  Using freestream as the       %
            %  reference is consistent with the local-inclination         %
            %  assumption (each panel sees undisturbed flow).             %
            % ---------------------------------------------------------- %
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


% ======================================================================= %
%  Helper: Prandtl-Meyer function  nu(M)  [radians]                       %
% ======================================================================= %
function nu = prandtlMeyerNu(M, gam)
    r   = sqrt((gam+1)/(gam-1));
    nu  = r * atan(sqrt((gam-1)/(gam+1) * (M^2-1))) - atan(sqrt(M^2-1));
end


% ======================================================================= %
%  Helper: invert nu -> M  (Newton's method on prandtlMeyerNu)            %
% ======================================================================= %
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


% ======================================================================= %
%  Helper: maximum attached-shock deflection angle theta_max(M)  [rad]    %
%                                                                          %
%  At theta_max the discriminant of the theta-beta-M cubic is zero.       %
%  Found by scanning beta and tracking d(theta)/d(beta) = 0.              %
% ======================================================================= %
function theta_max = maxDeflectionAngle(M, gam)
    % Sweep beta from Mach angle to 89 deg; theta peaks then falls
    mu   = asin(1/M);                            % Mach angle
    bvec = linspace(mu + 1e-4, pi/2 - 1e-4, 2000);
    th   = thetaFromBeta(bvec, M, gam);
    theta_max = max(th);
end


% ======================================================================= %
%  Helper: deflection angle from shock angle  (theta-beta-M formula)      %
% ======================================================================= %
function th = thetaFromBeta(beta, M, gam)
    th = atan2( 2*cot(beta).*(M^2*sin(beta).^2 - 1), ...
                M^2*(gam + cos(2*beta)) + 2 );
    th = max(th, 0);   % enforce non-negative (weak-shock branch)
end


% ======================================================================= %
%  Helper: solve theta-beta-M for weak-shock beta given theta             %
%                                                                          %
%  Uses bisection on the monotone portion of theta(beta) below theta_max. %
%  Robust, no chance of converging to the strong-shock branch.            %
% ======================================================================= %
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
    S = smooth3pt(S);

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

function Ss = smooth3pt(S)
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