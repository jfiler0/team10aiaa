function geom = processGeometryWeight(geom, settings)
    % apply a weight model to compute the empty weight

    switch settings.WE_model
        case settings.codes.WE_RAYMER
            WE = geom.weights.mtow.v * geom.weights.raymer.A.v * N2lb(geom.weights.mtow.v)^geom.weights.raymer.C.v;
    
        case settings.codes.WE_COMPS
            weight_comps = getRaymerWeightStruct(geom);
            fn = fieldnames(weight_comps);  % get all field names
            total = 0;
            for i = 1:numel(fn)
                total = total + weight_comps.(fn{i});
            end
            WE = total;
    end

    % Usally, we enter derived equations as a string. This can be fixed later. Easier to just used derived override here
    geom.weights.empty = json_entry("Empty Weight", WE, "N", geom, true);


    geom.weights.max_fuel_weight = json_entry("Max Fuel Weight", settings.WF_max_ratio * (geom.weights.mtow.v - geom.weights.empty.v), "N", geom, true);
    geom.weight.loaded = json_entry("Loaded Weight", 0, "N", geom, true);
    
    % TODO: How to compute usable fuel weight

    % obj.max_fuel_weight = obj.MTOW - obj.WE - obj.W_P - obj.W_Tanks - obj.W_F;
    % obj.internal_fuel_weight = 0.7 * obj.max_fuel_weight; % Accounts for tanks in an actual mission
    % obj.mid_mission_weight = obj.MTOW - obj.max_fuel_weight / 2; % Assume half of fuel is burned

end