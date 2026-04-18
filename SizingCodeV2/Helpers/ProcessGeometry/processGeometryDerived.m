function geom = processGeometryDerived(geom)
    % Take the simplified geometry file, then compute a bunch of important derived variables

    % This file is called anytime a geometry variable is changed right now. Which is very inefficent (especially given the amount of
    % constructors and strings
    % This is why each has the actual equation to update them embedded as a callable string. In the future, the code will only update the
    % variables it needs to
    
    geom.ref_area = json_entry("Reference Area", geom.wing.area.v * 2, "m2", true); % since section area is not mirrored

    geom.wing_height = json_entry("Wing Leading Edge Height", 0.1333 * geom.fuselage.length.v, "m", true);
    
    geom.fold_height = json_entry("Maximum Fold Height", geom.wing_height.v + (geom.wing.span.v * 0.5) * geom.input.fold_ratio.v, "m", true);

    geom.fuselage.diameter = json_entry("Fuselage Equivalent Diameter", 2*sqrt( geom.fuselage.max_area.v/pi), "m", true);

    % estimate fuselage area as ellipsoid
    rad = geom.fuselage.diameter.v/2;
    len =  geom.fuselage.length.v/2;

    a = rad;
    c = rad;
    b = len/2;

    SA = 4 * pi * ( ( (a*b)^1.6075 + (a*c)^1.6075 + (b*c)^1.6075 ) / 3)^(1/1.6075);
    geom.fuselage.area = json_entry("Fuselage Estimated Wetted Area", SA, "m2", true);

    geom.wing.fold_span = json_entry("Folded Wing Span", geom.wing.span.v * (1 - geom.input.fold_ratio.v), "m", true);

    geom.wing.fold_tip_chord = json_entry("Folded Tip Chord", geom.wing.root_chord.v + (geom.wing.root_chord.v - geom.wing.tip_chord.v) * ( 1 - geom.input.fold_ratio.v), "m", true);

    geom.wing.fold_area = json_entry("Folded Wing Area", geom.wing.fold_span.v * geom.wing.average_chord.v, "m2", true); % TODO: This is an estimate
end