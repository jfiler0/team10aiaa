function geom = processGeometryWeight(geom)

    geom.weights.empty = geom.weights.mtow * geom.weights.raymer.A * N2lb(geom.weights.mtow)^geom.weights.raymer.C;

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