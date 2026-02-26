function max_performance_plots(perf, N)
    perf.model.clear_mem(); perf.clear_data();
    W = 1;
    h_vec = linspace(0, 20000, N);
    M_vec = linspace(0.3, 2, N);
    [H, M] = meshgrid(h_vec, M_vec);
    h_vec_long = H(:)';
    M_vec_long = M(:)';

    one_vec = ones(size(h_vec_long));

    perf.model.cond = generateCondition(perf.model.geom, h_vec_long, M_vec_long,one_vec, W * one_vec, one_vec);

    general_contour("Altitude [m]", "Mach Number", "TSFC [s]", "TSFC at T = 1", H, M, perf.TSFC)
    general_contour("Altitude [m]", "Mach Number", "TA [kN]", "Max Thrust Available", H, M, perf.TA / 1000)
    general_contour("Altitude [m]", "Mach Number", "Excess Power [m/s]", "Excess Power", H, M, perf.ExcessPower, true)
    general_contour("Altitude [m]", "Mach Number", "Climb Angle [deg]", "Max Sustained Climb Angle", H, M, perf.ClimbAngle, true)
    general_contour("Altitude [m]", "Mach Number", "Acc [G]", "Max Axial Accelleration", H, M, perf.AxialAccelleration, true)

    % Now need to find the max turn rate
    perf.model.clear_mem(); perf.clear_data();
    perf.model.cond = generateCondition(perf.model.geom, h_vec_long, M_vec_long, perf.model.geom.input.g_limit.v * one_vec, W * one_vec, one_vec);
    % general_contour("Altitude [m]", "Mach Number", "Rate [deg/s]", "Max Level Turn Rate", H, M, perf.LevelTurnRate)
    general_contour("Altitude [m]", "Mach Number", "Rate [deg/s]", "Max Turn Rate", H, M, perf.TurnRate)

    perf.model.clear_mem(); perf.clear_data();
end