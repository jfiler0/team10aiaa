clear; % Start fresh

plane = struct();

plane.name = json_entry("Aircraft Name", "F-16A Block 5 Fighting Falcon", "s");
plane.id = json_entry("Aircraft ID", "f16_falcon", "s");

plane.fuselage.length = json_entry("Fuselage Length", ft2m(49.49), "m");
plane.fuselage.max_area = json_entry("Fuselage Max Area", 2, "m2");
plane.fuselage.E_WD = json_entry("Fuselage Wave Drag Efficency", 2.2, "");

plane.input.g_limit = json_entry("Structural G-Limit", 9, "");
plane.input.kloc = json_entry("KLOC", 5000, "");
plane.input.fold_ratio = json_entry("Fold Ratio", 0, ""); % for the main wing
plane.input.WF_ratio = json_entry("WF Ratio", 0.4206, "");  % WF = WF_ratio * (MTOW - WE) -> internal fuel weight

plane.weights.mtow = json_entry("Max Takeoff Weight", lb2N(35400), "N");
plane.weights.w_fixed = json_entry("Fixed Weight", lb2N(1500), "N"); % extra avionics

fuse_offset = 6.537; % in vsp it is defined that far from the origin
% MAIN WING DEFENITION - only the inboard side of the flap must be defined
    lerx_root = 9.06;
    % X_LE, Y_LE, vector of section spans, vector of LE sweep, vector of TE sweep, OPTIONAL: vector of tc, vector of dihedral, offset parameter
    sections = sections_from_sweeps( fuse_offset-4.734, 0.41, lerx_root, [1.18, 3.58], [76, 39], [-0.96, -0.96], tc_vec=[0.06, 0.04, 0.02], offset=[0, 0, 0.2] );
    sec0 = sections(1);
    sec1 = sections(2);
    sec6 = sections(3);

    % MAIN FLAP
    sec2 = btw_section(sec1, sec6, 0.1, flap_length=0.2, control_name="Main Flap");
    sec3 = btw_section(sec1, sec6, 0.5);
    
    % AILERON
    sec4 = btw_section(sec1, sec6, 0.6, flap_length=0.1, control_name="Aileron");
    sec5 = btw_section(sec1, sec6, 0.9);
    
    plane.wing = assemble_surface([sec0, sec1, sec2, sec3, sec4, sec5, sec6]);

% ELEVATOR DEFENITION
    sec0 = new_section(3.07, fuse_offset + 5.236, 0.799, tc=0.04, offset=[0 0 -0.05], dihedral=-15);
    sec2 = new_section(1.0, fuse_offset + 5.236 + 3.07 - 1.0, 0.799 + 2.33, tc=0.03, dihedral=-15);
    
    % Flap
    sec1 = btw_section(sec0, sec2, 0.1, flap_length=1, control_name="Elevator"); % Full Flying
    
    plane.elevator = assemble_surface([sec0, sec1, sec2]);

% TAIL DEFENITION
    sections = sections_from_sweeps( fuse_offset+ 3.115, 0.768, 4.38690, [0.55, 2.29], [72.73, 47.25], [0, 26], tc_vec=[0.04, 0.04, 0.02], dihedral_vec=[90 90 90]);

    sec0 = sections(1);
    sec1 = sections(2);
    sec4 = sections(3);
    
    % Flap
    sec2 = btw_section(sec1, sec4, 0.1, flap_length=0.15, control_name="Rudder"); % vtail
    sec3 = btw_section(sec1, sec4, 0.9);
    
    plane.rudder = assemble_surface([sec0, sec1, sec2, sec3, sec4], readSettings(), false); % false flag removes mirroring so it is just a vertical tail

plane.type = json_entry("Raymer Aircraft Type", "Jet fighter", "s"); % for coefficent lookups
plane.weights.raymer.A = json_entry("Raymer A Coeff", getRaymerCoefficents(plane.type.v, 1), "");
plane.weights.raymer.C = json_entry("Raymer C Coeff", getRaymerCoefficents(plane.type.v, 2), "");

plane.prop.num_engine = json_entry("Number of Engines", 1, "");
plane.prop.engine = json_entry("Engine Name", "F100", "s");

plane.racks = [-1 -0.7 -0.5 -0.2 0 0.2 0.5 0.7 1]; % spanwise position of the racks
% plane.stores = []; % clean confiuration

plane = setLoadout(plane, ["" "" "" "" "" "" "" ""]);

writeAircraftFile(plane);
    % Writes the actual file generally. This also means the location only needs to be changed in one place