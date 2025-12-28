function geom = processGeometryInput(geom)
    % Take the simplified geometry file, then compute a bunch of important derived variables

    geom.wing.chord_avg = 0.5 * ( geom.wing.root_chord + geom.wing.tip_chord );
    geom.wing.tr = geom.wing.tip_chord / geom.wing.root_chord; % Taper Ratio
    geom.wing.semi_span = geom.wing.span / 2;
    geom.wing.Lambda_TE = atand(tand(geom.wing.le_sweep) - 2 * (geom.wing.root_chord - geom.wing.chord_avg) / geom.wing.semi_span);
    geom.wing.AR = geom.wing.span / geom.wing.chord_avg;
    geom.wing.area = geom.wing.span * geom.wing.chord_avg;
    geom.ref_area = geom.wing.area; % Typical definition for reference area

    geom.fold_span = geom.wing.span * (1 - geom.wing.fold_ratio);
    geom.wing_height = 0.1333 * geom.fuselage.length; % height of the leading edge from the ground (estimations)
    geom.fold_height = geom.wing_height + (geom.wing.span * 0.5) * geom.wing.fold_ratio; % How hight the wings would reach straight up

    [A, C] = getRaymerCoefficents(geom.type); % need to store these as it is an expensive call
    geom.weights.raymer.A = A;
    geom.weights.raymer.C = C;

    % obj.D = 2*sqrt(obj.A_max/pi); % Assuming roughly circular cross section to get fuselage diameter/width

end