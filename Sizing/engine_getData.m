function engineData = engine_getData(name)
    % Before, the table was searched and loaded in every time propulsion was called. This was EXTRMELY slow. With the regression, all we
    % actually need is the two max thrust values. So they are just saved into the plane engine_data object upon loading

    % Thrust in engine_lookup is all in N

    persistent engine_lookup
    % check if the engine_lookup table is already loaded. This helps signficiantly with speed. If it is not loaded, load it
    if isempty(engine_lookup)
        engine_lookup = readtable("engine_lookup.xlsx");
    end
    % table names: EngineName, SealevelMaxThrust_noAB_, SealevelMaxThrust_AB_, CompressorPRC, FanPRC, BypassRatio, T04_BurnerOutletTemp_K_, QR_LowerHeatingValue_J_kg_

    selectedEngine=engine_lookup(ismember(engine_lookup.engine_name,name),:); % get the table row asked for and return as a table

    if(isempty(selectedEngine))
        error("Did not find engine: " + obj.engine)
    end

    T0_NoAB = selectedEngine.h0_maxThrust_NoAB;
    T0_AB = selectedEngine.h0_maxThrust_AB;

    engineData = [T0_NoAB, T0_AB];

end