clear; % Start fresh

plane = struct();

plane.name = json_entry("Aircraft Name", "F-14D Tomcat (unswept)", "s");
plane.id = json_entry("Aircraft ID", "f14_tomact_unswept", "s");

plane.fuselage.length = json_entry("Fuselage Length", in2m(669.3), "m");
plane.fuselage.max_area = json_entry("Fuselage Max Area", 3.5, "m2"); % guessing max area
plane.fuselage.E_WD = json_entry("Fuselage Wave Drag Efficency", 2.2, "");

plane.input.g_limit = json_entry("Structural G-Limit", 7.5, "");
plane.input.kloc = json_entry("KLOC", 3000, "");
plane.input.fold_ratio = json_entry("Fold Ratio", 0, ""); % for the main wing
plane.input.WF_ratio = json_entry("WF Ratio", 0.4206, "");  % WF = WF_ratio * (MTOW - WE) -> internal fuel weight

plane.weights.mtow = json_entry("Max Takeoff Weight", lb2N(74349), "N");
plane.weights.w_fixed = json_entry("Fixed Weight", lb2N(2500 + 6000), "N"); % extra avionics. Mimicking the extra weight from the sweep here

% MAIN WING DEFENITION - only the inboard side of the flap must be defined
    % X_LE, Y_LE, vector of section spans, vector of LE sweep, vector of TE sweep, OPTIONAL: vector of tc, vector of dihedral, offset parameter
    sections = sections_from_sweeps( in2m(238), in2m(57.8), in2m(248), [in2m(55), in2m(218)], [67, 20], [2, 2], tc_vec=[0.08, 0.05, 0.03], dihedral_vec=[-2, -2, -2],offset=[0, 0, 0.2] );
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
    sec0 = new_section(in2m(130), in2m(517.6), in2m(82), tc=0.04, offset=[0 0 -0.35]);
    sec2 = new_section(in2m(40), in2m(626), in2m(170), tc=0.03);
    
    % Flap
    sec1 = btw_section(sec0, sec2, 0.1, flap_length=1, control_name="Elevator"); % Full Flying
    
    plane.elevator = assemble_surface([sec0, sec1, sec2]);

% TAIL DEFENITION
    sections = sections_from_sweeps( in2m(540), in2m(40), in2m(135), [in2m(12), in2m(82)], [75, 48], [0, 15], tc_vec=[0.04, 0.04, 0.02], dihedral_vec=[85 85 85], offset=[0, in2m(45), -in2m(35)]);

    sec0 = sections(1);
    sec1 = sections(2);
    sec4 = sections(3);
    
    % Flap
    sec2 = btw_section(sec1, sec4, 0.1, flap_length=0.15, control_name="Rudder"); % vtail
    sec3 = btw_section(sec1, sec4, 0.9);
    
    plane.rudder = assemble_surface([sec0, sec1, sec2, sec3, sec4]); % false flag removes mirroring so it is just a vertical tail

plane.type = json_entry("Raymer Aircraft Type", "Jet fighter", "s"); % for coefficent lookups
plane.weights.raymer.A = json_entry("Raymer A Coeff", getRaymerCoefficents(plane.type.v, 1), "");
plane.weights.raymer.C = json_entry("Raymer C Coeff", getRaymerCoefficents(plane.type.v, 2), "");

plane.prop.num_engine = json_entry("Number of Engines", 2, "");
plane.prop.engine = json_entry("Engine Name", "F110", "s");

plane.racks = [-1 -0.7 -0.5 -0.2 0.2 0.5 0.7 1]; % spanwise position of the racks
% plane.stores = []; % clean confiuration

plane = setLoadout(plane, ["" "" "" "" "" "" "" ""]);

writeAircraftFile(plane);
    % Writes the actual file generally. This also means the location only needs to be changed in one place


%% AND THE SWEPT VERSION
plane.name = json_entry("Aircraft Name", "F-14D Tomcat (swept)", "s");
plane.id = json_entry("Aircraft ID", "f14_tomact_swept", "s");

% MAIN WING DEFENITION - only the inboard side of the flap must be defined
    % X_LE, Y_LE, vector of section spans, vector of LE sweep, vector of TE sweep, OPTIONAL: vector of tc, vector of dihedral, offset parameter
    sections = sections_from_sweeps( in2m(238), in2m(57.8), in2m(248), [in2m(45), in2m(85)], [67, 67], [45, 50], tc_vec=[0.08, 0.05, 0.03], dihedral_vec=[-2, -2, -2],offset=[0, 0, 0.2] );
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

writeAircraftFile(plane);