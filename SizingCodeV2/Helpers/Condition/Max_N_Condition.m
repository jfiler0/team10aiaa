function cond = Max_N_Condition(perf, h, MV, W)
    perf.model.clear_mem(); perf.clear_data();

    cond_level = levelFlightCondition(perf, h, MV, W);
    can_turn = cond_level.throttle.v < 1;

    h_vec = h(can_turn);
    M_vec = cond_level.M.v(can_turn);
    W_vec = W(can_turn);

    options = optimset('Display', 'off');
    N_opt = ones(size(h_vec));

    for i = 1:length(h_vec)
        fun_i = @(N) obj(perf, h_vec(i), M_vec(i), W_vec(i), N);
        N_opt(i) = fminbnd(fun_i, 1, perf.model.geom.input.g_limit.v, options);
    end

    perf.model.clear_mem(); perf.clear_data();
    N_final = ones(size(h));
    N_final(can_turn) = N_opt;
    cond = generateCondition(perf.model.geom, h, cond_level.M.v, N_final, W, ones(size(h)));
end

function res = obj(perf, h, M, W, N)
    perf.model.clear_mem(); perf.clear_data();
    perf.model.cond = generateCondition(perf.model.geom, h, M, N, W, 1);
    res = abs(perf.ExcessThrust);
end