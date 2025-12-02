%% HEADER
% This file is the main one to use when writing to concept_tabulations. It embeds all the rfp asks and assumptions we make. 

%% Initlization Functions
    build_atmosphere_lookup(-5000, ft2m(120000), 500); % Refresh atmosphere lookup
    matlabSetup(); % Clears and sets plot defaults
%% Set Fixed Inputs
    % These should remain constant between concepts
    fixed_input = struct();
    
    fixed_input.max_alpha = 12; % deg -> Guess (This defins max LANDING Cl)
    fixed_input.type = "Jet fighter"; % Which empty weight coefficents to take from Raymer. In weight_regression_lookup
    
    % Tuned to match F18 range requirements:
    fixed_input.MTOW_Scalar = 66/50; % Since the Raymer fighter jet corrections is 16k lb lower than the F18
    fixed_input.SWET_Scalar = 3; % Shifting SWET historical regression to match VSP (and scaled CD0 to correct LD)
    fixed_input.CDW_Scalar = 10/4; % Wave drag estimate is typically too low
    fixed_input.K1_Scalar = 1.3; % Scales induced drag (and thus reduces eosw)

%% Define Loadouts
    % When applied to a plane they set extra payload weight, can add to potential fuel volume (if a tank), and add to CD0
    clean_loadout = buildLoadout(["AIM-9X", "AIM-9X"]);
    strike_loadout = buildLoadout(["AIM-9X", "FPU-12", "AIM-120", "AIM-120", "FPU-12", "AIM-9X"]);

%% Read in Excel File
[currentFolder, ~, ~] = fileparts(mfilename('fullpath'));
excelPath = fullfile(currentFolder, "concepts_tabulations.xlsx");
T = readcell(excelPath);

%% Chose Your Concept
CN = 1; % COLUMN NUMBER
    % 1 -> F18E
    % 2 -> F35
    % 3 -> Concept 1
    % 4 -> Concept 2
    % 4 -> Concept 3
    % 4 -> Concept 4
    % 4 -> Concept 5

%% Gather Inputs
name = readVar('Deliverable', CN, T);

fixed_input.L_fuselage = readVar('Fuselage Length [m]', CN, T); % m
fixed_input.A_max = readVar('Max Fuselage Area [m2]', CN, T); % m2 -> From VSP
fixed_input.g_limit = readVar('G Limit', CN, T); % G -> FA18 limit
fixed_input.KLOC = readVar('KLOC', CN, T); % in kilo-lines of code

geom.empty_weight = lb2N(readVar('Empty Weight [lb]', CN, T)); % Gotta be Newtons m8. This drives MTOW using historical relations which eventually informs the amount of fuel which can be carried
geom.W_F = lb2N(readVar('Fixed Weight [lb]', CN, T)); % N - Fixed Weight (Avionics)
geom.span = readVar('Wing Span [m]', CN, T); % m - Wing Span
geom.Lambda_LE = readVar('LE Sweep [deg]', CN, T); % deg - Leading Edge Sweep
geom.c_r = readVar('Root Chord [m]', CN, T); % m - Root Chord
geom.c_t = readVar('Tip Chord [m]', CN, T); % m - Tip Chordf
geom.engine = readVar('Engine Selection', CN, T); % engine: A string code which you can see in engine_lookup.xslx. More info in engine_getData
geom.num_engine = readVar('Number of Engines', CN, T);

%% Make the plane object
%                                     empty_weight,       Lambda_LE,     c_r,       c_t,    span,        num_engine,      engine,      W_F
plane = planeObj(fixed_input, name, geom.empty_weight, geom.Lambda_LE, geom.c_r, geom.c_t, geom.span,  geom.num_engine, geom.engine, geom.W_F);
plane = plane.applyLoadout(clean_loadout); % Just two sidewinders

%% Size The Plane (Optional)
    % (Not Implemented Yet)
%% Display Plane Geometry
    % Build 3D plot to show wing geometry and fuselage size
    % (Not Implemented Yet)

%% Assign Derived Aircraft Geometry

T = assignVar(N2lb(plane.MTOW), 'MTOW [lb]', CN, T);

plane = plane.applyLoadout(strike_loadout); % Should have the highest payload weight. Technically can reduce by moving to wing tanks
internal_fuel = plane.MTOW - plane.WE - plane.W_P - plane.W_Tanks - plane.W_F;
plane = plane.applyLoadout(clean_loadout);
T = assignVar(N2lb(internal_fuel), 'Internal Fuel Weight [lb]', CN, T);

T = assignVar(plane.AR, 'Aspect Ratio', CN, T);
T = assignVar(plane.tr, 'Taper Ratio', CN, T);
T = assignVar(plane.c_avg, 'Average Chord [m]', CN, T);
T = assignVar(plane.Lambda_TE, 'TE Sweep [deg]', CN, T);
T = assignVar(plane.S_wing, 'Wing Area [m2]', CN, T);

%% Write to Excel

% Need to eliminate weird <missing> objects to sav
missingMask = cellfun(@(x) isa(x, 'missing'), T);
T(missingMask)= {""};

% writecell(T,"test.xlsx");
% writecell(T,"test.xslx",'Sheet','MyNewSheet','WriteVariableNames',false);
% writecell(T, excelPath, 'Sheet', 'MySheet', 'WriteMode','replacefile'); % or 'overwrite'

% excel = actxserver('Excel.Application');
% workbook = excel.Workbooks.Open(excelPath);
% 
% sheet = workbook.Sheets.Item('Concepts');
% 
% % Write values cell by cell (preserves formatting of untouched cells)
% for r = 1:size(T,1)
%     for c = 1:size(T,2)
%         sheet.Cells(r,c).Value = T{r,c};
%     end
% end
% 
% workbook.Save;
% workbook.Close;
% excel.Quit;

T = cell2table(T);
writetable(T, excelPath,'WriteVariableNames',false);

%% Function for Interacting With Excel File

%*** Should add more checks to these so it doesn't immediately break
function value = readVar(varName, CN, T)
    % Run through the first column to look for variable matching varName and read out number in CN
    varIndex = find(strcmp({T{:, 1}}, varName)); % Find the index of the variable in the first column
    if isempty(varIndex)
        error('Variable %s not found in the table.', varName); % Error if variable not found
    end
    value = T{varIndex, CN + 1}; % Retrieve the value from the specified column
end
function T = assignVar(value, varName, CN, T)
    % Run through the first column to look for variable matching varName and read out number in CN
    varIndex = find(strcmp({T{:, 1}}, varName)); % Find the index of the variable in the first column
    if isempty(varIndex)
        error('Variable %s not found in the table.', varName); % Error if variable not found
    end
    T{varIndex, CN + 1} = value; % Retrieve the value from the specified column
end