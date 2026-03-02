function max_sustained_turn(perf, N)
    settings = readSettings();
    perf.model.clear_mem(); perf.clear_data();
    W = 1;
    h_vec = linspace(0, ft2m(50000), N);
    M_vec = linspace(0.3, 2, N);
    [M, H] = meshgrid(M_vec, h_vec);
    h_vec_long = H(:)';
    M_vec_long = M(:)';
    one_vec = ones(size(h_vec_long));
    perf.model.clear_mem(); perf.clear_data();
    perf.model.cond = Max_N_Condition(perf, h_vec_long, M_vec_long, W * one_vec);
    % Create filter for load factor (Must be above 1)
        filter = 1.05 - perf.model.cond.n.v; % When a filter is less than 0, it is plotted
    if settings.be_imperial
            general_contour("Mach Number", "Altitude [ft]", "Rate [deg/s]", "Max Sustained Turn Rate", M, m2ft(H), perf.TurnRate, filter)
    else
            general_contour("Mach Number", "Altitude [m]", "Rate [deg/s]", "Max Sustained Turn Rate", M, H, perf.TurnRate, filter)
    end
end