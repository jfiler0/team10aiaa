%% build_f18_template
% - Goal: For testing, we need an aircraft file. This also provides an example file to reference for future aircraft analyisis. While you
% can build a file like this for each, the XML can be easily edited.
% - The specific assignments for each of these construct names is important. If any are missing, things will almost certainty break. You can
% add new things. It is also critical to keep plane files consistent with the same naming conventions.

% These strings are pretty self explanatory in what they assign. Read json_entry for more info on each field

clear; % Start fresh

plane = struct();

plane.name = json_entry("Aircraft Name", "F/A-18E Super Hornet", "s");
plane.id = json_entry("Aircraft ID", "f18_superhornet", "s");

plane.fuselage.length = json_entry("Fuselage Length", 17.54, "m");
plane.fuselage.max_area = json_entry("Fuselage Max Area", 2.8, "m2");
plane.fuselage.E_WD = json_entry("Fuselage Wave Drag Efficency", 2.2, "");

plane.input.g_limit = json_entry("Structural G-Limit", 7.5, "");
plane.input.kloc = json_entry("KLOC", 5000, "");
plane.input.fold_ratio = json_entry("Fold Ratio", 0.3, ""); % for the main wing
plane.input.WF_ratio = json_entry("WF Ratio", 0.4206, "");  % WF = WF_ratio * (MTOW - WE) -> internal fuel weight

plane.weights.mtow = json_entry("Max Takeoff Weight", lb2N(66000), "N");
plane.weights.w_fixed = json_entry("Fixed Weight", lb2N(1500), "N"); % extra avionics

% MAIN WING DEFENITION - only the inboard side of the flap must be defined
    wing_le_x = 4.280;
    lerx_root = 9.41;
    sec0 = new_section(lerx_root, wing_le_x, 0.297, tc=0.06, dihedral=-1.764, offset=[0 0 0.4]);
    sec1 = new_section(4.507, lerx_root+wing_le_x-4.507, 0.297 + 1.509, tc=0.04, dihedral=-1.764);
    sec6 = new_section(1.686, lerx_root+wing_le_x-1.686 - 0.25, 4.518 + 0.297 + 1.509, tc=0.02, dihedral=-1.764);
    
    % MAIN FLAP
    sec2 = btw_section(sec1, sec6, 0.1, flap_length=0.2, control_name="Main Flap");
    sec3 = btw_section(sec1, sec6, 0.5);
    
    % AILERON
    sec4 = btw_section(sec1, sec6, 0.6, flap_length=0.1, control_name="Aileron");
    sec5 = btw_section(sec1, sec6, 0.9);
    
    plane.wing = assemble_surface([sec0, sec1, sec2, sec3, sec4, sec5, sec6]);

% ELEVATOR DEFENITION
    sec0 = new_section(3.234, 13.622, 0.328, tc=0.04, offset=[0 0 -0.2]);
    sec2 = new_section(1.55, 1.55 + 2 + 13.622, 0.328+3.26190, tc=0.03);
    
    % Flap
    sec1 = btw_section(sec0, sec2, 0.1, flap_length=1, control_name="Elevator"); % Full Flying
    
    plane.elevator = assemble_surface([sec0, sec1, sec2]);

% VTAIL DEFENITION
    sec0 = new_section(3.2, 12.5, 1, tc=0.04, dihedral=68.84, offset=[0 0.5 -0.6], twist=-2);
    sec3 = new_section(1.02, 1.5 + 1.5 + 12.162, 0.5+3.212, tc=0.03, dihedral=68.84, twist=-2);
    
    % Flap
    sec1 = btw_section(sec0, sec3, 0.1, flap_length=0.15, control_name="Rudder"); % vtail
    sec2 = btw_section(sec0, sec3, 0.9);
    
    plane.rudder = assemble_surface([sec0, sec1, sec2, sec3]);

plane.type = json_entry("Raymer Aircraft Type", "Jet fighter", "s"); % for coefficent lookups
plane.weights.raymer.A = json_entry("Raymer A Coeff", getRaymerCoefficents(plane.type.v, 1), "");
plane.weights.raymer.C = json_entry("Raymer C Coeff", getRaymerCoefficents(plane.type.v, 2), "");

plane.prop.num_engine = json_entry("Number of Engines", 2, "");
plane.prop.engine = json_entry("Engine Name", "F414", "s");

plane.racks = [-1 -0.7 -0.6 -0.5 -0.2 0 0.2 0.5 0.6 0.7 1]; % spanwise position of the racks
% plane.stores = []; % clean confiuration

plane = setLoadout(plane, ["AIM-9X" "" "" "" "" "" "" "" "" "" "AIM-9X"]);

writeAircraftFile(plane);
    % Writes the actual file generally. This also means the location only needs to be changed in one place