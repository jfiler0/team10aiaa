clear; % Start fresh

plane = struct();

plane.name = json_entry("Aircraft Name", "HellstingerV3", "s");
plane.id = json_entry("Aircraft ID", "hellstingerv3", "s");

plane.fuselage.length = json_entry("Fuselage Length", ft2m(50), "m");
plane.fuselage.max_area = json_entry("Fuselage Max Area", in2m(in2m(4650)), "m2");
plane.fuselage.E_WD = json_entry("Fuselage Wave Drag Efficency", 2.2, "");

plane.input.g_limit = json_entry("Structural G-Limit", 7.5, "");
plane.input.kloc = json_entry("KLOC", 5000, "");
plane.input.fold_ratio = json_entry("Fold Ratio", 0, ""); % there is no fold right now
plane.input.WF_ratio = json_entry("WF Ratio", 0.6119, "");  % WF = WF_ratio * (MTOW - WE) -> internal fuel weight

mtow = lb2N(68400);
plane.weights.mtow = json_entry("Max Takeoff Weight", mtow, "N");
plane.weights.w_fixed = json_entry("Fixed Weight", lb2N(2000), "N");

% MAIN WING DEFENITION - only the inboard side of the flap must be defined
    wing_root = 4.4;
    wing_span = 18.2;
    wing_tip = 0.6;
    sweep = 30; % to match mach angle
    
    lerx_root = wing_root*1.7;
    wing_le_x = 4;

    sec0 = new_section(lerx_root, wing_le_x, 0.8, tc=0.06);
    sec1 = new_section(wing_root, wing_le_x + lerx_root - wing_root, sec0.le_yp.v + 0.08 * wing_span, tc=0.04);
    sec6 = new_section(wing_tip, sec1.le_x.v + sind(sweep)*(wing_span/2 - sec1.le_y.v), wing_span/2, tc=0.02);
    
    % MAIN FLAP
    sec2 = btw_section(sec1, sec6, 0.1, flap_length=0.2, control_name="Main Flap");
    sec3 = btw_section(sec1, sec6, 0.5);
    
    % AILERON
    sec4 = btw_section(sec1, sec6, 0.6, flap_length=0.1, control_name="Aileron");
    sec5 = btw_section(sec1, sec6, 0.9);
    
    plane.wing = assemble_surface([sec0, sec1, sec2, sec3, sec4, sec5, sec6]);

% ELEVATOR DEFENITION
    root_chord = 0.17 * plane.fuselage.length.v;
    tip_chord = 0.17 * plane.fuselage.length.v * 0.5544;
    sec0 = new_section(root_chord, plane.fuselage.length.v - root_chord, 1, tc=0.04);
    sec2 = new_section(tip_chord, plane.fuselage.length.v - tip_chord, 1+in2m(82.22), tc=0.03);
    
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

plane = setLoadout(plane, ["" "" "" "" "" "" "" ""]);
writeAircraftFile(plane);
    % Writes the actual file generally. This also means the location only needs to be changed in one place