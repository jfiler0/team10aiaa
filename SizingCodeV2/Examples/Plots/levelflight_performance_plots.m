function levelflight_performance_plots(perf, N)
    settings = readSettings();
    perf.model.clear_mem(); perf.clear_data();
    W = 1;
    h_vec = linspace(0, ft2m(50000), N);
    M_vec = linspace(0.3, 2, N);
    [M, H] = meshgrid(M_vec, h_vec);
    h_vec_long = H(:)';
    M_vec_long = M(:)';
    perf.model.cond = levelFlightCondition(perf, h_vec_long, M_vec_long, W * ones(size(h_vec_long)));
    disp(perf.model.cond.a.v)
    kts = zeros(size(H));
    for i = 1:50
        for j = 1:50
            kts(i,j) = M(i,j)*perf.model.cond.a.v(i + 49*(i-1))*1.94384449;
        end
    end
    
% Create filter for throttle (Cannot be 1) and CL cannot go above 1.4
    filter = max(perf.model.cond.throttle.v - 0.99, perf.model.cond.CL.v - 1.4); % When a filter is less than 0, it is plotted
if settings.be_imperial
        ydata = m2ft(H);
        ylabel = "Altitude [ft]";
        general_contour("Mach Number", ylabel, "mdotf / V [slug/ft]", "Specific Fuel Consumption", ...
                       M, ydata, kg2slug(perf.Rbar)/m2ft(1), filter)
        general_contour("Mach Number", ylabel, "mdotf [slug/s]", "Fuel Mass Flow", ...
                       M, ydata, kg2slug(perf.mdotf), filter)
        general_contour("Mach Number", ylabel, "TSFC [lbm/lbfhr]", "TSFC", ...
                       M, ydata, kgNs_2_lbmlbfhr(perf.TSFC), filter)
        general_contour("Mach Number", ylabel, "TA [lb]", "Thrust Available", ...
                       M, ydata, N2lb(perf.TA), filter)
else
        ydata = H;
        ylabel = "Altitude [m]";
        general_contour("Mach Number", ylabel, "mdotf / V [kg/m]", "Optimium Range Term (minimize)", ...
                       M, ydata, perf.Rbar, filter)
        general_contour("Mach Number", ylabel, "mdotf [kg/s]", "Fuel Mass Flow", ...
                       M, ydata, perf.mdotf, filter)
        general_contour("Mach Number", ylabel, "TSFC [s]", "TSFC", ...
                       M, ydata, perf.TSFC, filter)
        general_contour("Mach Number", ylabel, "TA [N]", "Thrust Available", ...
                       M, ydata, perf.TA, filter)
end
    general_contour("Mach Number", ylabel, "CD", "Drag Coefficent", M, ydata, perf.CD, filter)
    general_contour("Mach Number", ylabel, "CL", "Lift Coefficent", M, ydata, perf.model.cond.CL.v, filter)
    general_contour("Mach Number", ylabel, "L/D", "Lift Over Drag", M, ydata, perf.LD, filter)
    Cdw_data = perf.model.CDw;
if max(Cdw_data) > 0
        general_contour("Mach Number", ylabel, "CDw", "Wave Drag Coeffcient", M, ydata, perf.model.CDw, filter)
end
    general_contour("Mach Number", ylabel, "CDi", "Induced Drag Coeffcient", M, ydata, perf.model.CDi, filter)
    general_contour("Mach Number", ylabel, "e_osw", "Oswald Efficency", M, ydata, perf.e_osw, filter)
    general_contour("Mach Number", ylabel, "CLa", "Lift Slope", M, ydata, perf.model.CLa, filter)
    general_contour("Mach Number", ylabel, "Throttle", "Throttle", M, ydata, perf.model.cond.throttle.v, filter)
    general_contour("Airspeed (kts)", ylabel, "Throttle", "Throttle", kts, ydata, perf.model.cond.throttle.v, filter)

    perf.model.clear_mem(); perf.clear_data();
end