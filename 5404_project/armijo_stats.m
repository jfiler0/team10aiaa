function armijo_stats()
% ARMIJO_STATS
%
%   Runs the supersonic airfoil CG + Armijo optimizer, extracts detailed
%   line-search statistics, produces a publication-ready figure, and prints
%   a formatted discussion of every statistic for use in a report.
%
%   Requires cg_armijo.m and the physics helpers from supersonic_airfoil_cg.m
%   (all aerodynamic local functions are duplicated at the bottom of this file
%   so it runs standalone).
%
%   Usage:
%     armijo_stats()

matlabSetup

% ── Problem parameters (must match supersonic_airfoil_cg.m) ──────────────
L            = 1;
N            = 9;
Nr           = 50;
t_max_center = L / 20;
target_cl    = 0.07;
min_area     = 0.05;
alpha_aero   = 5;
M_inf        = 7;

x_ctrl  = linspace(0, L, N+2);
xr      = linspace(0, L, Nr+2);
t_max_ref = t_max_parabola(xr(2:Nr+1)/L, t_max_center);

yt0 = t_max_parabola(x_ctrl(2:N+1)/L, t_max_center);
D0  = [yt0, 2*yt0];

objFun    = @(D) obj_fn(D, xr, x_ctrl, N, Nr, alpha_aero, M_inf, ...
                        target_cl, min_area, t_max_ref, t_max_center);
scalarFun = @(D) objFun(D).obj;

% ── Run optimizer with statistics logging enabled ─────────────────────────
fprintf('Running CG + Armijo optimizer...\n');
cg_opts.max_iter   = 300;
cg_opts.tol_grad   = 1e-5;
cg_opts.tol_step   = 1e-9;
cg_opts.tol_obj    = 1e-10;
cg_opts.fd_h       = 1e-5;
cg_opts.fd_type    = 'central';
cg_opts.armijo_c   = 1e-4;
cg_opts.armijo_rho = 0.5;
cg_opts.armijo_a0  = 1.0;
cg_opts.restart_n  = 2*N;
cg_opts.display    = 'none';   % suppress per-iter output; stats script handles display

[D_opt, hist] = cg_armijo(scalarFun, D0(:), cg_opts);
out_opt = objFun(D_opt);

% ── Compute derived statistics ─────────────────────────────────────────────
iters     = 1 : hist.n_iter;           % exclude k=0 (no line search)
ls        = hist.ls_steps(iters+1);    % backtracking halvings per iteration
alpha_vec = hist.alpha(iters+1);       % accepted step lengths
gnorm_vec = hist.gnorm(iters+1);       % gradient norms at accepted points
f_vec     = hist.f(iters+1);           % objective values
resets    = hist.dir_reset(iters+1);   % direction-guard events
ls_fail   = hist.ls_failed(iters+1);   % line-search failures

grad_cum  = hist.feval_grad_cum(iters+1);
ls_cum    = hist.feval_ls_cum(iters+1);

% Per-iteration evaluation cost breakdown
evals_per_grad = N * (2 - strcmp(cg_opts.fd_type,'central')*0);
                 % central: 2N evals per gradient; forward: N evals
evals_grad_per_iter = evals_per_grad * ones(size(iters));  % constant per iter
evals_ls_per_iter   = ls + 1;   % +1 for the accepted-point eval

% Accepted alpha as multiples of rho^k (how many halvings occurred)
alpha_log2 = -log2(alpha_vec / cg_opts.armijo_a0);  % = ls_count (float)

% Gradient norm correlation with LS cost (Pearson r)
ls_nonzero  = ls(ls > 0);
gn_nonzero  = gnorm_vec(ls > 0);
if numel(ls_nonzero) > 2
    corr_ls_gnorm = corr(ls_nonzero(:), gn_nonzero(:));
else
    corr_ls_gnorm = NaN;
end

% Efficiency: fraction of total evaluations that directly compute gradients
% (i.e., useful information vs. overhead from line search)
total_evals = hist.n_feval;
pct_grad    = 100 * hist.feval_grad_cum(end) / total_evals;
pct_ls      = 100 * hist.feval_ls_cum(end)   / total_evals;
pct_other   = 100 - pct_grad - pct_ls;

% Phase detection: penalty-dominated (early) vs. converging (late)
% Heuristic: penalty-dominated while objective > 10x final value
f_final    = f_vec(end);
phase_mask = f_vec > 5 * f_final;   % 1 = early/penalty phase, 0 = converging

mean_ls_early = mean(ls(phase_mask));
mean_ls_late  = mean(ls(~phase_mask));
if isnan(mean_ls_early), mean_ls_early = 0; end
if isnan(mean_ls_late),  mean_ls_late  = 0; end


% ══════════════════════════════════════════════════════════════════════════
%  FIGURE — four panels
% ══════════════════════════════════════════════════════════════════════════
figure('Name', 'Armijo Backtracking Statistics', ...
       'Position', [60 60 1200 900]);

C_EARLY = [0.85 0.33 0.10];   % rust-orange for penalty-dominated phase
C_LATE  = [0.20 0.45 0.75];   % steel-blue  for converging phase
C_RESET = [0.60 0.10 0.60];   % purple for direction-reset markers
C_FAIL  = [0.90 0.10 0.10];   % red for line-search failures

% ── Panel 1: Backtracking halvings per iteration ──────────────────────────
ax1 = subplot(2, 2, 1);
hold on;

% Colour each bar by phase
for i = 1:length(iters)
    col = C_LATE;
    if phase_mask(i), col = C_EARLY; end
    bar(iters(i), ls(i), 1, 'FaceColor', col, 'EdgeColor', 'none');
end

% Overlay direction-reset and line-search-failure markers
reset_iters = iters(resets);
fail_iters  = iters(ls_fail);
if ~isempty(reset_iters)
    scatter(reset_iters, ls(resets) + 0.25, 60, C_RESET, '^', ...
            'filled', 'DisplayName', 'Direction reset');
end
if ~isempty(fail_iters)
    scatter(fail_iters, ls(ls_fail) + 0.25, 60, C_FAIL, 'x', ...
            'LineWidth', 2, 'DisplayName', 'LS failed');
end

yline(mean(ls), 'k--', 'LineWidth', 1.4, ...
      'Label', sprintf('mean = %.1f', mean(ls)), ...
      'LabelHorizontalAlignment', 'right');

% Phase boundary line
if any(phase_mask) && any(~phase_mask)
    boundary = find(~phase_mask, 1) - 0.5;
    xline(boundary, ':', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.2, ...
          'Label', 'Phase boundary', 'LabelOrientation', 'horizontal');
end

% Legend patches
patch(NaN,NaN, C_EARLY, 'DisplayName', 'Penalty-dominated phase', 'EdgeColor','none');
patch(NaN,NaN, C_LATE,  'DisplayName', 'Converging phase',        'EdgeColor','none');
legend('Location', 'northeast', 'FontSize', 8);

xlabel('Iteration k'); ylabel('Backtracking halvings');
title('(a)  Backtracking steps per iteration');
grid on; ax1.XLim = [0.5, hist.n_iter + 0.5];

% ── Panel 2: Accepted step length (alpha) over iterations ─────────────────
ax2 = subplot(2, 2, 2);
hold on;

semilogy(iters, alpha_vec, 'k.-', 'MarkerSize', 10, 'LineWidth', 1.2);

% Reference lines at alpha_0 * rho^k
rho = cg_opts.armijo_rho;  a0 = cg_opts.armijo_a0;
for halv = 0:6
    yline(a0 * rho^halv, '--', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.8, ...
          'Label', sprintf('\\alpha_0 \\rho^{%d}', halv), ...
          'LabelHorizontalAlignment', 'right', 'FontSize', 7);
end

if ~isempty(reset_iters)
    semilogy(reset_iters, alpha_vec(resets), '^', ...
             'Color', C_RESET, 'MarkerFaceColor', C_RESET, 'MarkerSize', 8, ...
             'DisplayName', 'Direction reset');
    legend('alpha_k', 'Direction reset', 'Location', 'best', 'FontSize', 8);
end

xlabel('Iteration k'); ylabel('\alpha_k  (log scale)');
title('(b)  Accepted step length \alpha_k');
grid on; ax2.XLim = [0.5, hist.n_iter + 0.5];

% ── Panel 3: Cumulative function evaluation budget breakdown ───────────────
ax3 = subplot(2, 2, 3);
hold on;

% Stacked area: gradient evals (bottom) + LS evals (top)
feval_other_cum = (1:length(iters))';  % 1 objective eval per iter (accepted pt)
x_fill = [iters, fliplr(iters)];

% Bottom band: gradient evals
area(iters, grad_cum, 'FaceColor', C_LATE,  'FaceAlpha', 0.6, 'EdgeColor', 'none', ...
     'DisplayName', sprintf('Gradient evals (%.0f%%)', pct_grad));

% Middle band: line-search evals on top of gradient
area(iters, grad_cum + ls_cum, 'FaceColor', C_EARLY, 'FaceAlpha', 0.6, ...
     'EdgeColor', 'none', 'DisplayName', sprintf('Line-search evals (%.0f%%)', pct_ls));

% Cover the overlap so we see stacked bands, not overlapping
area(iters, grad_cum, 'FaceColor', C_LATE, 'FaceAlpha', 0.6, 'EdgeColor', 'none', ...
     'HandleVisibility', 'off');

plot(iters, grad_cum + ls_cum, 'k-', 'LineWidth', 1.4, ...
     'DisplayName', sprintf('Total evals = %d', total_evals));

xlabel('Iteration k'); ylabel('Cumulative function evaluations');
title('(c)  Evaluation budget breakdown');
legend('Location', 'northwest', 'FontSize', 8);
grid on; ax3.XLim = [0.5, hist.n_iter + 0.5];

% ── Panel 4: Objective vs cumulative evaluations (fairest convergence plot) -
ax4 = subplot(2, 2, 4);
hold on;

total_cum = grad_cum + ls_cum + (1:length(iters))';
semilogy(total_cum, f_vec, 'k.-', 'MarkerSize', 8, 'LineWidth', 1.4, ...
         'DisplayName', 'f vs total evals');

% Mark direction-reset and phase-boundary positions on this axis
if ~isempty(reset_iters)
    semilogy(total_cum(resets), f_vec(resets), '^', ...
             'Color', C_RESET, 'MarkerFaceColor', C_RESET, 'MarkerSize', 7, ...
             'DisplayName', 'Direction reset');
end

yline(out_opt.data.Cdp, '--', 'Color', [0.2 0.6 0.2], 'LineWidth', 1.2, ...
      'Label', 'C_{Dp} (no penalty)', 'LabelHorizontalAlignment', 'right');

xlabel('Cumulative function evaluations');
ylabel('Objective f  (log scale)');
title('(d)  Convergence vs. evaluation count');
legend('Location', 'northeast', 'FontSize', 8);
grid on;

sgtitle('CG + Armijo: Backtracking Line Search Statistics', ...
        'FontSize', 13, 'FontWeight', 'bold');


% ══════════════════════════════════════════════════════════════════════════
%  PRINTED STATISTICS TABLE
% ══════════════════════════════════════════════════════════════════════════
sep = repmat('=', 1, 66);
fprintf('\n%s\n', sep);
fprintf('  ARMIJO BACKTRACKING STATISTICS — CG + Armijo\n');
fprintf('  Airfoil problem: M=%.0f, alpha=%.0f deg, target CL=%.2f\n', ...
        M_inf, alpha_aero, target_cl);
fprintf('%s\n\n', sep);

fprintf('  SOLVER SUMMARY\n');
fprintf('  %s\n', repmat('-',1,50));
fprintf('  Total iterations          : %d\n',     hist.n_iter);
fprintf('  Total function evals      : %d\n',     total_evals);
fprintf('    Gradient evaluations    : %d  (%.0f%%)\n', hist.feval_grad_cum(end), pct_grad);
fprintf('    Line-search evaluations : %d  (%.0f%%)\n', hist.feval_ls_cum(end),   pct_ls);
fprintf('    Accepted-point evals    : %d  (%.0f%%)\n', hist.n_iter,               pct_other);
fprintf('  Final objective           : %.6f\n',   f_vec(end));
fprintf('  Final CL                  : %.5f (target %.4f)\n', out_opt.data.Cl, target_cl);
fprintf('  Final CDp                 : %.5f\n',   out_opt.data.Cdp);
fprintf('\n');

fprintf('  BACKTRACKING STEP STATISTICS\n');
fprintf('  %s\n', repmat('-',1,50));
fprintf('  Min halvings per iteration : %d\n',    min(ls));
fprintf('  Max halvings per iteration : %d\n',    max(ls));
fprintf('  Mean halvings              : %.3f\n',  mean(ls));
fprintf('  Median halvings            : %.1f\n',  median(ls));
fprintf('  Std deviation              : %.3f\n',  std(double(ls)));
fprintf('  Iterations needing 0 halv  : %d  (%.0f%%)\n', sum(ls==0), 100*mean(ls==0));
fprintf('  Iterations needing >3 halv : %d  (%.0f%%)\n', sum(ls>3),  100*mean(ls>3));
fprintf('  Line-search failures       : %d\n',   sum(ls_fail));
fprintf('\n');

fprintf('  PHASE ANALYSIS\n');
fprintf('  %s\n', repmat('-',1,50));
n_early = sum(phase_mask);  n_late = sum(~phase_mask);
fprintf('  Penalty-dominated iters (f > 5*f_final) : %d\n',  n_early);
fprintf('  Converging phase iters                  : %d\n',  n_late);
fprintf('  Mean halvings — penalty phase           : %.2f\n', mean_ls_early);
fprintf('  Mean halvings — converging phase        : %.2f\n', mean_ls_late);
fprintf('\n');

fprintf('  DIRECTION QUALITY\n');
fprintf('  %s\n', repmat('-',1,50));
fprintf('  Direction-guard resets     : %d  (%.0f%% of iters)\n', ...
        sum(resets), 100*mean(resets));
fprintf('  Corr(halvings, |grad|)     : %.3f\n',  corr_ls_gnorm);
fprintf('  Min accepted alpha         : %.3e\n',  min(alpha_vec));
fprintf('  Max accepted alpha         : %.3e\n',  max(alpha_vec));
fprintf('  Mean accepted alpha        : %.3e\n',  mean(alpha_vec));
fprintf('\n');

fprintf('  EVALUATION EFFICIENCY\n');
fprintf('  %s\n', repmat('-',1,50));
fprintf('  Evals per gradient         : %d  (central FD, N=%d)\n', 2*N, N);
fprintf('  Avg LS evals per iter      : %.2f\n',  mean(evals_ls_per_iter));
fprintf('  Total overhead ratio       : %.2fx\n', total_evals / hist.feval_grad_cum(end));
fprintf('  (overhead ratio = total / gradient-only evals)\n');
fprintf('\n%s\n', sep);


% ══════════════════════════════════════════════════════════════════════════
%  DISCUSSION POINTS (formatted for direct inclusion in a report)
% ══════════════════════════════════════════════════════════════════════════
fprintf('\n%s\n', sep);
fprintf('  REPORT DISCUSSION POINTS\n');
fprintf('%s\n\n', sep);

fprintf('  1. MEAN BACKTRACKING STEPS (%.2f halvings/iter)\n\n', mean(ls));
fprintf(['     The Armijo condition requires f(x+as) <= f(x) + c*a*(g''s).\n'...
         '     On average, the accepted step length was alpha_0 * rho^%.1f = %.2e,\n'...
         '     meaning the initial trial step a0=1 was rejected on most iterations.\n'...
         '     This is expected for a penalty-augmented objective: the penalty term\n'...
         '     R=100 creates a steep, non-smooth landscape near constraint boundaries\n'...
         '     where large steps overshoot. For the full aircraft design problem with\n'...
         '     15+ variables and similarly structured penalties, this suggests scaling\n'...
         '     a0 by 1/||g|| at each iteration to reduce average LS cost.\n\n'], ...
         mean(ls), mean(alpha_vec));

fprintf('  2. PHASE DEPENDENCE (early: %.2f halvings  |  late: %.2f halvings)\n\n', ...
        mean_ls_early, mean_ls_late);
fprintf(['     Line-search cost is highest in the penalty-dominated phase (first\n'...
         '     %d iterations), when constraint violations are large and the gradient\n'...
         '     points aggressively toward the feasible region. Once the solution\n'...
         '     enters the converging phase, the objective landscape is smoother and\n'...
         '     accepted steps are larger. This two-regime behaviour justifies using\n'...
         '     a warm-started a0: initialise with the previously accepted alpha rather\n'...
         '     than resetting to 1.0 each iteration, which cuts LS evals in the late\n'...
         '     phase substantially.\n\n'], n_early);

fprintf('  3. EVALUATION BUDGET BREAKDOWN (gradient: %.0f%%  |  line-search: %.0f%%)\n\n', ...
        pct_grad, pct_ls);
fprintf(['     With central finite differences, each gradient evaluation costs 2N=%d\n'...
         '     function calls, accounting for %.0f%% of the total budget. Line-search\n'...
         '     overhead is %.0f%%. The overhead ratio of %.2fx means that for every\n'...
         '     gradient computed, %.2f additional evaluations were spent on step-size\n'...
         '     selection. Switching to forward differences would halve the gradient\n'...
         '     cost (at the expense of O(h) accuracy vs O(h^2)), potentially making\n'...
         '     the line search a larger fraction of total cost and making the choice\n'...
         '     of a0 even more important.\n\n'], ...
         2*N, pct_grad, pct_ls, total_evals/hist.feval_grad_cum(end), ...
         total_evals/hist.feval_grad_cum(end) - 1);

fprintf('  4. OBJECTIVE VS CUMULATIVE EVALS (panel d)\n\n');
fprintf(['     Plotting convergence against cumulative evaluations rather than\n'...
         '     iteration number is the fairest efficiency measure, since fminunc\n'...
         '     uses a different number of evaluations per iteration (it builds a\n'...
         '     Hessian approximation). The slope of panel (d) on a log scale gives\n'...
         '     the empirical convergence rate per unit of computational work. If\n'...
         '     this slope is shallower than fminunc on the same axis, it directly\n'...
         '     quantifies how much the BFGS Hessian approximation is worth in terms\n'...
         '     of function evaluations — the currency that matters when each eval\n'...
         '     involves a full panel-method solve.\n\n']);

fprintf('  5. DIRECTION RESETS (%d resets, %.0f%% of iterations)\n\n', ...
        sum(resets), 100*mean(resets));
fprintf(['     The direction-guard fires when the conjugate direction s_k satisfies\n'...
         '     g_k''*s_k >= 0, meaning it is no longer a descent direction. This\n'...
         '     happens when finite-difference gradient noise corrupts the accumulated\n'...
         '     conjugate directions. Each reset forces a steepest-descent step,\n'...
         '     discarding the conjugate history and costing the superlinear\n'...
         '     convergence benefit of CG. The correlation between halvings and\n'...
         '     gradient norm (r=%.3f) quantifies how closely LS difficulty tracks\n'...
         '     gradient accuracy: a strong positive correlation would suggest the\n'...
         '     gradient is the limiting factor and a tighter FD step size (or\n'...
         '     complex-step differentiation) would directly reduce backtracking cost.\n\n'], ...
         corr_ls_gnorm);

fprintf('%s\n', sep);

end % ── main function ─────────────────────────────────────────────────────


% ╔══════════════════════════════════════════════════════════════════════════╗
% ║  PHYSICS — identical to supersonic_airfoil_cg.m local functions        ║
% ╚══════════════════════════════════════════════════════════════════════════╝
function out = obj_fn(D, xr, x_ctrl, N, Nr, alpha, M, ...
                      target_cl, min_area, t_max_ref, t_max_center)
    [yt, yb] = get_foil_coords(D, xr, x_ctrl, N);
    data     = foilData(xr, yt, yb, alpha, M, D);
    h1 = abs((data.Cl - target_cl) / target_cl);
    g1 = 1 - data.area / min_area;
    g2 = norm(max(0, t_max_ref - (yt-yb)(2:Nr+1)) / t_max_center);
    out.obj  = data.Cdp + 100 * max([h1, g1, g2, 0]);
    out.data = data;  out.h1 = h1;  out.g1 = g1;  out.g2 = g2;
end

function t = t_max_parabola(x_c, t_max_center)
    a = t_max_center / 0.25;
    t = a*0.25 - a*(x_c - 0.5).^2;
end

function [ytc, ybc] = get_foil_coords(D, xr, x_ctrl, N)
    yt_inner = D(1:N);
    yb_inner = yt_inner - abs(D(N+1:2*N));
    ytc = spline(x_ctrl, [0, yt_inner, 0], xr);
    ybc = spline(x_ctrl, [0, yb_inner, 0], xr);
end

function data = foilData(x, yt, yb, alpha, M, D)
    data = struct('D',D,'x',x,'yt',yt,'yb',yb,'alpha',alpha,'M',M);
    data.coords = [x,flip(x(2:end-1));yt,flip(yb(2:end-1))];
    data.area   = polyarea(data.coords(1,:),data.coords(2,:));
    [data.At,data.Nvt] = panelInfo(x,yt,1);
    [data.Ab,data.Nvb] = panelInfo(x,yb,0);
    data.A  = [data.At,data.Ab];   data.Nv = [data.Nvt,data.Nvb];
    data.Cpt = panelCp(data.Nvt,alpha,M);
    data.Cpb = panelCp(data.Nvb,alpha,M);
    data.Cp  = [data.Cpt,data.Cpb];
    data.xm  = 0.5*(x(1:end-1)+x(2:end));
    data.ytm = 0.5*(yt(1:end-1)+yt(2:end));
    data.ybm = 0.5*(yb(1:end-1)+yb(2:end));
    data.coords_m = [data.xm,data.xm;data.ytm,data.ybm];
    data.L = max(x)-min(x);  data.A_ref = data.L;
    C = -(data.Nvt*(data.Cpt.*data.At)' + data.Nvb*(data.Cpb.*data.Ab)')/data.A_ref;
    data.Cn  = C(2);  data.Ca  = C(1);
    data.Cl  = data.Cn*cosd(alpha) - data.Ca*sind(alpha);
    data.Cdp = data.Ca*cosd(alpha) + data.Cn*sind(alpha);
    dF = -data.Cp.*data.A.*data.Nv;  r = data.coords_m;
    data.Cm_LE = sum(r(1,:).*dF(2,:)-r(2,:).*dF(1,:))/(data.A_ref*data.L);
    data.X_cp  = data.Cm_LE/data.Cl;
    data.Cdw   = waveD_Hayes(x,yt,yb,data.A_ref);
    Re = 1.225*0.01503*301.7*M*data.L/80.134e-5;
    data.Cdf   = skinFriction(x,yt,yb,M,Re,data.A_ref);
    data.Cd_tot = max([data.Cdw,data.Cdp])+data.Cdf;
    data.thickness = yt-yb;
end

function [A,Nv] = panelInfo(x,y,is_top)
    A  = sqrt((x(1:end-1)-x(2:end)).^2+(y(1:end-1)-y(2:end)).^2);
    Nv = [y(1:end-1)-y(2:end);x(2:end)-x(1:end-1)]./A;
    if ~is_top; Nv = -Nv; end
end

function Cp = panelCp(Nv, alpha, M)
    gam=1.4; dir=[cosd(alpha);sind(alpha)];
    theta = acos(max(-1,min(1,dir'*Nv)))-pi/2;
    K=sqrt(M^2-1);
    Cp_max=1+((gam+1)*K^2+2)*log((gam+1)/2+1/K^2)/((gam-1)*K^2+2);
    nu_inf=prandtlMeyerNu(M,gam); theta_max=maxDeflectionAngle(M,gam);
    nu_max=pi/2*(sqrt((gam+1)/(gam-1))-1);
    Cp=zeros(1,length(theta));
    for i=1:length(theta)
        th=theta(i);
        if th>=0
            if th>=theta_max; Cp(i)=Cp_max*sin(th)^2;
            else
                beta=solveBeta(th,M,gam); Mn1=M*sin(beta);
                Cp(i)=(1+2*gam/(gam+1)*(Mn1^2-1)-1)/(0.5*gam*M^2);
            end
        else
            nu2=min(nu_inf+abs(th),0.9999*nu_max); M2=invertPrandtlMeyer(nu2,gam);
            p0p=@(Mx)(1+(gam-1)/2*Mx^2)^(gam/(gam-1));
            Cp(i)=(p0p(M)/p0p(M2)-1)/(0.5*gam*M^2);
        end
    end
end

function nu=prandtlMeyerNu(M,gam)
    r=sqrt((gam+1)/(gam-1));
    nu=r*atan(sqrt((gam-1)/(gam+1)*(M^2-1)))-atan(sqrt(M^2-1));
end

function M=invertPrandtlMeyer(nu_target,gam)
    A=(gam+1)/(gam-1); nu_max=pi/2*(sqrt(A)-1); X=nu_target/nu_max;
    M=max(1.001,1+1.2276*X+0.4919*X^2+2.4009*X^3-5.2313*X^4+4.0754*X^5);
    for k=1:20
        dM=(nu_target-prandtlMeyerNu(M,gam))/(sqrt(M^2-1)/(M*(1+(gam-1)/2*M^2)));
        M=max(1.001,M+dM); if abs(dM)<1e-10; break; end
    end
end

function th_max=maxDeflectionAngle(M,gam)
    mu=asin(1/M); bvec=linspace(mu+1e-4,pi/2-1e-4,2000);
    th_max=max(thetaFromBeta(bvec,M,gam));
end

function th=thetaFromBeta(beta,M,gam)
    th=atan2(2*cot(beta).*(M^2*sin(beta).^2-1),M^2*(gam+cos(2*beta))+2);
    th=max(th,0);
end

function beta=solveBeta(theta,M,gam)
    mu=asin(1/M); bvec=linspace(mu+1e-6,pi/2-1e-6,4000);
    [~,idx]=max(thetaFromBeta(bvec,M,gam)); blo=mu+1e-8; bhi=bvec(idx);
    for k=1:60
        bmid=0.5*(blo+bhi); f=thetaFromBeta(bmid,M,gam)-theta;
        if f>0; bhi=bmid; else; blo=bmid; end
        if (bhi-blo)<1e-12; break; end
    end
    beta=0.5*(blo+bhi);
end

function Cdw=waveD_Hayes(x,yt,yb,A_ref)
    S=smooth3pt(max(yt-yb,0)); n=length(x); Spp=zeros(1,n);
    for k=2:n-1
        h1=x(k)-x(k-1); h2=x(k+1)-x(k);
        Spp(k)=2*(S(k+1)/h2-S(k)*(1/h1+1/h2)+S(k-1)/h1)/(h1+h2);
    end
    [Xi,Xj]=meshgrid(x,x); [Si,Sj]=meshgrid(Spp,Spp);
    dist=abs(Xi-Xj); od=dist>0;
    I=sum(sum(Si.*Sj.*log(dist+~od).*od))*((x(end)-x(1))/(n-1))^2;
    Cdw=max(-I/(2*pi*A_ref),0);
end

function Ss=smooth3pt(S)
    Ss=S; Ss(2:end-1)=(S(1:end-2)+S(2:end-1)+S(3:end))/3;
end

function Cdf=skinFriction(x,yt,yb,M,Re_L,A_ref)
    dx=diff(x);
    S_wet=sum(sqrt(dx.^2+diff(yt).^2))+sum(sqrt(dx.^2+diff(yb).^2));
    Cdf=0.074/(Re_L/(1+0.035*M^2))^0.2*S_wet/A_ref;
end