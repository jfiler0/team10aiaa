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
plane.fuselage.max_area = json_entry("Fuselage Max Area", 2.5, "m2");
plane.fuselage.E_WD = json_entry("Fuselage Wave Drag Efficency", 2.2, "");

plane.input.g_limit = json_entry("Structural G-Limit", 7.5, "");
plane.input.kloc = json_entry("KLOC", 5000, "");

plane.weights.mtow = json_entry("Max Takeoff Weight", lb2N(59488), "N");
plane.weights.w_fixed = json_entry("Fixed Weight", lb2N(2000), "N");

plane.wing.span = json_entry("Wing Span", 12.05, "m");
plane.wing.le_sweep = json_entry("Wing Leading Edge Sweep", 29.3, "deg");
plane.wing.root_chord = json_entry("Wing Root Chord", 5.07, "m");
plane.wing.tip_chord = json_entry("Wing Tip Chord", 1.686, "m");
plane.wing.fold_ratio = json_entry("Wing Fold Ratio", 0.333, "");
plane.wing.dihedral = json_entry("Dihedral", -2, "deg");
plane.wing.le_x = json_entry("Wing Leading Edge X Position", 8, "m");

plane.type = json_entry("Raymer Aircraft Type", "Jet fighter", "s"); % for coefficent lookups
plane.weights.raymer.A = json_entry("Raymer A Coeff", getRaymerCoefficents(plane.type.v, 1), "");
plane.weights.raymer.C = json_entry("Raymer C Coeff", getRaymerCoefficents(plane.type.v, 2), "");

plane.prop.num_engine = json_entry("Number of Engines", 2, "");
plane.prop.engine = json_entry("Engine Name", "F414", "s");

plane.racks = [-1 -0.7 -0.5 -0.2 0.2 0.5 0.7 1]; % spanwise position of the racks
% plane.stores = []; % clean confiuration

writeAircraftFile(plane);
    % Writes the actual file generally. This also means the location only needs to be changed in one place