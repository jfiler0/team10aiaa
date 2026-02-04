function geom = processGeometryWeight(geom)
    % apply a weight model to compute the empty weight

    geom.weights.empty = json_entry("Empty Weight", "geom.weights.mtow.v * geom.weights.raymer.A.v * N2lb(geom.weights.mtow.v)^geom.weights.raymer.C.v", "m", geom);

    % geom.weights.components = calcRaymerWeights(getPlaneRaymerWeightInput(geom));
    % fn = fieldnames(geom.weights.components);  % get all field names
    % total = 0;
    % for i = 1:numel(fn)
    %     total = total + geom.weights.components.(fn{i});
    % end
    % geom.weights.empty = total;

    % obj.max_fuel_weight = obj.MTOW - obj.WE - obj.W_P - obj.W_Tanks - obj.W_F;
    % obj.internal_fuel_weight = 0.7 * obj.max_fuel_weight; % Accounts for tanks in an actual mission
    % obj.mid_mission_weight = obj.MTOW - obj.max_fuel_weight / 2; % Assume half of fuel is burned

end