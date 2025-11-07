function [TA, TSFC, alpha] = engine_query(engine, M, h, AB_perc)
    % engine - should be a string. It will be the name looked up for engine data
    % M - - mach number
    % h - m - altitude
    % AB_perc - - afterburner percentage (0 to 1)

    % TA - N - available thrust
    % TSFC - (kg/s)/N or kg/Ns - thrust specific fuel consumption
    % alpha - - lapse rate
    persistent engine_lookup
    % check if the engine_lookup table is already loaded. This helps signficiantly with speed. If it is not loaded, load it
    if isempty(engine_lookup)
        engine_lookup = readtable("engine_lookup.xlsx");
    end
    % table names: EngineName, SealevelMaxThrust_noAB_, SealevelMaxThrust_AB_, CompressorPRC, FanPRC, BypassRatio, T04_BurnerOutletTemp_K_, QR_LowerHeatingValue_J_kg_

    selectedEngine=engine_lookup(ismember(engine_lookup.EngineName,engine),:); % get the table row asked for and return as a table

    if(isempty(selectedEngine))
        error("Did not find engine: " + obj.engine)
    end

    % Run Kevin's function
    [F_th_mil, TSFC_mil, F_th_AB, TSFC_AB] = engine_regr(h, M, selectedEngine.SealevelMaxThrust_noAB_, selectedEngine.SealevelMaxThrust_AB_);
    
    % TA if at sea level
    TA0 = selectedEngine.SealevelMaxThrust_noAB_ + AB_perc * (selectedEngine.SealevelMaxThrust_AB_ - selectedEngine.SealevelMaxThrust_noAB_);
    TA = F_th_mil + AB_perc * ( F_th_AB - F_th_mil );

    TSFC = TSFC_mil + AB_perc * ( TSFC_AB - TSFC_mil );
    if( TA < 0)
        TA = NaN;
        TSFC = NaN;
    end

    alpha = TA / TA0;

end