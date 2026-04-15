%% build_f18_template
% - Goal: For testing, we need an aircraft file. This also provides an example file to reference for future aircraft analyisis. While you
% can build a file like this for each, the XML can be easily edited.
% - The specific assignments for each of these construct names is important. If any are missing, things will almost certainty break. You can
% add new things. It is also critical to keep plane files consistent with the same naming conventions.

% These strings are pretty self explanatory in what they assign. Read json_entry for more info on each field

clear; % Start fresh

plane = struct();

plane.name = json_entry("Aircraft Name", "Hellstinger v3", "s");
plane.id = json_entry("Aircraft ID", "Hellstinger v3", "s");

plane.fuselage.length = json_entry("Fuselage Length", in2m(600), "m");
plane.fuselage.max_area = json_entry("Fuselage Max Area", in2m(in2m(4650)), "m2");
plane.fuselage.E_WD = json_entry("Fuselage Wave Drag Efficency", 2.2, "");

plane.input.g_limit = json_entry("Structural G-Limit", 7.5, "");
plane.input.kloc = json_entry("KLOC", 5000, "");
plane.input.fold_ratio = json_entry("Fold Ratio", 0, ""); % there is no fold right now
plane.input.WF_ratio = json_entry("WF Ratio", 0.6119, "");  % WF = WF_ratio * (MTOW - WE) -> internal fuel weight

plane.weights.mtow = json_entry("Max Takeoff Weight", lb2N(79081), "N");
plane.weights.w_fixed = json_entry("Fixed Weight", lb2N(2000), "N");

% MAIN WING DEFENITION - only the inboard side of the flap must be defined
    
    lerx_root = 7;
    wing_root = in2m(174.1);
    wing_le_x = 0.45 * plane.fuselage.length.v - lerx_root + wing_root;

    sec0 = new_section(lerx_root, wing_le_x, 1, tc=0.06);
    sec1 = new_section(in2m(174.1), wing_le_x + lerx_root - wing_root, 2, tc=0.04);
    sec6 = new_section(0.14 * in2m(174.1), wing_le_x + lerx_root - wing_root + sind(25)*(in2m(426.5)/2 - 2), in2m(426.5)/2, tc=0.02);
    
    % MAIN FLAP
    sec2 = btw_section(sec1, sec6, 0.1, flap_length=0.2, control_name="Main Flap");
    sec3 = btw_section(sec1, sec6, 0.5);
    
    % AILERON
    sec4 = btw_section(sec1, sec6, 0.6, flap_length=0.1, control_name="Aileron");
    sec5 = btw_section(sec1, sec6, 0.9);
    
    plane.wing = assemble_surface([sec0, sec1, sec2, sec3, sec4, sec5, sec6]);
    % plane.wing = assemble_surface([sec0, sec1, sec6]);

% ELEVATOR DEFENITION

    root_chord = 4;
    tip_chord = 1.8;
    sec0 = new_section(root_chord, plane.fuselage.length.v - root_chord, 0, tc=0.04);
    sec2 = new_section(tip_chord, plane.fuselage.length.v - tip_chord, 3.5, tc=0.03);
    
    % Flap
    sec1 = btw_section(sec0, sec2, 0.1, flap_length=1, control_name="Elevator"); % Full Flying
    
    plane.elevator = assemble_surface([sec0, sec1, sec2]);
    % plane.elevator = assemble_surface([sec0, sec2]);

% VTAIL DEFENITION
    root_chord = in2m(79.02);
    tip_chord = in2m(98.62) * 0.4705;
    sec0 = new_section(root_chord, plane.fuselage.length.v - root_chord, 1, tc=0.04, dihedral=60);
    sec3 = new_section(tip_chord, plane.fuselage.length.v - tip_chord, 1+in2m(44.5), tc=0.03, dihedral=60);
    
    % Flap
    sec1 = btw_section(sec0, sec3, 0.1, flap_length=0.15, control_name="Rudder"); % vtail
    sec2 = btw_section(sec0, sec3, 0.9);
    
    plane.rudder = assemble_surface([sec0, sec1, sec2, sec3]);
    % plane.rudder = assemble_surface([sec0, sec3]);

plane.type = json_entry("Raymer Aircraft Type", "Jet fighter", "s"); % for coefficent lookups
plane.weights.raymer.A = json_entry("Raymer A Coeff", getRaymerCoefficents(plane.type.v, 1), "");
plane.weights.raymer.C = json_entry("Raymer C Coeff", getRaymerCoefficents(plane.type.v, 2), "");

plane.prop.num_engine = json_entry("Number of Engines", 2, "");
plane.prop.engine = json_entry("Engine Name", "F110", "s");

plane.racks = [-1 -0.7 -0.5 -0.2 0.2 0.5 0.7 1]; % spanwise position of the racks
% plane.stores = []; % clean confiuration

plane = setLoadout(plane, ["AIM-9X" "" "" "" "" "" "" "AIM-9X"]);
% 
% plane.airfoil = json_entry("Airfoil Code", "NACAXXX", "s")

writeAircraftFile(plane);
    % Writes the actual file generally. This also means the location only needs to be changed in one place