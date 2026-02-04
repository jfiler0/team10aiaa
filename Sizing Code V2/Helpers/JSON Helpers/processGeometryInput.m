function geom = processGeometryInput(geom)
    % Take the simplified geometry file, then compute a bunch of important derived variables
    
    geom.wing.chord_avg = json_entry("Wing Average Chord", "0.5 * ( geom.wing.root_chord.v + geom.wing.tip_chord.v )", "m");
    
    geom.wing.tr = json_entry("Taper Ratio", "geom.wing.tip_chord.v / geom.wing.root_chord.v", ""); 
    
    geom.wing.semi_span = json_entry("Wing Semi-Span", "geom.wing.span.v / 2", "m");
    
    geom.wing.Lambda_TE = json_entry("Wing Trailing Edge Sweep", "atand( tand(geom.wing.le_sweep.v) - 2 * (geom.wing.root_chord.v - geom.wing.chord_avg.v) / geom.wing.semi_span.v )", "deg");
    
    geom.wing.AR = json_entry("Aspect Ratio", "geom.wing.span.v / geom.wing.chord_avg.v", "");
    
    geom.wing.area = json_entry("Wing Area", "geom.wing.span.v * geom.wing.chord_avg.v", "m2");
    
    geom.ref_area = json_entry("Reference Area", "geom.wing.area.v", "m2"); 
    
    geom.fold_span = json_entry("Folded Span", "geom.wing.span.v * (1 - geom.wing.fold_ratio.v)", "m");
    
    geom.wing_height = json_entry("Wing Leading Edge Height", "0.1333 * geom.fuselage.length.v", "m");
    
    geom.fold_height = json_entry("Maximum Fold Height", "geom.wing_height.v + (geom.wing.span.v * 0.5) * geom.wing.fold_ratio.v", "m");
    
    geom.weights.raymer.A = json_entry("Raymer A Coeff", "getRaymerCoefficents(geom.type.v, 1)", "");
    geom.weights.raymer.C = json_entry("Raymer C Coeff", "getRaymerCoefficents(geom.type.v, 2)", "");

    geom.fuselage.diameter = json_entry("Fuselage Equivalent Diameter", "2*sqrt( geom.fuselage.max_area.v/pi)", "m");
end