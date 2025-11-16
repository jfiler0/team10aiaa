function loadout = buildLoadout(storesList)

    % returns struct with loadout.weight as total weight of stores in N and loadout.CD0, increase in parasite drag
    % also has fields for external_fuel_N (summed amount of fuel that can be stored in drop tanks),
    % loadout.storesList as a copy of he input, loadout.storesNames as a string array of store names

    % Note that loadout.weight is the empty weight of drop tanks + weapon stores.
    % This function still misses the weight of jettison equipment and their drag

    loadout.weight = 0;
    loadout.weight_tanks_empty = 0;
    loadout.weight_weapons = 0;
    loadout.CD0 = 0;
    loadout.external_fuel_N = 0;
    loadout.storesList = storesList;
    loadout.storesNames = storesList; % Cheap way of setting the size

    % storesList is an array of strings that shoul match store coes in stores_lookup.xslx
    stores_lookup = readtable("stores_lookup.xlsx");
    
    for i = 1:numel(storesList)
        store=stores_lookup(ismember(stores_lookup.store_code,storesList(i)),:);

        loadout.weight = loadout.weight + lb2N(store.weight_lbf);
        loadout.CD0 = loadout.CD0 + store.drag_index / 1000; % *** Likely not totally correct but close enough
        loadout.external_fuel_N = loadout.external_fuel_N + lb2N( store.fuel_volume_gal * 6.7); % Found 6.7 lb/gal online
        loadout.storesNames(i) = store.full_name;

        if(store.store_type == "Drop Tank")
            loadout.weight_tanks_empty = loadout.weight_tanks_empty + lb2N(store.weight_lbf);
        else
            loadout.weight_weapons = loadout.weight_weapons + lb2N(store.weight_lbf);
        end
    
    end

end