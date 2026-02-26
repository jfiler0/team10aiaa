%% build_f18_template
% - Goal: For testing, we need an aircraft file. This also provides an example file to reference for future aircraft analyisis. While you
% can build a file like this for each, the XML can be easily edited.
% - The specific assignments for each of these construct names is important. If any are missing, things will almost certainty break. You can
% add new things. It is also critical to keep plane files consistent with the same naming conventions.

% These strings are pretty self explanatory in what they assign. Read json_entry for more info on each field

clear; % Start fresh

plane = struct();

plane.name = json_entry("Aircraft Name", "Kevin CAD: Hellstringer", "s");
plane.id = json_entry("Aircraft ID", "kevin_cad", "s");

plane.fuselage.length = json_entry("Fuselage Length", in2m(600), "m");
plane.fuselage.max_area = json_entry("Fuselage Max Area", in2m(in2m(4650)), "m2");
plane.fuselage.E_WD = json_entry("Fuselage Wave Drag Efficency", 2.2, "");

plane.input.g_limit = json_entry("Structural G-Limit", 7.5, "");
plane.input.kloc = json_entry("KLOC", 5000, "");
% plane.input.fold_ratio = json_entry("Fold Ratio", 0.3, "");

plane.weights.mtow = json_entry("Max Takeoff Weight", lb2N(79081), "N");
plane.weights.w_fixed = json_entry("Fixed Weight", lb2N(2000), "N");

plane.wing.span = json_entry("Wing Span", in2m(426.5), "m");
plane.wing.le_sweep = json_entry("Wing Leading Edge Sweep", 25, "deg");
plane.wing.root_chord = json_entry("Wing Root Chord", in2m(174.1), "m");
plane.wing.tip_chord = json_entry("Wing Tip Chord", 0.14 * in2m(174.1), "m");
plane.wing.fold_ratio = json_entry("Wing Fold Ratio", 0.333, "");
plane.wing.dihedral = json_entry("Wing Dihedral", -1.8, "deg");
plane.wing.le_x = json_entry("Wing Leading Edge X Position", 0.45 * plane.fuselage.length.v, "m");

plane.wing.controls.flap_width = json_entry("Main Wing Flap Width (normalized to span)", 0.3, "");
plane.wing.controls.flap_length = json_entry("Main Wing Flap Length (normalized to local chod)", 0.2, "");
plane.wing.controls.aileron_width = json_entry("Main Wing Aileron Width (normalized to span)", 0.3, "");
plane.wing.controls.aileron_length = json_entry("Main Wing Aileron Length (normalized to local chord)", 0.1, "");

plane.wing.strake.norm_length = json_entry("Strake Length (normalized to root chord)", 0.200 * plane.fuselage.length.v / in2m(174.1), "");
plane.wing.strake.norm_span = json_entry("Strake Span (normalized to main wing span)", in2m(105) / plane.wing.span.v, "");

plane.elevator.root_chord = json_entry("Elevator Root Chord", 0.17 * plane.fuselage.length.v, "m");
plane.elevator.tip_chord = json_entry("Elevator Tip Chord", 0.17 * plane.fuselage.length.v * 0.5544 , "m");
plane.elevator.semi_span = json_entry("Elevator Semispan", in2m(82.22), "m");
plane.elevator.dihedral = json_entry("Elevator Dihedral", 0, "deg");
plane.elevator.elevator_length = json_entry("Elevator Control Surface Length (normalized to local chord)", 0.15, "");

plane.vtail.root_chord = json_entry("V-Tail Root Chord", in2m(79.02), "m");
plane.vtail.tip_chord = json_entry("V-Tail Tip Chord", in2m(98.62) * 0.4705, "m");
plane.vtail.semi_span = json_entry("V-Tail Semispan", in2m(44.5), "m");
plane.vtail.dihedral = json_entry("V-Tail Dihedral", 65, "deg");
plane.vtail.rudder_length = json_entry("Rudder Length (normalized to local chord)", 0.15, "");

plane.type = json_entry("Raymer Aircraft Type", "Jet fighter", "s"); % for coefficent lookups
plane.weights.raymer.A = json_entry("Raymer A Coeff", getRaymerCoefficents(plane.type.v, 1), "");
plane.weights.raymer.C = json_entry("Raymer C Coeff", getRaymerCoefficents(plane.type.v, 2), "");

plane.prop.num_engine = json_entry("Number of Engines", 2, "");
plane.prop.engine = json_entry("Engine Name", "F110", "s");

plane.racks = [-1 -0.7 -0.5 -0.2 0.2 0.5 0.7 1]; % spanwise position of the racks
% plane.stores = []; % clean confiuration

plane = setLoadout(plane, ["AIM-9X" "" "" "" "" "" "" "AIM-9X"]);

writeAircraftFile(plane);
    % Writes the actual file generally. This also means the location only needs to be changed in one place