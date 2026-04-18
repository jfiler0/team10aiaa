function CD0 = fortran_cd0(geom, M_vec, h_vec)

caseDef.title = "Hellstinger_V3";
caseDef.Sref = m2ft(m2ft(geom.ref_area.v))
caseDef.scale = 1;
caseDef.inmd  = 0;  % 0 => xinput is altitude in kft

fuse_tc = geom.fuselage.diameter.v / geom.fuselage.length.v;

if geom.rudder.mirror.v
    vtail_area = m2ft(m2ft(2*geom.rudder.area.v));
else
    vtail_area = m2ft(m2ft(4*geom.rudder.area.v));
end

caseDef.components = struct( ...
    "name",  {"FUSELAGE",  "WING",   "HTAIL",  "VTAIL"}, ...
    "Swet",  {m2ft(m2ft(geom.fuselage.area.v)),    m2ft(m2ft(4*geom.wing.area.v)),   m2ft(m2ft(4*geom.elevator.area.v)),  vtail_area}, ... % top and bottom
    "Refl",  {m2ft(geom.fuselage.length.v), m2ft(geom.wing.average_chord.v),  m2ft(geom.elevator.average_chord.v), m2ft(geom.rudder.average_chord.v)}, ... % essentially the average chord
    "tc",    {fuse_tc,                      geom.wing.average_tc.v,           geom.elevator.average_tc.v,          geom.rudder.average_tc.v}, ...
    "icode", {1,                            0,                                0,                                   0}, ... % 1 -> body of revolution. 0 -> planar
    "trans", {0.0,                          0.0,                              0.0,                                 0.0} ... % 0 -> all turbulent. 1 -> all laminar. 0-1 -> some mix
);


% Aircraft at Sea Level and 30kft Max Machs
caseDef.conds = [M_vec' , m2ft(h_vec')/1000 ];

out = run_Friction(caseDef);

% Cd_friction     Cd_form      Cd_total 
CD0 = out.table.Cd_total';

end