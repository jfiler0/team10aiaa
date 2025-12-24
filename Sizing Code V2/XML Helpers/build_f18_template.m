% This builds a stuct to be saved as an XML of a F18. The inputs can be changed for a general aircraft.
clear;

plane = struct();

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

fullPath = mfilename('fullpath');
codeFolder = fileparts(fullPath);
saveFile = fullfile(codeFolder, "..","Aircraft Files", "f18_superhornet.xml");

writestruct(plane,saveFile);