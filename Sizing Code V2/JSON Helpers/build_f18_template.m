%% build_f18_template
% - Goal: For testing, we need an aircraft file. This also provides an example file to reference for future aircraft analyisis. While you
% can build a file like this for each, the XML can be easily edited.
% - The specific assignments for each of these construct names is important. If any are missing, things will almost certainty break. You can
% add new things. It is also critical to keep plane files consistent with the same naming conventions.

clear;

plane = struct();

plane.id = "f18_superhornet";

plane.fuselage.length = 17.54;
plane.fuselage.max_area = 2.5;

plane.input.g_limit = 7.5;
plane.input.kloc = 5000;

plane.weights.mtow = lb2N(59488);
plane.weights.w_fixed = lb2N(2000);

plane.wing.span = 12.05;
plane.wing.le_sweep = 29.3;
plane.wing.root_chord = 5.07;
plane.wing.tip_chord = 1.686;
plane.wing.fold_ratio = 0.333;

plane.type = "Jet fighter"; % for coefficent lookups

writeAircraftFile(plane);