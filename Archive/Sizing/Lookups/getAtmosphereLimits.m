function [lower, upper] = getAtmosphereLimits()
    % If h = NaN when passed into queryAtmosphere, it sets T to the lower bounds and a to the upper bound
    [lower, upper, ~, ~, ~] = queryAtmosphere(alt, values_to_get);
end