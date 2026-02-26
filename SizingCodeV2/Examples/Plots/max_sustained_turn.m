function max_sustained_turn(perf, N)
    perf.model.clear_mem(); perf.clear_data();
    W = 1;
    h_vec = linspace(0, 5000, N);
    M_vec = linspace(0.3, 2, N);
    [H, M] = meshgrid(h_vec, M_vec);
    h_vec_long = H(:)';
    M_vec_long = M(:)';

    one_vec = ones(size(h_vec_long));

    perf.model.clear_mem(); perf.clear_data();
    perf.model.cond = Max_N_Condition(perf, h_vec_long, M_vec_long, W * one_vec);
    general_contour("Altitude [m]", "Mach Number", "Rate [deg/s]", "Max Sustained Turn Rate", H, M, perf.TurnRate)
end