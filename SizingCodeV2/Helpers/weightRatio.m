function W = weightRatio(ratio, geom)
    % Compute the current weight as a ratio 0-1 from empty to MTOW
    W = geom.weights.empty.v + (geom.weights.mtow.v - geom.weights.empty.v) * ratio;
end