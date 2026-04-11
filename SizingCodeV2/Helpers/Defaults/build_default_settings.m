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
set.transonic_M_eps = 0.005;

set.g_const = 9.8051; % gravitational consts
set.jeta_density = 0.82; % kg/L

set.be_imperial = true;

set.spot_factor_reference = 52.7559; % Folded wing area of an f18e

set.CD0_scaler = 1; % general scaler to parasite drag
set.CDi_scaler = 1;
set.CDw_scaler = 1.6309; % general scaler to wave drag
set.CLa_scaler = 1;
set.CDp_scaler = 0.3250;
set.SpotFactor_scaler = 1;

set.COST_scaler = 1;
set.TA_scaler = 1;
set.TSFC_scaler = 1.1703;

set.WE_scaler = 1; % scales all components and the final empty weight
set.WF_ratio =  0.4206; % WF = WF_ratio * (MTOW - WE) -> internal fuel weight

set.codes = build_default_codes();

set.WE_model = set.codes.WE_Roskam; % go back to set.codes.WE_Nicolai

set.CD0_model = set.codes.CD0_FRICTION; % CD0_BASIC CD0_FRICTION
set.CDi_model = set.codes.CDi_BASIC_SUBSONIC; % CDi_BASIC_SUBSONIC CDi_IDRAG
set.CDw_model = set.codes.CDw_BASIC;
set.CLa_model = set.codes.CLa_RAYMER;
set.COST_model = set.codes.COST_XANDERSCRIPT;
set.PROP_model = set.codes.PROP_HYBRID; % PROP_BASIC PROP_NPSS PROP_HOOK PROP_HYBRID
set.CDp_model = set.codes.CDp_CONST;
set.SpotFactor_model = set.codes.SpotFactor_BASIC;

set.CDp_CONST_CD = 0.15; % the drag coefficent used for each store in the CDp_CONST model

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