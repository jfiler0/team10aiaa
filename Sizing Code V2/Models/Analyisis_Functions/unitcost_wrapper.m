function cost = unitcost_wrapper(in)
    % in contains geometry, conditions, settings

    % Exports cost in the millions per aircraft
    cost= ( getcost(N2lb(in.geom.weights.empty.v), in.geom.input.kloc.v) / 500 )  / 1000000; % Divide by 500 since getcost assumes 500 aircraft in the program, and convert to mil
end