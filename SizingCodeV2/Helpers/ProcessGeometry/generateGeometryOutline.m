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
        0, 0 , 0 ]; % custom defenition

    outline.coords.fuseage = [ fuse_coords ; flip(fuse_coords(1:(end-1), 1)) , flip(-fuse_coords(1:(end-1), 2)) , flip(-fuse_coords(1:(end-1), 3)) ];

    geom.outline = outline;
end

function coords = coords_from_object(geom, objName)
    sections = geom.(objName).sections;

    % One arrayfun: each section → [le_x, le_y, le_z, te_x, te_y, te_z]
    data = arrayfun(@(s) apply_section_twist(s, geom.(objName).qrtr_chd_x.v), sections, 'UniformOutput', false);

    data   = vertcat(data{:});          % N×6
    coords = [data(:,1:3); ...          % LE points  (N×3)
              flip(data(:,4:6), 1)];    % TE flipped (N×3)
                                        % result: 2N×3
end

function out = apply_section_twist(s, qrtr_chd_x)

% qrtr_chd_x is an average of all the sections. This makes a singular rotation line that looks much better than rotating about each locally

% LE: s.le_coords , TE: s.te_choords , 1/4 chord: s.qrtr_chd_coords
% Rotate about [0 cosd(s.dihedral) sin(s.dihedral)] for s.twist degrees

% GOAL: Return vector of 6 elements [LEx, LEy , LEz, TEx, TEy, TEz]

if(s.twist.v == 0)
    out = [s.le_coords, s.te_coords];

else

    rot_point = [qrtr_chd_x, s.qrtr_chd_coords(2), s.qrtr_chd_coords(3)]; % get x from the average but y and z from local
    
    le_rel = s.le_coords - rot_point; % le reltative to quarter chord
    te_rel = s.te_coords - rot_point; % te reltative to quarter chord
    
    axis = [0 cosd(s.dihedral.v) sind(s.dihedral.v)];
    theta = s.twist.v;
    
    % Rodrigues' rotation formula components
    K = [    0     -axis(3)  axis(2);
          axis(3)     0     -axis(1);
         -axis(2)  axis(1)     0   ];
    R = eye(3) + sind(theta)*K + (1 - cosd(theta))*(K*K);
    
    le_rot = rot_point + (R * le_rel')';
    te_rot = rot_point + (R * te_rel')';
    
    out = [le_rot, te_rot];
end

end