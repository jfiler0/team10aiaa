function geom = updatePropulsionInfo(geom)
    % Same process as Sizing V1. Use thi xlsx with standard data for engines. Get the sea level parameters.
    % We save the into the geom object for use with propulsion models.
    % In the future, we can add more columns to the excel file if more advanced models require more inputs

    % In the current configuration, there is no intention to allow changing of engine type during optimization. It must be done manually

    engine_lookup = readtable("engine_lookup.xlsx");

    engine_name = geom.prop.engine.v; % reminder that .v is needed to get "value"

    selectedEngine=engine_lookup(ismember(engine_lookup.engine_name,engine_name),:); 
        % get the table row asked for and return as a table

    if(isempty(selectedEngine))
        error("Did not find engine: " + engine_name)
    end

    % Assign the variables (don't need to pass geom as these should not be changed)
    geom.prop.dry_weight = json_entry("Engine Dry Weight", selectedEngine.weight, "N"); % N
    geom.prop.diam = json_entry("Engine Diameter", selectedEngine.diameter, "m"); % m

    %  NOTE THAT THE IMPACT OF MULTIPLE ENGINES IS APPLIED HERE
    geom.prop.T0_NoAB = json_entry("Max Sealevel Military Thrust", selectedEngine.h0_maxThrust_NoAB * geom.prop.num_engine.v, "N"); % N
    geom.prop.T0_AB = json_entry("Max Sealevel Afterburning Thrust", selectedEngine.h0_maxThrust_AB * geom.prop.num_engine.v, "N"); % N
end