% This file is the main one to use when writing to concept_tabulations. It embeds all the rfp asks and assumptions we make. 
% Controls

    % Chose Your Concept
    CN = 1; % COLUMN NUMBER
        % 1 -> F18E
        % 2 -> F35  
        % 3 -> Concept 1
        % 4 -> Concept 2
        % 4 -> Concept 3
        % 4 -> Concept 4
        % 4 -> Concept 5

    performance_plots = false; % Aerodynamics, Propulsion, Atmospere, Performance grids
    mission_plots = false; % Fuel burn, LD, TSFC over time
    geometry_plot = false; % Outline of the wing geometry

    run_sizing = false; % WARNING: This will overwrite xlsx data and can take awhile

    skip_max_ranges = false; % This can take a bit of time so if you are exploring other parameters consider just disabling it

    write_to_xlsx = true; % Toggle actual writing to the excel file (for debugging)

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

    fixed_input_superclean = fixed_input; % Making another set of corrections for the mach mach condition (when you scrub down the plane and make it super sleek to set a record)

    fixed_input_superclean.SWET_Scalar = 2; % Set this to 1 for totally clean, max speed (bring to 243/152 for real performance)
    fixed_input_superclean.CDW_Scalar = 7/4; % Set this to 1 for totally clean, max speed (bring to 7/4 for real performance)
    fixed_input_superclean.K1_Scalar = 1;

%% Define Loadouts
    % When applied to a plane they set extra payload weight, can add to potential fuel volume (if a tank), and add to CD0
    clean_loadout = buildLoadout(["AIM-9X", "AIM-9X"]);
    strike_loadout = buildLoadout(["AIM-9X", "FPU-12", "AIM-120", "AIM-120", "FPU-12", "AIM-9X"]);
%% Define missions
    ferry_700 = mission( [...
        flightSegment2("TAKEOFF") 
        flightSegment2("CLIMB", 0.7) 
        flightSegment2("CRUISE", NaN, NaN, nm2m(700))
        flightSegment2("LOITER", NaN, 10000, 10) % 10 min loiter
        flightSegment2("CRUISE", NaN, NaN, nm2m(700))
        flightSegment2("LANDING") ] , ...
        ...
        clean_loadout);

    air2air_700 = mission( [...
        flightSegment2("TAKEOFF") 
        flightSegment2("CLIMB", 0.7) 
        flightSegment2("CRUISE", NaN, NaN, nm2m(700))
        flightSegment2("LOITER", NaN, 10000, 20) % 20 min loiter
        flightSegment2("COMBAT", 0.8, 1000, [8 0.5]) % 8 minutes of combat, deploy 50% of payload
        flightSegment2("CRUISE", NaN, NaN, nm2m(700))
        flightSegment2("LANDING") ] , ...
        ...
        clean_loadout);
    
    % 5 cruise segments * 10 divisions * 93 function calls * 50 max internal function calls
    
    air2ground_700 = mission( [...
        flightSegment2("TAKEOFF") 
        flightSegment2("CLIMB", 0.85) % Check this mach
        flightSegment2("CRUISE", NaN, NaN, nm2m(700)) % 700 nm flight
        flightSegment2("LANDING") % Saying this is decent
        flightSegment2("LOITER", NaN, ft2m(10000), 10) % 10 min loiter
        flightSegment2("CLIMB", 0.85) % Check this mach
        flightSegment2("CRUISE", 0.85, NaN, nm2m(50)) % Penetrate
        flightSegment2("COMBAT", 0.85, 1000, [30/60 0]) % quick combat ***
        flightSegment2("CLIMB", 0.85) % Check this mach
        flightSegment2("CRUISE", NaN, NaN, nm2m(700)) % 700 nm flight
        flightSegment2("LOITER", NaN, ft2m(10000), 20) % 20 min loiter
        flightSegment2("LANDING") ] , ...
        ...
        strike_loadout);

%% Read in Excel File
    disp("Reading Input Geoemtry...")
    [currentFolder, ~, ~] = fileparts(mfilename('fullpath'));
    excelPath = fullfile(currentFolder, "concepts_tabulations.xlsx");
    T = readcell(excelPath);

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

    fold_ratio = readVar('Fold Ratio', CN, T);

%% Make the plane object
    disp("Building plane object...")
    %                                     empty_weight,       Lambda_LE,     c_r,       c_t,    span,        num_engine,      engine,      W_F
    plane = planeObj(fixed_input, name, geom.empty_weight, geom.Lambda_LE, geom.c_r, geom.c_t, geom.span,  geom.num_engine, geom.engine, geom.W_F);
    plane = plane.applyLoadout(clean_loadout); % Just two sidewinders


%% Size The Plane (Optional)
    if run_sizing
        disp("Running Sizing...")
        error("Sizing function not implemented yet");
    end

%% Display Plane Geometry
    % Build 3D plot to show wing geometry and fuselage size
    if geometry_plot
        disp("Working On Geometry Plot...")
        error("Geometry plot not implemented yet");
    end

%% Create Performance Plots
    if performance_plots
        disp("Working On Performance Plots...")
        plane.buildPlots(plane.MTOW, 30); % Can increase 50 for more resoultion at a time penalty
    end
    
%% Assign Derived Aircraft Geometry
    disp("Writing Derived Geometry...")

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

%% Compute Performance Data
    disp("Computing Performance Data...")

    T = assignVar(plane.calcUnitCost(), 'Unit Cost [millions]', CN, T);
    T = assignVar(plane.calcSpotFactor(fold_ratio), 'Spot Factor', CN, T);

    T = assignVar(plane.calcProp(0, 0, 0)/1000, 'Max Military Thrust [kN]', CN, T);
    T = assignVar(plane.calcProp(0, 0, 1)/1000, 'Max AB Thrust [kN]', CN, T);

    plane.fixed_input = fixed_input_superclean; % For mach mach calculation
    plane = plane.updateDerivedVariables();

    max_mach = plane.calcMaxMach(plane.WE, 1);
    T = assignVar(max_mach, 'Max Mach Number', CN, T);

    T = assignVar(ms2kt(plane.calcLandingSpeed(0, plane.MTOW)), 'Landing Speed [kt]', CN, T);

    plane.fixed_input = fixed_input; % Back to normal
    plane = plane.updateDerivedVariables();

    [maxAlt, ~, ~] = plane.calcMaxAlt(plane.MTOW, 1); % at MTOW?
    T = assignVar(m2ft(maxAlt)/1000, 'Service Ceiling [kft]', CN, T);

    [climbRate, ~, ~] = plane.calcMaxClimbRate(0, plane.MTOW, 1);
    T = assignVar(climbRate, 'Max Climb Rate [m/s]', CN, T);

    % Should be an actual maximum search
    [turn_rate, ~] = plane.getMaxTurn(0, 0.5, plane.MTOW); % M = 0.5, h = 0
    T = assignVar(turn_rate, 'Max Turn Rate [deg/s]', CN, T);

    [range_m, ~] = plane.findTotalMaxRange(plane.MTOW, 20);
    T = assignVar(m2nm(range_m), 'Maximum Range [nm]', CN, T);

    [time_s, ~] = plane.findTotalMaxEndurance(plane.MTOW, 20);
    T = assignVar(time_s/60, 'Maximum Endurance [min]', CN, T);

    T = assignVar(plane.MTOW / plane.S_wing, 'Max Wing Loading [N/m2]', CN, T);
    T = assignVar(plane.calcProp(0, 0, 1) / plane.MTOW, 'Min Thrust Loading', CN, T);

    [~, ~, ~, LDmax] = plane.findMaxEnduranceState(plane.MTOW);
    T = assignVar(LDmax, 'Max L/D', CN, T);

%% Work on Missions

disp("Computing mission fuel reserves...")

[~, ~, ~, fuel_remaining] = air2air_700.solveMission(plane, mission_plots); % *** Make actual air2air mission
T = assignVar(N2lb(fuel_remaining), '700nm Combat Mission Fuel Remaining [lb]', CN, T);

[~, ~, ~, fuel_remaining] = air2ground_700.solveMission(plane, mission_plots);
T = assignVar(N2lb(fuel_remaining), '700nm Strike Mission Fuel Remaining [lb]', CN, T);

disp("Computing maximum mission ranges...")

if ~skip_max_ranges

    startRange = 10; %nm
    
    max_air2air_range = fzero(@(R) W0_diff( plane, returnAir2AirMission( R, clean_loadout ) ) , startRange ); % *** need to correct air2air loadout
    max_air2ground_range = fzero(@(R) W0_diff( plane, returnAir2GroundMission( R, strike_loadout ) ) , startRange );
    max_ferry_range = fzero(@(R) W0_diff( plane, returnFerryMission( R, clean_loadout ) ) , startRange );
    
    T = assignVar(max_air2air_range, 'Combat Mission Max Range [nm]', CN, T);
    T = assignVar(max_air2ground_range, 'Strike Mission Max Range [nm]', CN, T);
    T = assignVar(max_ferry_range, 'Ferry Mission Max Range [nm]', CN, T);

end

function ferry_mission = returnFerryMission(range, loadout)
    ferry_mission = mission( [...
        flightSegment2("TAKEOFF") 
        flightSegment2("CLIMB", 0.7) 
        flightSegment2("CRUISE", NaN, NaN, nm2m(range))
        flightSegment2("LOITER", NaN, 10000, 10) % 10 min loiter
        flightSegment2("CRUISE", NaN, NaN, nm2m(range))
        flightSegment2("LANDING") ] , ...
        ...
        loadout);
end
function air2air_mission = returnAir2AirMission(range, loadout)
    air2air_mission = mission( [...
        flightSegment2("TAKEOFF") 
        flightSegment2("CLIMB", 0.7) 
        flightSegment2("CRUISE", NaN, NaN, nm2m(range))
        flightSegment2("LOITER", NaN, 10000, 20) % 20 min loiter
        flightSegment2("COMBAT", 0.8, 1000, [8 0.5]) % 8 minutes of combat, deploy 50% of payload
        flightSegment2("CRUISE", NaN, NaN, nm2m(range))
        flightSegment2("LANDING") ] , ...
        ...
        loadout);
end
function air2ground_mission = returnAir2GroundMission(range, loadout)
    air2ground_mission = mission( [...
        flightSegment2("TAKEOFF") 
        flightSegment2("CLIMB", 0.85) % Check this mach
        flightSegment2("CRUISE", 0.85, ft2m(30000), nm2m(range)) % 700 nm flight
        flightSegment2("LANDING") % Saying this is decent
        flightSegment2("LOITER", NaN, ft2m(10000), 10) % 10 min loiter
        flightSegment2("CLIMB", 0.85) % Check this mach
        flightSegment2("CRUISE", 0.85, NaN, nm2m(50)) % Penetrate
        flightSegment2("COMBAT", 0.85, 1000, [30/60 0]) % quick combat ***
        flightSegment2("CLIMB", 0.85) % Check this mach
        flightSegment2("CRUISE", 0.85, ft2m(30000), nm2m(range)) % 700 nm flight
        flightSegment2("LOITER", NaN, ft2m(10000), 20) % 20 min loiter
        flightSegment2("LANDING") ] , ...
        ...
        loadout);
end


%% Evaluate Constraints

disp("Computing rfp requirements...")

[g_vec, g_names] = constraints_rfp(plane, [air2air_700 air2ground_700]);

for i = 1:length(g_names)
     T = assignVar(g_vec(i), g_names(i), CN, T);
end


%% Write to Excel

if write_to_xlsx
    disp("Writing to excel file at " + excelPath)

    % Need to eliminate weird <missing> objects to sav
    missingMask = cellfun(@(x) isa(x, 'missing'), T);
    T(missingMask)= {""};
    
    % Using writetable instead of writecell preserves xlsx formatting
    T = cell2table(T);
    writetable(T, excelPath,'WriteVariableNames',false);

end

%% Wrap Up
disp("Done.")

%% Function for Interacting With Excel File

%*** Should add more checks to these so it doesn't immediately break
function value = readVar(varName, CN, T)
    % Run through the first column to look for variable matching varName and read out number in CN
    varIndex = find(strcmp({T{:, 1}}, varName)); % Find the index of the variable in the first column
    if isempty(varIndex)
        error('Variable %s not found in the table.', varName); % Error if variable not found
    end
    value = T{varIndex, CN + 1}; % Retrieve the value from the specified column
    
    valueNum = str2double(value); % Convert to double if it can be converted
    if(~isnan(valueNum))
        value = valueNum;
    end
end
function T = assignVar(value, varName, CN, T)
    % Run through the first column to look for variable matching varName and read out number in CN
    varIndex = find(strcmp({T{:, 1}}, varName)); % Find the index of the variable in the first column
    if isempty(varIndex)
        error('Variable %s not found in the table.', varName); % Error if variable not found
    end
    T{varIndex, CN + 1} = value; % Retrieve the value from the specified column
end