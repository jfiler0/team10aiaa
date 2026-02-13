function geom = processGeometryDerived(geom)
    % Take the simplified geometry file, then compute a bunch of important derived variables

    % This file is called anytime a geometry variable is changed right now. Which is very inefficent (especially given the amount of
    % constructors and strings
    % This is why each has the actual equation to update them embedded as a callable string. In the future, the code will only update the
    % variables it needs to
    
    geom.wing.chord_avg = json_entry("Wing Average Chord", "0.5 * ( geom.wing.root_chord.v + geom.wing.tip_chord.v )", "m", geom);
    
    geom.wing.tr = json_entry("Taper Ratio", "geom.wing.tip_chord.v / geom.wing.root_chord.v", "", geom); 
    
    geom.wing.semi_span = json_entry("Wing Semi-Span", "geom.wing.span.v / 2", "m", geom);
    
    geom.wing.Lambda_TE = json_entry("Wing Trailing Edge Sweep", "atand( tand(geom.wing.le_sweep.v) - 2 * (geom.wing.root_chord.v - geom.wing.chord_avg.v) / geom.wing.semi_span.v )", "deg", geom);
    
    geom.wing.AR = json_entry("Aspect Ratio", "geom.wing.span.v / geom.wing.chord_avg.v", "", geom);
    
    geom.wing.area = json_entry("Wing Area", "geom.wing.span.v * geom.wing.chord_avg.v", "m2", geom);
    
    geom.ref_area = json_entry("Reference Area", "geom.wing.area.v", "m2", geom); 
    
    geom.fold_span = json_entry("Folded Span", "geom.wing.span.v * (1 - geom.wing.fold_ratio.v)", "m", geom);
    
    geom.wing_height = json_entry("Wing Leading Edge Height", "0.1333 * geom.fuselage.length.v", "m", geom);
    
    geom.fold_height = json_entry("Maximum Fold Height", "geom.wing_height.v + (geom.wing.span.v * 0.5) * geom.wing.fold_ratio.v", "m", geom);

    geom.fuselage.diameter = json_entry("Fuselage Equivalent Diameter", "2*sqrt( geom.fuselage.max_area.v/pi)", "m", geom);
end