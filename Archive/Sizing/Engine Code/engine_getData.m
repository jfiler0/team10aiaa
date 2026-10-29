function engineData = engine_getData(name, geom_trigger)
    % Before, the table was searched and loaded in every time propulsion was called. This was EXTRMELY slow. With the regression, all we
    % actually need is the two max thrust values. So they are just saved into the plane engine_data object upon loading

    % I am being lazy and reusing this code to fetch engine geometry. If geom_trigger = 1. This returns weight/diam instead of thrusts
    if nargin < 2
        geom_trigger = 0;
    end

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

    if geom_trigger == 1
        dry_weight = selectedEngine.weight; % N
        diam = selectedEngine.diameter; % m
        engineData = [dry_weight, diam];
    else
        T0_NoAB = selectedEngine.h0_maxThrust_NoAB; % N
        T0_AB = selectedEngine.h0_maxThrust_AB; % N
        engineData = [T0_NoAB, T0_AB];
    end

end