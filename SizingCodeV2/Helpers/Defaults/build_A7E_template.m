clear; % Start fresh

plane = struct();

plane.name = json_entry("Aircraft Name", "A-7E Corsair II", "s");
plane.id = json_entry("Aircraft ID", "a7e_corsair", "s");

plane.fuselage.length = json_entry("Fuselage Length", ft2m(45.34), "m");
plane.fuselage.max_area = json_entry("Fuselage Max Area", 2, "m2");
plane.fuselage.E_WD = json_entry("Fuselage Wave Drag Efficency", 2.2, "");

plane.input.g_limit = json_entry("Structural G-Limit", 5, "");
plane.input.kloc = json_entry("KLOC", 5000, "");
plane.input.fold_ratio = json_entry("Fold Ratio", 0, ""); % for the main wing
plane.input.WF_ratio = json_entry("WF Ratio", 0.4206, "");  % WF = WF_ratio * (MTOW - WE) -> internal fuel weight

plane.weights.mtow = json_entry("Max Takeoff Weight", lb2N(37279), "N");
plane.weights.w_fixed = json_entry("Fixed Weight", lb2N(1500), "N"); % extra avionics

% MAIN WING DEFENITION - only the inboard side of the flap must be defined
    % X_LE, Y_LE, vector of section spans, vector of LE sweep, vector of TE sweep, OPTIONAL: vector of tc, vector of dihedral, offset parameter
    sections = sections_from_sweeps( ft2m(16.16), ft2m(2), ft2m(14.49), ft2m(17.06), 40, 17, tc_vec=[0.06, 0.03], offset=[0, 0, ft2m(3.3)], dihedral_vec=[-8,-8] );
    sec0 = sections(1);
    sec5 = sections(2);

    % MAIN FLAP
    sec1 = btw_section(sec0, sec5, 0.1, flap_length=0.2, control_name="Main Flap");
    sec2 = btw_section(sec0, sec5, 0.5);
    
    % AILERON
    sec3 = btw_section(sec2, sec5, 0.6, flap_length=0.1, control_name="Aileron");
    sec4 = btw_section(sec2, sec5, 0.9);
    
    plane.wing = assemble_surface([sec0, sec1, sec2, sec3, sec4, sec5]);

% ELEVATOR DEFENITION
    sec0 = new_section(ft2m(7), ft2m(36.5), ft2m(2.25), tc=0.04, offset=[0 0 -0.05], dihedral=8);
    sec2 = new_section(ft2m(1.75), ft2m(44), ft2m(9), tc=0.03, dihedral=8);
    
    % Flap
    sec1 = btw_section(sec0, sec2, 0.1, flap_length=1, control_name="Elevator"); % Full Flying
    
    plane.elevator = assemble_surface([sec0, sec1, sec2]);

% TAIL DEFENITION
    sections = sections_from_sweeps( ft2m(22.08), ft2m(3.3), ft2m(23.36), [ft2m(1.6), ft2m(7.5)], [82, 55], [0, 15], tc_vec=[0.04, 0.04, 0.02], dihedral_vec=[90 90 90]);

    sec0 = sections(1);
    sec1 = sections(2);
    sec4 = sections(3);
    
    % Flap
    sec2 = btw_section(sec1, sec4, 0.1, flap_length=0.15, control_name="Rudder"); % vtail
    sec3 = btw_section(sec1, sec4, 0.9);
    
    plane.rudder = assemble_surface([sec0, sec1, sec2, sec3, sec4], false); % false flag removes mirroring so it is just a vertical tail

plane.type = json_entry("Raymer Aircraft Type", "Jet fighter", "s"); % for coefficent lookups
plane.weights.raymer.A = json_entry("Raymer A Coeff", getRaymerCoefficents(plane.type.v, 1), "");
plane.weights.raymer.C = json_entry("Raymer C Coeff", getRaymerCoefficents(plane.type.v, 2), "");

plane.prop.num_engine = json_entry("Number of Engines", 1, "");
plane.prop.engine = json_entry("Engine Name", "TF41-A-2", "s");

plane.racks = [-1 -0.7 -0.5 -0.2 0.2 0.5 0.7 1]; % spanwise position of the racks
% plane.stores = []; % clean confiuration

plane = setLoadout(plane, ["" "" "" "" "" "" "" ""]);

writeAircraftFile(plane);
    % Writes the actual file generally. This also means the location only needs to be changed in one place