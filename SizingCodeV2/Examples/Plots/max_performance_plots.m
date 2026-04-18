function max_performance_plots(perf, N)
    settings = readSettings();
    perf.model.clear_mem(); perf.clear_data();
    W = 1;
    h_vec = linspace(0, ft2m(50000), N);
    M_vec = linspace(0.3, 2, N);
    [M, H] = meshgrid(M_vec, h_vec);
    h_vec_long = H(:)';
    M_vec_long = M(:)';
    one_vec = ones(size(h_vec_long));
    perf.model.cond = generateCondition(perf.model.geom, h_vec_long, M_vec_long,one_vec, W * one_vec, one_vec);
    % Create filter for excess power (cannot be less than 0)
    filter = -perf.ExcessPower; % When a filter is less than 0, it is plotted
    if settings.be_imperial
        ydata = m2ft(H);
        ylabel = "Altitude [ft]";
        general_contour("Mach Number", ylabel, "TSFC [lbm/lbfhr]", "TSFC", M, ydata, kgNs_2_lbmlbfhr(perf.TSFC), filter)
        general_contour("Mach Number", ylabel, "TA [lb]", "Max Thrust Available", M, ydata, N2lb(perf.TA), filter)
        general_contour("Mach Number", ylabel, "Excess Power [ft/s]", "Excess Power", M, ydata, m2ft(perf.ExcessPower), filter)
    else
        ydata = H;
        ylabel = "Altitude [m]";
        general_contour("Mach Number", ylabel, "TSFC [s]", "TSFC at T = 1", M, ydata, perf.TSFC, filter)
        general_contour("Mach Number", ylabel, "TA [kN]", "Max Thrust Available", M, ydata, perf.TA / 1000, filter)
        general_contour("Mach Number", ylabel, "Excess Power [m/s]", "Excess Power", M, ydata, perf.ExcessPower, filter)
    end
    general_contour("Mach Number", ylabel, "Climb Angle [deg]", "Max Sustained Climb Angle", M, ydata, perf.ClimbAngle, filter)
    general_contour("Mach Number", ylabel, "Acc [G]", "Max Axial Accelleration", M, ydata, perf.AxialAccelleration, filter)
    % Now need to find the max turn rate
    perf.model.clear_mem(); perf.clear_data();
    perf.model.cond = generateCondition(perf.model.geom, h_vec_long, M_vec_long, perf.model.geom.input.g_limit.v * one_vec, W * one_vec, one_vec);
    % general_contour("Mach Number", "Altitude [m]", "Rate [deg/s]", "Max Level Turn Rate", M, H, perf.LevelTurnRate)
    general_contour("Mach Number", ylabel, "Rate [deg/s]", "Max Turn Rate", M, ydata, perf.TurnRate, filter)
    perf.model.clear_mem(); perf.clear_data();
end