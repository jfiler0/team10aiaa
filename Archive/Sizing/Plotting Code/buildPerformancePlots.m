function buildPerformancePlots(plane, W, N)
    % M: Input the weight you want to check for all of these. Likely plane.MTOW
    % N: Master resolution. Likely betwen 10 and 50

    hvec = linspace(plane.alt_range(1), plane.alt_range(2), N);  % Altitude from 100 m to 40,000 ft but still in m here
    Mvec = linspace(plane.mach_range(1), plane.mach_range(2), N);

    [M, h] = meshgrid(Mvec, hvec);

    emptyM = zeros(size(M));
    % Preallocate result matrices - h and M

        % AERODYNAMICS
        trimCL = emptyM;
        CD = emptyM;
        CDi = emptyM;
        D = emptyM;

        % PROPULSION
        TA_AB    = zeros(size(M));
        TSFC_AB  = zeros(size(M));
        alpha_AB = zeros(size(M));
        mdotf_AB = zeros(size(M));

        TA_NoAB    = zeros(size(M));
        TSFC_NoAB  = zeros(size(M));
        alpha_NoAB = zeros(size(M));
        mdotf_NoAB = zeros(size(M));

        qinf = zeros(size(M));

        % PEFORMANCE
        turn_rate = emptyM;
        n_max = emptyM;
        excessPower_NoAB = emptyM;
        excessPower_AB = emptyM;

        turn_rate_sustained = emptyM;
        n_max_sustained = emptyM;
        
    % % Preallocate - just M
        CL_max_clean = zeros(size(Mvec));
        CL_max_flapped = zeros(size(Mvec));
        CLa = zeros(size(Mvec));
        CDW = zeros(size(Mvec));
    
    emptyhvec = zeros(size(hvec));
    % % Preallocate - just h
        stallSpeed = emptyhvec;
        takeoffSpeed = emptyhvec;
        landingSpeed = emptyhvec;

        Tvec = emptyhvec;
        avec = emptyhvec;
        Pvec = emptyhvec;
        rhovec = emptyhvec;
        muvec = emptyhvec;

        excessPowerMax_NoAB = emptyhvec;
        mach_maxExcess_NoAB = emptyhvec;
        maxMach_NoAB = emptyhvec;

        excessPowerMax_AB = emptyhvec;
        mach_maxExcess_AB = emptyhvec;
        maxMach_AB = emptyhvec;

        climbRate_AB = emptyhvec;
        climbAngle_AB = emptyhvec;
        climbSpeed_AB = emptyhvec;

        climbRate_NoAB = emptyhvec;
        climbAngle_NoAB = emptyhvec;
        climbSpeed_NoAB = emptyhvec;
    
    progressbar('Performance Plots')
    num_ops = numel(M) + numel(Mvec) + numel(hvec);

    % Query functions for each point
    for i = 1:numel(M)
        progressbar(i/num_ops)

        [q, ~, ~, ~] = metricFreestream(h(i), M(i));
        qinf(i) = q;

        trimCL(i) = plane.calcTrimCL(h(i), M(i), W);
        [CD(i), ~, CDi(i), ~] = plane.calcCD(trimCL(i), M(i));
        D(i) = CD(i) * q * plane.S_ref;

        [TA_AB(i), TSFC_AB(i), alpha_AB(i), mdotf_AB(i)] = plane.calcProp(M(i), h(i), 1);
        [TA_NoAB(i), TSFC_NoAB(i), alpha_NoAB(i), mdotf_NoAB(i)] = plane.calcProp(M(i), h(i), 0);
        

        [turn_rate(i), n_max(i)] = plane.getMaxTurn( h(i), M(i), W);
        [turn_rate_sustained(i), n_max_sustained(i)] = plane.getSustainedTurn( h(i), M(i), W, 1);

        excessPower_AB(i) = plane.calcExcessPower(h(i), M(i), W, 1);
        excessPower_NoAB(i) = plane.calcExcessPower(h(i), M(i), W, 0);

        if excessPower_NoAB(i) < 0
            excessPower_NoAB(i) = NaN;
        end
        if excessPower_AB(i) < 0
            excessPower_AB(i) = NaN;
        end

    end

    for i = 1:numel(Mvec)
        progressbar((i + numel(M))/num_ops)
        [CL_max_clean(i), CL_max_flapped(i), CLa(i)] = plane.calcCL(Mvec(i));
        CDW(i) = plane.CDW_interp(Mvec(i));
    end

    for i = 1:numel(hvec)
        progressbar((i + numel(M) + numel(Mvec))/num_ops)

        [CL_max_clean(i), CL_max_flapped(i), CLa(i)] = plane.calcCL(Mvec(i));

        stallSpeed(i) = plane.calcStallSpeed(hvec(i), W);
        takeoffSpeed(i) = plane.calcTakeoffSpeed(hvec(i), W);
        landingSpeed(i) = plane.calcLandingSpeed(hvec(i), W);

        [Tvec(i), avec(i), Pvec(i), rhovec(i), muvec(i)] = queryAtmosphere(hvec(i), [1 1 1 1 1]);

        if(i == 1)
            calcMaxExcessPower_NoAB_Mguess = 2;
            calcMaxMachFixedAlt_NoAB_Mguess = 2;

            calcMaxExcessPower_AB_Mguess = 0.5;
            calcMaxMachFixedAlt_AB_Mguess = 2;
        else
            calcMaxExcessPower_NoAB_Mguess = mach_maxExcess_NoAB(i - 1);
            calcMaxMachFixedAlt_NoAB_Mguess = maxMach_NoAB(i - 1);

            calcMaxExcessPower_AB_Mguess = mach_maxExcess_AB(i - 1);
            calcMaxMachFixedAlt_AB_Mguess = maxMach_AB(i - 1);

        end

        [excessPowerMax_NoAB(i), ~, mach_maxExcess_NoAB(i)] = plane.calcMaxExcessPower(hvec(i), W, 0, calcMaxExcessPower_NoAB_Mguess);
        maxMach_NoAB(i) = plane.calcMaxMachFixedAlt( hvec(i), W, 0, calcMaxMachFixedAlt_NoAB_Mguess);

        [excessPowerMax_AB(i), ~, mach_maxExcess_AB(i)] = plane.calcMaxExcessPower(hvec(i), W, 1, calcMaxExcessPower_AB_Mguess);
        maxMach_AB(i) = plane.calcMaxMachFixedAlt( hvec(i), W, 1, calcMaxMachFixedAlt_AB_Mguess);

        [climbRate_AB(i), climbAngle_AB(i), climbSpeed_AB(i)] = plane.calcMaxClimbRate( hvec(i), W, 1);
        [climbRate_NoAB(i), climbAngle_NoAB(i), climbSpeed_NoAB(i)] = plane.calcMaxClimbRate( hvec(i), W, 0);

    end

    progressbar(1)

    %% AERODYNAMICS PLOT

    figure('Name',"Aerodynamics");
    subplot(3, 3, 1);
    surf(M, m2ft(h)/1000, trimCL, 'EdgeColor', 'none')
    xlabel('$M$')
    ylabel('$h$ [kft]')
    zlabel('$C_L$')
    title('Trim Lift Coefficent')

    subplot(3, 3, 2);
    surf(M, m2ft(h)/1000, CD, 'EdgeColor', 'none')
    xlabel('$M$')
    ylabel('$h$ [kft]')
    zlabel('$CD$')
    title('Drag Coefficent')

    subplot(3, 3, 3);
    surf(M, m2ft(h)/1000, CDi, 'EdgeColor', 'none')
    xlabel('$M$')
    ylabel('$h$ [kft]')
    zlabel('$CD_i$')
    title('Induced Drag Coefficent')

    subplot(3, 3, 4);
    surf(M, m2ft(h)/1000, atand(1./(trimCL./CD)), 'EdgeColor', 'none')
    xlabel('$M$')
    title("Glide Angle (deg)")
    ylabel('$h$ [kft]')

    subplot(3, 3, 5)
    surf(Mvec, m2ft(h)/1000, D/1000, 'EdgeColor', 'none')
    xlabel('$M$')
    ylabel('$h$ [kft]')
    zlabel('$D$ [kN]')
    title('Total Drag')

    subplot(3, 3, 6)
    plot(Mvec, CDW)
    xlabel('$M$')
    ylabel('$C_{D_W}$')
    title("Wave Drag")

    subplot(3, 3, 7)
    plot(Mvec, CL_max_clean, DisplayName="Clean")
    hold on;
    plot(Mvec, CL_max_flapped, DisplayName="Flapped")
    xlabel('$M$')
    ylabel('$C_{L_{max}}$')
    title("Max Lift Coefficent")
    legend(Location="best");

    subplot(3, 3, 8)
    plot(Mvec, CLa)
    xlabel('$M$')
    ylabel('$C_{L_\alpha}$')
    title("Lift Slope")

    subplot(3, 3, 9)
    surf(M, m2ft(h)/1000, trimCL./CD, 'EdgeColor', 'none')
    xlabel('$M$')
    ylabel('$h$ [kft]')
    zlabel('$\frac{L}{D}$')
    title('Lift over Drag')
    
    subplot(3, 3, 9)
    surf(M, m2ft(h)/1000, trimCL./CD, 'EdgeColor', 'none')
    xlabel('$M$')
    ylabel('$h$ [kft]')
    zlabel('$\frac{L}{D}$')
    title('Lift over Drag')

    sgtitle("AERODYNAMICS")

    %% ATMOSPHERE PLOT

    figure('Name',"Atmosphere");
    subplot(2, 2, 1)
    plot(m2ft(hvec)/1000, Tvec);
    ylabel("$T$ [K]")
    yyaxis right;
    plot(m2ft(hvec)/1000, avec);
    ylabel("$a$ [m/s]")

    xlabel("$h$ [kft]")
    title("Temperature \& Speed of Sound")

    subplot(2, 2, 2)
    plot(m2ft(hvec)/1000, Pvec/1000);
    xlabel("$h$ [kft]")
    ylabel("$P$ [kPa]")
    title("Pressure")

    subplot(2, 2, 3)
    plot(m2ft(hvec)/1000, rhovec);
    xlabel("$h$ [kft]")
    ylabel("$\rho$ [kg/m3]")
    title("Density")

    subplot(2, 2, 4)
    plot(m2ft(hvec)/1000, muvec);
    xlabel("$h$ [kft]")
    ylabel("$\mu$ [Pa*s]")
    title("Dynamic Viscosity")

    sgtitle("ATMOSPHERE")

    %% PROPULSION
    figure('Name',"Propulsion");
    
    subplot(2, 2, 1);
    surf(M, m2ft(h)/1000, TA_NoAB/1000, 'EdgeColor', 'none', 'FaceAlpha', 1.0);
    hold on
    surf(M, m2ft(h)/1000, TA_AB/1000, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    hold off
    view(3)
    axis tight
    shading interp
    set(gcf, 'Renderer', 'opengl')
    xlabel('$M$')
    ylabel('$h$ [kft]')
    zlabel('$T_A$ [kN]')
    title('Thrust Available')
    
    subplot(2, 2, 2);
    surf(M, m2ft(h)/1000, TSFC_NoAB, 'EdgeColor', 'none', 'FaceAlpha', 1.0);
    hold on
    surf(M, m2ft(h)/1000, TSFC_AB, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    hold off
    view(3)
    axis tight
    shading interp
    set(gcf, 'Renderer', 'opengl')
    xlabel('$M$')
    ylabel('$h$ [kft]')
    zlabel('TSFC [kg/Ns]')
    title('Thrust Specific Fuel Consumption')
    
    subplot(2, 2, 3);
    surf(M, m2ft(h)/1000, alpha_NoAB, 'EdgeColor', 'none', 'FaceAlpha', 1.0);
    hold on
    surf(M, m2ft(h)/1000, alpha_AB, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    hold off
    view(3)
    axis tight
    shading interp
    set(gcf, 'Renderer', 'opengl')
    xlabel('$M$')
    ylabel('$h$ [kft]')
    zlabel('$\alpha$')
    title('Thrust Lapse')
    
    subplot(2, 2, 4);
    surf(M, m2ft(h)/1000, mdotf_NoAB, 'EdgeColor', 'none', 'FaceAlpha', 1.0);
    hold on
    surf(M, m2ft(h)/1000, mdotf_AB, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    hold off
    view(3)
    axis tight
    shading interp
    set(gcf, 'Renderer', 'opengl')
    xlabel('$M$')
    ylabel('$h$ [kft]')
    zlabel('$\dot{m}_f$ [kg/s]')
    title('Max Fuel Flow')
    
    sgtitle("PROPULSION")

    %% PERFORMANCE
    figure('Name',"Performance");
    subplot(2, 3, 1);
    surf(M, m2ft(hvec)/1000, turn_rate, 'EdgeColor', 'none')
    xlabel('$M$')
    ylabel('$h$ [kft]')
    zlabel('Turn Rate [deg/s]')
    title('Maximum Turn Rate')

    subplot(2, 3, 2);
    surf(M, m2ft(hvec)/1000, turn_rate_sustained, 'EdgeColor', 'none')
    xlabel('$M$')
    ylabel('$h$ [kft]')
    zlabel('Turn Rate [deg/s]')
    title('Max Sustained Rate')

    subplot(2, 3, 3);
    surf(M, m2ft(hvec)/1000, excessPower_NoAB, 'EdgeColor', 'none', 'FaceAlpha', 1.0);
    hold on
    surf(M, m2ft(hvec)/1000, excessPower_AB, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    hold off
    view(3)
    axis tight
    shading interp
    set(gcf, 'Renderer', 'opengl')
    xlabel('$M$')
    ylabel('$h$ [kft]')
    zlabel('Excess Power [m/s]')
    title('Excess Power')

    subplot(2, 3, 4);
    hold on;
    plot(m2ft(hvec)/1000, excessPowerMax_NoAB, DisplayName="No AB [Excess]", Color='r', LineStyle='-')
    plot(m2ft(hvec)/1000, excessPowerMax_AB, DisplayName="AB [Excess]", Color='b', LineStyle='-')
    ylabel("Excess Power [m/s]")
    yyaxis right;
    plot(m2ft(hvec)/1000, mach_maxExcess_NoAB, DisplayName="No AB [Angle]", Color='r', LineStyle='--')
    plot(m2ft(hvec)/1000, mach_maxExcess_AB, DisplayName="AB [Angle]", Color='b', LineStyle='--')
    ylabel("Mach to Fly")
    xlabel('$h$ [kft]')
    title("Max Excess Power at Altitude")
    % legend(Location="best")
    hold off;

    subplot(2, 3, 5);
    plot(m2ft(hvec)/1000, maxMach_NoAB, DisplayName="No AB", Color='r')
    hold on;
    plot(m2ft(hvec)/1000, maxMach_AB, DisplayName="AB", Color='b')
    xlabel('$h$ [kft]')
    ylabel("Mach")
    title("Max Mach Number at Altitude")
    legend(Location="best")
    hold off;

    subplot(2, 3, 6);
    hold on;
    plot(m2ft(hvec)/1000, climbRate_NoAB, DisplayName="No AB [Rate]", Color='r', LineStyle='-')
    plot(m2ft(hvec)/1000, climbRate_AB, DisplayName="AB [Rate]", Color='b', LineStyle='-')
    ylabel("Climb Rate [m/s]")
    yyaxis right;
    plot(m2ft(hvec)/1000, climbAngle_NoAB, DisplayName="No AB [Angle]", Color='r', LineStyle='--')
    plot(m2ft(hvec)/1000, climbAngle_AB, DisplayName="AB [Angle]", Color='b', LineStyle='--')
    ylabel("Climb Angle [deg]")
    xlabel('$h$ [kft]')
    title("Max Sustained Climb Rate")
    % legend(Location="best")
    hold off;

    sgtitle("PERFORMANCE")

end