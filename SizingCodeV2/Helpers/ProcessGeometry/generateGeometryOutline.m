function geom = generateGeometryOutline(geom)
    % outline.sections (wing/htail/vtail) -> le chord positions from nose + chord length
    % outline.coords (wing/htail/vtail/fuse) -> global coordinates from nose as 2 columns + rows

    outline.coords.wing = coords_from_object(geom, "wing");
    outline.coords.elevator = coords_from_object(geom, "elevator");
    outline.coords.rudder = coords_from_object(geom, "rudder");

    rad = geom.fuselage.diameter.v/2; % fuselage radius
    aft_fuse_diam = geom.prop.diam.v * geom.prop.num_engine.v; % TODO: Should be number of engines

    % coords do not need to close. Assumption is that the first and last points connect

    fuse_coords = [ ...
        geom.fuselage.length.v, aft_fuse_diam/2, 0 ;
        geom.elevator.le_x.v, aft_fuse_diam/2 , 0 ; 
        geom.wing.le_x.v + geom.wing.root_chord.v, rad , 0 ; ...
        geom.wing.le_x.v, rad , 0 ; ...
        0, 0 , 0 ];

    outline.coords.fuseage = [ fuse_coords ; flip(fuse_coords(1:(end-1), 1)) , flip(-fuse_coords(1:(end-1), 2)) , flip(-fuse_coords(1:(end-1), 3)) ];

    geom.outline = outline;
end

function coords = coords_from_object(geom, objName)
    %CLAUDE:
    sections = geom.(objName).sections;

    % One arrayfun: each section → [le_x, le_y, le_z, te_x, te_y, te_z]
    data = arrayfun(@(s) [s.le_x.v, s.le_y.v, s.le_z.v, ...
                          s.te_x.v, s.te_y.v, s.te_z.v], ...
                   sections, 'UniformOutput', false);

    data   = vertcat(data{:});          % N×6
    coords = [data(:,1:3); ...          % LE points  (N×3)
              flip(data(:,4:6), 1)];    % TE flipped (N×3)
                                        % result: 2N×3
end