%% build_f18_template
% - Goal: For testing, we need an aircraft file. This also provides an example file to reference for future aircraft analyisis. While you
% can build a file like this for each, the XML can be easily edited.
% - The specific assignments for each of these construct names is important. If any are missing, things will almost certainty break. You can
% add new things. It is also critical to keep plane files consistent with the same naming conventions.

clear;

set = struct();

set.program_name = "Sizing Code V2.1";

% settings for the transonic merge function (First value MUST be less than 1 and second MUST be greater than 1)
set.transonic_range = [0.95 1.3];
set.transonic_M_eps = 0.01;

set.CD0_scaler = 1; % general scaler to parasite drag
set.CDi_scaler = 1;
set.CDw_scaler = 1; % general scaler to wave drag

set.codes = build_default_codes();

set.CD0_model = set.codes.CD0_BASIC;
set.CDi_model = set.codes.CDi_BASIC_SUBSONIC;
set.CDw_model = set.codes.CDw_BASIC;

% *** Lots of room to expand capability.
% The great thing about a general settings constructor is that it will update everywhere and be available without passing around a new
% variable


fullPath = mfilename('fullpath');
codeFolder = fileparts(fullPath);
    % Identify the current script path
saveFile = fullfile(codeFolder, "../..","settings.json");
    % Use relative paths to assign the settings location. If this is ever changed, readSettings.m must also be corrected

jsonText = jsonencode(set, 'PrettyPrint', true);
    % Generate the string to write

% Write JSON text to a file
fileID = fopen(saveFile, 'w');
fwrite(fileID, jsonText, 'char');
fclose(fileID);