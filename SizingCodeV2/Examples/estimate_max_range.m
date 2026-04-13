function [max_range, h_opt, M_opt, v_opt] = estimate_max_range(perf, W, opts)
    arguments
        perf 
        W 
        opts.x0_override = NaN % if specified we skip the search and just set it [h, M]
    end

    W_start = W - 0.05; W_end = 0.05;
    W_mid   = 0.5*(W_start + W_end);

    if isnan(opts.x0_override)
        h_vec = linspace(1000, 12000, 20);
        M_vec = linspace(0.5,  1.4,   20);
        [H, M] = ndgrid(h_vec, M_vec);   % ndgrid for consistency
        h_long = H(:);
        M_long = M(:);
    
        cond = levelFlightCondition(perf, h_long, M_long, W_mid, perf.model.settings.codes.MV_DEC_MACH);
        perf.model.cond = cond;
    
        range_sweep = perf.LD .* cond.vel.v ...
                    .* log(weightRatio(W_start, perf.model.geom) / weightRatio(W_end, perf.model.geom)) ...
                    ./ (perf.model.settings.g_const .* perf.TSFC);
    
        [~, idx] = max(range_sweep);
        h_best = h_long(idx);
        M_best = M_long(idx);
    
        h_scale = 10000;   % m  — representative cruise altitude
        M_scale = 1.0;     % — Mach is already O(1) but kept for symmetry
    
        x0_n = [h_best / h_scale, M_best / M_scale];
    
        eval_count = 0;
        objective  = @(x_n) counted_obj(perf, x_n(1)*h_scale, x_n(2)*M_scale, W_mid);
    
        options = optimset('Display',     'off', ...
                           'TolX',        1e-4,  ...   % in normalised space — ~1m / 0.0001 Mach
                           'TolFun',      1e-4,  ...
                           'MaxFunEvals', 400);
        tic;
        x_opt_n   = fminsearch(objective, x0_n, options);
        t_elapsed = toc;

        h_opt = x_opt_n(1) * h_scale;
        M_opt = x_opt_n(2) * M_scale;
    else
        h_opt = opts.x0_override(1);
        M_opt = opts.x0_override(2);
    end

    perf.model.cond = levelFlightCondition(perf, h_opt, M_opt, W_mid);
    v_opt     = perf.model.cond.vel.v;
    max_range = perf.LD * v_opt ...
              * log(weightRatio(W_start, perf.model.geom) / weightRatio(W_end, perf.model.geom)) ...
              / (perf.model.settings.g_const * perf.TSFC);

    % disp(max_range)
    % fprintf('estimate_max_range: %d evals | %.2f sec | h=%.0fm M=%.3f range=%.0fnm\n', eval_count, t_elapsed, h_opt, M_opt, m2nm(max_range));


    function out = counted_obj(perf, h, M, W)
        eval_count = eval_count + 1;
        out = obj(perf, h, M, W);
    end
end

function out = obj(perf, h, M, W)
    perf.model.cond = levelFlightCondition(perf, h, M, W);
    range_term      = perf.model.cond.vel.v / perf.mdotf;
    R               = 100;
    out = -range_term + R * max([-perf.ExcessPower/100, -h/10000, 0]);
end