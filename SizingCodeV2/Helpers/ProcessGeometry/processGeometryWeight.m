function geom = processGeometryWeight(geom, settings)
    % apply a weight model to compute the empty weight

    WE = NaN; % if this still NaN, it sums comp weights to get NaN

    switch settings.WE_model
        case settings.codes.WE_RAYMER
            WE = geom.weights.mtow.v * geom.weights.raymer.A.v * N2lb(geom.weights.mtow.v)^geom.weights.raymer.C.v;
    
            weight_comps = struct(); % empty

        case settings.codes.WE_COMPS
            weight_comps = getRaymerWeightStruct(geom);
            
        case settings.codes.WE_Nicolai
            model = model_class(settings, geom);
            perf = performance_class(model);

            % iterate here

            weight_comps = struct(); % set this to your list of components
            WE = 1000; % Need to make this something

        case settings.codes.WE_Roskam
            model = model_class(settings, geom);
            perf = performance_class(model);

            output = RoskamWeightCalculator(geom, perf);

            weight_comps = output; % set this to your list of components
    end

    if isnan(WE)
        fn = fieldnames(weight_comps);  % get all field names
        total = 0;
        for i = 1:numel(fn)
            total = total + weight_comps.(fn{i});
        end
        WE = total;
    end

    % Usally, we enter derived equations as a string. This can be fixed later. Easier to just used derived override here
    geom.weights.empty = json_entry("Empty Weight", WE, "N", true); % this is with no stores
    geom.weights.max_fuel_weight = json_entry("Max Fuel Weight", geom.input.WF_ratio.v * (geom.weights.mtow.v - geom.weights.empty.v), "N", true);
    geom.weights.loaded = json_entry("Loaded Weight", 0, "N", true); % set with setLoadout
    geom.weights.ext_max_fuel_weight = json_entry("External Tank Max Fuel Weight", 0, "N", true); % set with setLoadout
    geom.weights.components = weight_comps;
end