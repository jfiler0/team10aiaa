function [x_opt, history] = cg_armijo(fun, x0, options)
% CG_ARMIJO  Conjugate Gradient with Backtracking Armijo Line Search
%
%   Implements Algorithm 1 from the AOE 5404 project report exactly:
%     - Fletcher-Reeves beta update
%     - Armijo sufficient-decrease condition
%     - Finite-difference gradient (central differences)
%     - Optional periodic restart every n steps
%
% USAGE
%   [x_opt, history] = cg_armijo(fun, x0)
%   [x_opt, history] = cg_armijo(fun, x0, options)
%
% INPUTS
%   fun      : function handle, f = fun(x), scalar output
%   x0       : [n x 1] initial guess (column vector)
%   options  : struct with any of the following fields:
%
%     .max_iter    (default 300)   maximum CG iterations
%     .tol_grad    (default 1e-5)  stop when norm(g) < tol_grad
%     .tol_step    (default 1e-9)  stop when norm(step) < tol_step
%     .tol_obj     (default 1e-10) stop when |Δf| < tol_obj
%     .fd_h        (default 1e-5)  finite-difference step size
%     .fd_type     ('central' | 'forward', default 'central')
%                  central differences are O(h^2) accurate;
%                  forward differences are O(h) but half the evaluations
%     .armijo_c    (default 1e-4)  Armijo sufficient-decrease constant
%     .armijo_rho  (default 0.5)   Armijo backtracking factor
%     .armijo_a0   (default 1.0)   initial trial step length
%     .armijo_max  (default 100)   max backtracking steps
%     .restart_n   (default n)     restart every this many iterations
%                  set to Inf to disable periodic restarts
%     .display     ('iter' | 'final' | 'none', default 'iter')
%
% OUTPUTS
%   x_opt   : [n x 1] optimized design vector
%   history : struct with fields:
%     .x       {iter+1 x 1} cell of x at each iteration
%     .f       [iter+1 x 1] objective values
%     .gnorm   [iter+1 x 1] gradient norms
%     .snorm   [iter+1 x 1] step norms  (NaN at k=0)
%     .alpha   [iter+1 x 1] accepted step lengths (NaN at k=0)
%     .beta    [iter+1 x 1] Fletcher-Reeves beta (NaN at k=0 and restarts)
%     .n_feval [scalar]     total function evaluations used

opts = parse_options(options, length(x0));

x   = x0(:);          % ensure column vector
n   = length(x);
k   = 0;

f   = fun(x);
g   = fd_grad(fun, x, f, opts);
s   = -g;             % initial search direction = steepest descent

n_feval = 1 + length(x) * (2 - (strcmp(opts.fd_type,'forward')));
                      % 1 for f(x0) + n (central) or n (forward) for grad


MAX = opts.max_iter + 1;
hist_f     = nan(MAX, 1);
hist_gnorm = nan(MAX, 1);
hist_snorm = nan(MAX, 1);
hist_alpha = nan(MAX, 1);
hist_beta  = nan(MAX, 1);
hist_x     = cell(MAX, 1);

hist_f(1)     = f;
hist_gnorm(1) = norm(g);
hist_x{1}     = x;

print_header(opts);
print_iter(0, f, norm(g), NaN, NaN, NaN, opts);


converged = false;

for k = 1 : opts.max_iter

    gs = g' * s;          % directional derivative along s
    if gs >= -eps * norm(g) * norm(s)
        s  = -g;
        gs = g' * s;
    end

    alpha   = opts.armijo_a0;
    f_curr  = f;
    armijo_iters = 0;

    for ls = 1 : opts.armijo_max
        x_try   = x + alpha * s;
        f_try   = fun(x_try);
        n_feval = n_feval + 1;

  
        if f_try <= f_curr + opts.armijo_c * alpha * gs
            break
        end
        alpha        = opts.armijo_rho * alpha;    % line 6: α ← ρα
        armijo_iters = armijo_iters + 1;
    end

  
    alpha_k = alpha;
    x_new   = x + alpha_k * s;           % x_{k+1} ← x_k + α_k s_k
    f_new   = fun(x_new);
    n_feval = n_feval + 1;

 
    g_new   = fd_grad(fun, x_new, f_new, opts);
    n_feval = n_feval + length(x) * (2 - strcmp(opts.fd_type,'forward'));

    step_norm = norm(x_new - x);
    grad_norm = norm(g_new);
    delta_f   = abs(f_new - f);

    % ── Fletcher-Reeves beta (line 11) ────────────────────────────────────
    beta_raw = (g_new' * g_new) / max(g' * g, 1e-30);

    % ── Periodic restart / negative beta reset (before line 12) ──────────
    do_restart = (mod(k, opts.restart_n) == 0) || (beta_raw < 0);
    if do_restart
        beta_k = 0;
    else
        beta_k = beta_raw;
    end

    % ── New conjugate direction (line 12) ─────────────────────────────────
    s_new = -g_new + beta_k * s;         % s_{k+1} ← -g_{k+1} + β s_k

    % ── Log iteration ─────────────────────────────────────────────────────
    hist_f(k+1)     = f_new;
    hist_gnorm(k+1) = grad_norm;
    hist_snorm(k+1) = step_norm;
    hist_alpha(k+1) = alpha_k;
    hist_beta(k+1)  = beta_k;
    hist_x{k+1}     = x_new;

    print_iter(k, f_new, grad_norm, step_norm, alpha_k, beta_k, opts);

    % ── Advance ──────────────────────────────────────────────────────────
    x = x_new;
    f = f_new;
    g = g_new;
    s = s_new;

    % ── Convergence checks ────────────────────────────────────────────────
    if grad_norm < opts.tol_grad
        print_converged('gradient norm', grad_norm, opts.tol_grad, opts);
        converged = true; break
    end
    if step_norm < opts.tol_step
        print_converged('step norm', step_norm, opts.tol_step, opts);
        converged = true; break
    end
    if delta_f < opts.tol_obj && k > 1
        print_converged('objective change', delta_f, opts.tol_obj, opts);
        converged = true; break
    end

end

if ~converged && ~strcmp(opts.display, 'none')
    fprintf('  Warning: maximum iterations (%d) reached.\n', opts.max_iter);
end

% ── Pack outputs ──────────────────────────────────────────────────────────
x_opt = x;

history.x      = hist_x(1:k+1);
history.f      = hist_f(1:k+1);
history.gnorm  = hist_gnorm(1:k+1);
history.snorm  = hist_snorm(1:k+1);
history.alpha  = hist_alpha(1:k+1);
history.beta   = hist_beta(1:k+1);
history.n_feval = n_feval;
history.n_iter  = k;

print_final(x_opt, history, fun, opts);

end % ── main function ──────────────────────────────────────────────────────


function g = fd_grad(fun, x, fx, opts)
% Central differences:  g_i = [f(x+he_i) - f(x-he_i)] / (2h)   O(h^2)
% Forward differences:  g_i = [f(x+he_i) - f(x)]       / h       O(h)
    n = length(x);
    g = zeros(n, 1);
    h = opts.fd_h;

    if strcmp(opts.fd_type, 'central')
        for i = 1:n
            xp = x; xp(i) = xp(i) + h;
            xm = x; xm(i) = xm(i) - h;
            g(i) = (fun(xp) - fun(xm)) / (2*h);
        end
    else   % forward
        for i = 1:n
            xp = x; xp(i) = xp(i) + h;
            g(i) = (fun(xp) - fx) / h;
        end
    end
end

function opts = parse_options(user_opts, n)
    opts.max_iter   = 300;
    opts.tol_grad   = 1e-5;
    opts.tol_step   = 1e-9;
    opts.tol_obj    = 1e-10;
    opts.fd_h       = 1e-5;
    opts.fd_type    = 'central';
    opts.armijo_c   = 1e-4;
    opts.armijo_rho = 0.5;
    opts.armijo_a0  = 1.0;
    opts.armijo_max = 100;
    opts.restart_n  = n;        % default: restart every n steps
    opts.display    = 'iter';

    if nargin < 1 || isempty(user_opts), return; end

    fields = fieldnames(user_opts);
    for i = 1:length(fields)
        f = fields{i};
        if isfield(opts, f)
            opts.(f) = user_opts.(f);
        else
            warning('cg_armijo: unknown option "%s" ignored.', f);
        end
    end
end


function print_header(opts)
    if strcmp(opts.display, 'iter')
        fprintf('\n');
        fprintf(' %5s | %14s | %12s | %12s | %10s | %8s\n', ...
            'Iter', 'f', '|grad|', '|step|', 'alpha', 'beta');
        fprintf(' %s\n', repmat('-', 1, 70));
    end
end

function print_iter(k, f, gnorm, snorm, alpha, beta, opts)
    if ~strcmp(opts.display, 'iter'), return; end
    if k == 0
        fprintf(' %5d | %14.6g | %12.4g | %12s | %10s | %8s\n', ...
            0, f, gnorm, '—', '—', '—');
    else
        fprintf(' %5d | %14.6g | %12.4g | %12.4g | %10.3g | %8.4f\n', ...
            k, f, gnorm, snorm, alpha, beta);
    end
end

function print_converged(criterion, val, tol, opts)
    if strcmp(opts.display, 'none'), return; end
    fprintf('\n  Converged: %s = %.3g < tol = %.3g\n', criterion, val, tol);
end

function print_final(x_opt, history, fun, opts)
    if strcmp(opts.display, 'none'), return; end
    f_final = history.f(end);
    fprintf('\n');
    fprintf('  ─────────────────────────────────────────────────────\n');
    fprintf('  CG + Armijo Summary\n');
    fprintf('  ─────────────────────────────────────────────────────\n');
    fprintf('  Iterations   : %d\n',    history.n_iter);
    fprintf('  Func evals   : %d\n',    history.n_feval);
    fprintf('  Final f      : %.6g\n',  f_final);
    fprintf('  Final |grad| : %.4g\n',  history.gnorm(end));
    fprintf('  ─────────────────────────────────────────────────────\n\n');
end
