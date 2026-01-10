%% build_f18_template
% - Goal: For testing, we need an aircraft file. This also provides an example file to reference for future aircraft analyisis. While you
% can build a file like this for each, the XML can be easily edited.
% - The specific assignments for each of these construct names is important. If any are missing, things will almost certainty break. You can
% add new things. It is also critical to keep plane files consistent with the same naming conventions.

clear;

plane = struct();

plane.id = "f18_superhornet";

% plane.fuselage.length = 17.54;
plane.fuselage.length = json_entry("Fuselage Length", 17.54, false, "m");
plane.fuselage.max_area = json_entry("Fuselage Max Area", 2.5, false, "m2");
plane.fuselage.E_WD = json_entry("Fuselage Wave Drag Efficency", 2.2, false, "");

plane.input.g_limit = json_entry("Structural G-Limit", 7.5, false, "");
plane.input.kloc = json_entry("KLOC", 5000, false, "");

plane.weights.mtow = json_entry("Max Takeoff Weight", lb2N(59488), false, "N");
plane.weights.w_fixed = json_entry("Fixed Weight", lb2N(2000), false, "N");

plane.wing.span = json_entry("Wing Span", 12.05, false, "m");
plane.wing.le_sweep = json_entry("Wing Leading Edge Sweep", 29.3, false, "deg");
plane.wing.root_chord = json_entry("Wing Root Chord", 5.07, false, "m");
plane.wing.tip_chord = json_entry("Wing Tip Chord", 1.686, false, "m");
plane.wing.fold_ratio = json_entry("Wing Fold Ratio", 0.333, false, "");

plane.type = json_entry("Raymer Aircraft Type", "Jet fighter", false, "s"); % for coefficent lookups

plane.prop.num_engine = json_entry("Number of Engines", 2, false, "");
plane.prop.engine = json_entry("Engine Name", "F414", false, "s");

writeAircraftFile(plane);