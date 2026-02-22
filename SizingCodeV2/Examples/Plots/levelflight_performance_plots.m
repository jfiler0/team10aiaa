function levelflight_performance_plots(perf, N)
    perf.model.clear_mem(); perf.clear_data();
    W = 1;
    h_vec = linspace(3700, 3500, N);
    M_vec = linspace(0.6, 0.7, N);

    % h_vec = linspace(0, 5000, N);
    % M_vec = linspace(0.3, 2, N);

    [H, M] = meshgrid(h_vec, M_vec);
    h_vec_long = H(:)';
    M_vec_long = M(:)';

    perf.model.cond = levelFlightCondition(perf, h_vec_long, M_vec_long, W * ones(size(h_vec_long)));

    general_contour("Altitude [m]", "Mach Number", "TSFC [s]", "TSFC", H, M, perf.TSFC)
    general_contour("Altitude [m]", "Mach Number", "mdotf [kg/s]", "Fuel Mass Flow", H, M, perf.mdotf)
    general_contour("Altitude [m]", "Mach Number", "CD", "Drag Coefficent", H, M, perf.CD)
    general_contour("Altitude [m]", "Mach Number", "CL", "Lift Coefficent", H, M, perf.model.cond.CL.v)
    general_contour("Altitude [m]", "Mach Number", "L/D", "Lift Over Drag", H, M, perf.LD)
    
    Cdw_data = perf.model.CDw;
    if max(Cdw_data) > 0 % if the conditions go into transonic
        general_contour("Altitude [m]", "Mach Number", "CDw", "Wave Drag Coeffcient", H, M, perf.model.CDw)
    end
    general_contour("Altitude [m]", "Mach Number", "CDi", "Induced Drag Coeffcient", H, M, perf.model.CDi)
    general_contour("Altitude [m]", "Mach Number", "e_osw", "Oswald Efficency", H, M, perf.e_osw)
    general_contour("Altitude [m]", "Mach Number", "CLa", "Lift Slope", H, M, perf.model.CLa)
    general_contour("Altitude [m]", "Mach Number", "Excess Power [m/s]", "Excess Power", H, M, perf.ExcessPower)
    general_contour("Altitude [m]", "Mach Number", "mdotf / V", "Optimium Range Term (minimize)", H, M, perf.Rbar, false, [0 0.002] )
    general_contour("Altitude [m]", "Mach Number", "Throttle", "Throttle", H, M, perf.model.cond.throttle.v)

    
    perf.model.clear_mem(); perf.clear_data();
end