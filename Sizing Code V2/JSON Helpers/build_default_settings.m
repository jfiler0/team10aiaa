%% build_f18_template
% - Goal: For testing, we need an aircraft file. This also provides an example file to reference for future aircraft analyisis. While you
% can build a file like this for each, the XML can be easily edited.
% - The specific assignments for each of these construct names is important. If any are missing, things will almost certainty break. You can
% add new things. It is also critical to keep plane files consistent with the same naming conventions.

clear;

set = struct();

set.program_name = "Sizing Code V2.1";

% settings for the transonic merge function
set.transonic_range = [0.95 1.3];
set.transonic_M_eps = 0.01;

set.CD0_scaler = 1; % general scaler to parasite drag
set.CDW_scaler = 1; % general scaler to wave drag

fullPath = mfilename('fullpath');
codeFolder = fileparts(fullPath);
saveFile = fullfile(codeFolder, "..","settings.json");

jsonText = jsonencode(set, 'PrettyPrint', true);

% Write JSON text to a file
fileID = fopen(saveFile, 'w');
fwrite(fileID, jsonText, 'char');
fclose(fileID);