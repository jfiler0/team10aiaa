function out = getRaymerWeightStruct(geom)
    % Passing in the aircraft.geom
    out = calcRaymerWeights(getPlaneRaymerWeightInput(geom));
end