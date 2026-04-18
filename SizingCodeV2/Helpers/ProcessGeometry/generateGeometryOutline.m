function geom = generateGeometryOutline(geom)
    % outline.sections (wing/htail/vtail) -> le chord positions from nose + chord length
    % outline.coords (wing/htail/vtail/fuse) -> global coordinates from nose as 2 columns + rows

    measure_from_centerline = true;
        % When enabled, it draws instead using acutal span of the offset wing from the fuselage.
            % Can be more unstable with small LERX
        % When false, the span artifically increases by the fuselage diameter

    span = geom.wing.span.v;
    rad = geom.fuselage.diameter.v/2; % fuselage radius

    if measure_from_centerline
        span = span - rad * 2;
    end
    semi_span = 0.5 * span;

    strake_norm_span = geom.wing.strake.norm_span.v;
    if measure_from_centerline
        strake_norm_span = strake_norm_span - rad * 2 / geom.wing.span.v;
        if strake_norm_span < 0
            warning("Drawing from centerline results in LERX that does not extend past the fuselage resulting in negative span")
        end
    end

    % length must also get shorter
    strake_norm_length = geom.wing.strake.norm_length.v * strake_norm_span / geom.wing.strake.norm_span.v;

    aft_fuse_diam = geom.prop.diam.v * geom.prop.num_engine.v; % TODO: Should be number of engines

    % Main wing:
    sec1 = makeSecObj( [geom.wing.le_x.v rad 0], geom.wing.root_chord.v );
    sec3 = makeSecObj( [geom.wing.le_x.v + semi_span * sind(geom.wing.le_sweep.v), rad + semi_span semi_span * sind(geom.wing.dihedral.v)], geom.wing.tip_chord.v);
    sec2 = betw_sec(sec1, sec3, strake_norm_span);
    
    strake_length = strake_norm_length * sec1.chord_length;
    sec1 = makeSecObj( [sec1.LE_X - strake_length, sec1.LE_Y, sec1.LE_Z], sec1.chord_length + strake_length);
    
    outline.sections.wing = [sec1, sec2, sec3];

    % Elevator:
    elevator_root_chord = geom.elevator.root_chord.v;
    elevator_tip_chord = geom.elevator.tip_chord.v;
    eleavtor_semispan = geom.elevator.semi_span.v;
    elevator_dihedral = geom.elevator.dihedral.v;

    elevator_le_pos = geom.fuselage.length.v - elevator_root_chord;

    outline.sections.elevator = [...
        makeSecObj( [elevator_le_pos, aft_fuse_diam/2, 0], elevator_root_chord ) ,... 
        makeSecObj( [elevator_le_pos + eleavtor_semispan * sind(geom.wing.le_sweep.v), aft_fuse_diam/2 + eleavtor_semispan, eleavtor_semispan * sind(elevator_dihedral)], elevator_tip_chord ) ...
        ];

    % Vtail
    vtail_root_chord = geom.vtail.root_chord.v;
    vtail_tip_chord = geom.vtail.tip_chord.v;
    vtail_semispan = geom.vtail.semi_span.v;
    elevator_dihedral = geom.vtail.dihedral.v;

    vtail_le_pos = geom.fuselage.length.v - vtail_root_chord;
    
    rudder_sweep = geom.wing.le_sweep.v; % HARD SET ANGLES TO MATCH

    outline.sections.vtail = [...
        makeSecObj( [vtail_le_pos, cosd(elevator_dihedral)*aft_fuse_diam/2, sind(elevator_dihedral)*aft_fuse_diam/2], vtail_root_chord ) ,... 
        makeSecObj( [vtail_le_pos + vtail_semispan * sind(rudder_sweep), cosd(elevator_dihedral)*(aft_fuse_diam/2 + eleavtor_semispan), sind(elevator_dihedral)*(aft_fuse_diam/2 + eleavtor_semispan)], vtail_tip_chord ) ...
        ];

    % coords do not need to close. Assumption is that the first and last points connect

    fuse_coords = [ ...
        geom.fuselage.length.v, aft_fuse_diam/2, 0 ;
        elevator_le_pos, aft_fuse_diam/2 , 0 ; 
        geom.wing.le_x.v + geom.wing.root_chord.v, rad , 0 ; ...
        geom.wing.le_x.v - strake_length, rad , 0 ; ...
        0, 0 , 0 ];

    outline.coords.fuseage = [ fuse_coords ; flip(fuse_coords(1:(end-1), 1)) , flip(-fuse_coords(1:(end-1), 2)) , flip(-fuse_coords(1:(end-1), 3)) ];

    outline.coords.wing = [ outline.sections.wing(1).le_coords ; outline.sections.wing(2).le_coords ; outline.sections.wing(3).le_coords ; outline.sections.wing(3).te_coords ; outline.sections.wing(2).te_coords ; outline.sections.wing(1).te_coords ];

    outline.coords.elevator = [ outline.sections.elevator(1).le_coords ; outline.sections.elevator(2).le_coords ; outline.sections.elevator(2).te_coords ; outline.sections.elevator(1).te_coords ];

    outline.coords.vtail = [ outline.sections.vtail(1).le_coords ; outline.sections.vtail(2).le_coords ; outline.sections.vtail(2).te_coords ; outline.sections.vtail(1).te_coords ];

    geom.outline = outline;
end

function secObj = makeSecObj(le_coords, chord_length, inclination)

    secObj = struct();
    secObj.le_coords = le_coords; % as a vector (X, Y, Z) from nose
    secObj.LE_X = le_coords(1);
    secObj.LE_Y = le_coords(2);
    secObj.LE_Z = le_coords(3);
    secObj.chord_length = chord_length;

    % inclination in body center line

    % TODO: Implement this
    secObj.te_coords = le_coords  + chord_length * [1 0 0]; % as a vector (X, Y, Z) from nose
    secObj.TE_X = secObj.te_coords(1);
    secObj.TE_Y = secObj.te_coords(2);
    secObj.TE_Z = secObj.te_coords(3);
    
end

function sec = betw_sec(sec1, sec2, ratio)
    % Returns a section with a LE position and chord. 0 is sec1, 1 is sec2
    LE_coords_1 = sec1.le_coords;
    LE_coords_2 = sec2.le_coords;

    Chord_1 = sec1.chord_length;
    Chord_2 = sec2.chord_length;

    LE_coords = LE_coords_1 + (LE_coords_2 - LE_coords_1) * ratio;
    Chord = Chord_1 + (Chord_2 - Chord_1) * ratio;

    sec = makeSecObj(LE_coords, Chord);
end