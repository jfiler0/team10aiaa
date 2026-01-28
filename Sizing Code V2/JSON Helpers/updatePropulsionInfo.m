function geom = updatePropulsionInfo(geom)
    engine_lookup = readtable("engine_lookup.xlsx");

    engine_name = geom.prop.engine.v;

    selectedEngine=engine_lookup(ismember(engine_lookup.engine_name,engine_name),:); % get the table row asked for and return as a table

    if(isempty(selectedEngine))
        error("Did not find engine: " + engine_name)
    end

    geom.prop.dry_weight = json_entry("Engine Dry Weight", selectedEngine.weight, true, "N"); % N
    geom.prop.diam = json_entry("Engine Diameter", selectedEngine.diameter, true, "m"); % m
    %% NOTE THAT THE IMPACT OF MULTIPLE ENGINES IS APPLIED HERE
    geom.prop.T0_NoAB = json_entry("Max Sealevel Military Thrust", selectedEngine.h0_maxThrust_NoAB * geom.prop.num_engine.v, true, "N"); % N
    geom.prop.T0_AB = json_entry("Max Sealevel Afterburning Thrust", selectedEngine.h0_maxThrust_AB * geom.prop.num_engine.v, true, "N"); % N
end