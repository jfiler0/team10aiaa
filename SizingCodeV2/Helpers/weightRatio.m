function W = weightRatio(ratio, geom)
    % Compute the current weight as a ratio 0-1. Goes from empty+payload empty weight to empty+payload empty weight+fuel weights
    % was from empty to MTOW

    % need to compute internal fuel and fuel in external loadout. Can we have that W = 1 is full fuel weight and not mtow
    total_max_fuel = geom.weights.max_fuel_weight.v + geom.weights.ext_max_fuel_weight.v; % adding the internal fuel + fuel from external stores
    W = geom.weights.empty.v + geom.weights.loaded.v + total_max_fuel * ratio;
end