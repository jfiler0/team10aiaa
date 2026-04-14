function geom = setLoadout(geom, storeNames)

    settings = readSettings();

    % geom - the plane we are working with
    % storeNames - an array of strings that should match existing entries in the "Stores" folder

    % We will check this matches the racks defined in geom.racks, read the json files, and write it to .stores
    % An element in storeNames can be "" or "X" with slightly different behavior
    %   "" stores will be filtered out
    %   "X" stores are created and added to the rack but have no mass or drag

    rack_positions = geom.racks; % array of normalized y positions for each rack
    num_racks = length(rack_positions);

    if(length(storeNames) ~= num_racks)
        error("Cannot set loadout. The number of provided store names does not match the number of defined racks.")
    end

    % Identify the empty stores
    filter = ~strcmp(storeNames, ""); % non empty stores

    % Make an array of rack positions
    
    rack_numbers = 1:num_racks;

    % Filter out the empty stores
    storeNames = storeNames(filter);
    rack_positions = rack_positions(filter);
    rack_numbers = rack_numbers(filter);
    
    % New counter of the number of non empty racks
    num_stores = length(storeNames);

    fullPath = mfilename('fullpath');
    codeFolder = fileparts(fullPath);
    storesFolder = fullfile(codeFolder, "../AircraftFiles/Stores");
        % If this is changed, writeStoreStruct must also be corrected

    % Prefill with empty stores to make sure fields are correct
    geom.stores = repmat(readStoreFile("X", storesFolder), [num_stores, 1]); % prefills with a bunch of empty stores

    geom.weights.loaded = json_entry("Loaded Weight", 0, "N", true);
    geom.weights.ext_max_fuel_weight = json_entry("External Tank Max Fuel Weight", 0, "N", true);

    for i = 1:num_stores
        geom.stores(i) = readStoreFile(storeNames(i), storesFolder);
        
        geom.stores(i).rack_ypos = json_entry("Rack Y-Position (normalized)", rack_positions(i), "", true);
        geom.stores(i).rack_num = json_entry("Rack Number", rack_numbers(i), "", true);

        geom.weights.loaded.v = geom.weights.loaded.v + geom.stores(i).weight.v; % does not include fuel weight
        geom.weights.ext_max_fuel_weight.v = geom.weights.ext_max_fuel_weight.v + geom.stores(i).fuel_vol.v * settings.jeta_density * settings.g_const; % fuel_vol in liters to fuel weight in N
    end

end

function struct = readStoreFile(name, storesFolder)
    file_path = fullfile(storesFolder, name + ".json");
    try
        struct = readstruct(file_path);
    catch
        error("No store file was found at: '%s'", file_path)
    end
end