function [TA, TSFC, alpha] = engine_query(engineData, M, h, AB_perc)
    % engineData - [T0_NoAB, T0_AB]
    % M - - mach number
    % h - m - altitude
    % AB_perc - - afterburner percentage (0 to 1)

    % TA - N - available thrust
    % TSFC - (kg/s)/N or kg/Ns - thrust specific fuel consumption
    % alpha - - lapse rate

    % Run Kevin's function
    [F_th_mil, TSFC_mil, F_th_AB, TSFC_AB] = engine_regr(h, M, engineData(1), engineData(2));
    
    % TA if at sea level
    TA0 = engineData(1) + AB_perc * (engineData(2) - engineData(1));
    TA = F_th_mil + AB_perc * ( F_th_AB - F_th_mil );

    TSFC = TSFC_mil + AB_perc * ( TSFC_AB - TSFC_mil );
    if( TA < 0)
        TA = 0;
    end

    alpha = TA / TA0;

end