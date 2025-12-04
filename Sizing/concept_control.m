% This file is the main one to use when writing to concept_tabulations. It embeds all the rfp asks and assumptions we make. 

% MAKE SURE YOU COPY concepts_tabulations_template.xlsx inside the Sizing folder and name it concepts_tabulations.xlsx

% INSTRUCTIONS
% --- Go to concept_tabulatons.xlsx. See the geometry inputs in the "Geometry Inputs" section
% --- Select your concept below using the column number
% --- Enable/Disable operations below. For testing, you can set write_to_xlsx = false so no permeant operations occur
% --- Run the file (make sure you have added all files in team10aiaa to the working directory
% --- If excel writing is enabled, you can view performance outputs there. Or look at plots if you generated them
% *** You now have two options: Manual Sizing & Automatic Sizing

% Manual Sizing
% --- Edit the geometry inputs and run the file over and over till you are happy
% --- Can load sensitivities_plot to get an understanding of trends for each geometric variable

% Automatic Sizing
% --- Set run_sizing to true. It will try to find a feasible design. If excel writing is enabled, it will overwrite the geometry inputs with
% the new set. You can then start with manual sizing from there for any finetuning or adjustments

% Other Notes
% --- performance_plots has a lot of interesting info (~15s). sizing_plot gives a fully 2D view of the optimization problem but takes a bit
% --- skip_max_ranges will disable the max range search which is more resource intense than any of the other outputs

% Controls
    % Chose Your Concept
    CN = 1; % COLUMN NUMBER
        % 1 -> F18E
        % 2 -> F18E_Sized (for testing)
        % 3 -> F16
        % 4 -> F35  
        % 5 -> Concept 1
        % 6 -> Concept 2
        % 7 -> Concept 3
        % 8 -> Concept 4
        % 9 -> Concept 5
        % 10 -> Temp (can paste in values here to save them temporarily)

    performance_plots = false; % Aerodynamics, Propulsion, Atmospere, Performance grids
    mission_plots = false; % Fuel burn, LD, TSFC over time
    geometry_plot = false; % Outline of the wing geometry (not implemented yet)
    drag_polar = true;
    
    run_sizing = false; % WARNING: This will overwrite xlsx data (takes about ~15 seconds)
        sizing_plot = false; % Shows constraint boundaries (this does take a min. Only actually samples 15 x 15)
    sensitivities_plot = false; % Can change parameter selection in "Sensitivities Plot"

    skip_max_ranges = true; % This can take a bit of time so if you are exploring other parameters consider just disabling it

    write_to_xlsx = false; % Toggle actual writing to the excel file (for debugging)

%% Initlization Functions
    build_atmosphere_lookup(-5000, ft2m(120000), 500); % Refresh atmosphere lookup
    matlabSetup(); % Clears and sets plot defaults

%% Define Loadouts
    % When applied to a plane they set extra payload weight, can add to potential fuel volume (if a tank), and add to CD0
    clean_loadout = buildLoadout(["AIM-9X", "AIM-9X"]); % Just the sidewinders
    ferry_loadout = buildLoadout(["AIM-9X", "FPU-12", "FPU-12", "FPU-12", "AIM-9X"]); % Three tanks
    strike_loadout = buildLoadout(["AIM-9X", "FPU-12", "MK-83", "MK-83", "MK-83", "MK-83", "FPU-12", "AIM-9X"]); % 4 Mk83 bombs
    air2air_loadout = buildLoadout(["AIM-9X", "AIM-120", "AIM-120", "AIM-120", "FPU-12", "AIM-120", "AIM-120", "AIM-120", "AIM-9X"]); % 6 amraams
%% Define missions
    ferry_700 = mission( [...
        flightSegment2("TAKEOFF") 
        flightSegment2("CLIMB", 0.7) 
        flightSegment2("CRUISE", NaN, NaN, nm2m(700))
        flightSegment2("LOITER", NaN, 10000, 10) % 10 min loiter
        flightSegment2("CRUISE", NaN, NaN, nm2m(700))
        flightSegment2("LANDING") ] , ...
        ...
        ferry_loadout, "700nm Ferry");

    air2air_700 = mission( [...
        flightSegment2("TAKEOFF") 
        flightSegment2("CLIMB", 0.7) 
        flightSegment2("CRUISE", NaN, NaN, nm2m(700))
        flightSegment2("LOITER", NaN, 10000, 20) % 20 min loiter
        flightSegment2("COMBAT", 0.8, 1000, [8 0.5]) % 8 minutes of combat, deploy 50% of payload
        flightSegment2("CRUISE", NaN, NaN, nm2m(700))
        flightSegment2("LANDING") ] , ...
        ...
        air2air_loadout, "700nm Air 2 Air");
    
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
        strike_loadout, "700nm Strike");

    missionList = [air2ground_700 air2air_700]; % Missions to constraint

%% Read in Excel File
    disp("Reading Input Geoemtry...")
    [currentFolder, ~, ~] = fileparts(mfilename('fullpath'));
    excelPath = fullfile(currentFolder, "concepts_tabulations.xlsx");
    T = readcell(excelPath);

%% Trying a different way to read file cause broken? idk

% disp("Reading Input Geometry...")
% 
% thisFile = matlab.desktop.editor.getActiveFilename; % Pulls local file path
% [currentFolder, ~, ~] = fileparts(thisFile);
% 
% excelPath = fullfile(currentFolder, "concepts_tabulations.xlsx");
% T = readcell(excelPath);

%% Gather Inputs
    name = readVar('Deliverable', CN, T);

    disp("Loaded geometry for: " + name)
    
    fixed_input = struct();
    fixed_input.L_fuselage = readVar('Fuselage Length [m]', CN, T); % m
    fixed_input.A_max = readVar('Max Fuselage Area [m2]', CN, T); % m2 -> From VSP
    fixed_input.g_limit = readVar('G Limit', CN, T); % G -> FA18 limit
    fixed_input.KLOC = readVar('KLOC', CN, T); % in kilo-lines of code
    fixed_input.fold_ratio = readVar('Fold Ratio', CN, T);
    
    geom.empty_weight = lb2N(readVar('Empty Weight [lb]', CN, T)); % Gotta be Newtons m8. This drives MTOW using historical relations which eventually informs the amount of fuel which can be carried
    geom.W_F = lb2N(readVar('Fixed Weight [lb]', CN, T)); % N - Fixed Weight (Avionics)
    geom.span = readVar('Wing Span [m]', CN, T); % m - Wing Span
    geom.Lambda_LE = readVar('LE Sweep [deg]', CN, T); % deg - Leading Edge Sweep
    geom.c_r = readVar('Root Chord [m]', CN, T); % m - Root Chord
    geom.c_t = readVar('Tip Chord [m]', CN, T); % m - Tip Chordf
    geom.engine = readVar('Engine Selection', CN, T); % engine: A string code which you can see in engine_lookup.xslx. More info in engine_getData
    geom.num_engine = readVar('Number of Engines', CN, T);

    tail_input = struct();
    % tail_input.mac = readVar('MAC', CN, T);

%% Set Remaining Fixed Inputs
    % These should remain constant between concepts
    
    fixed_input.max_alpha = 10; % deg -> Guess (This defins max LANDING Cl) -> Too high for landing now!
    fixed_input.type = "Jet fighter"; % Which empty weight coefficents to take from Raymer. In weight_regression_lookup
    
    % Tuned to match F18 range requirements:
    % fixed_input.MTOW_Scalar = 66/50; % Since the Raymer fighter jet corrections is 16k lb lower than the F18
    fixed_input.MTOW_Scalar = 60/50;
    fixed_input.SWET_Scalar = 3; % Shifting SWET historical regression to match VSP (and scaled CD0 to correct LD)
    fixed_input.CDW_Scalar = 9/4; % Wave drag estimate is typically too low
    fixed_input.K1_Scalar = 1.3; % Scales induced drag (and thus reduces eosw)
    fixed_input.F_Scaler = 1.3; % Increases max possible lift (by scaling fuselage lift factor)

    fixed_input_superclean = fixed_input; % Making another set of corrections for the mach mach condition (when you scrub down the plane and make it super sleek to set a record)

    fixed_input_superclean.SWET_Scalar = 2; % Set this to 1 for totally clean, max speed (bring to 243/152 for real performance)
    fixed_input_superclean.CDW_Scalar = 7/4; % Set this to 1 for totally clean, max speed (bring to 7/4 for real performance)
    fixed_input_superclean.K1_Scalar = 1;

%% Make the plane object
    disp("Building plane object...")
    %                                     empty_weight,       Lambda_LE,     c_r,       c_t,    span,        num_engine,      engine,      W_F
    plane = planeObj(fixed_input, tail_input, name, geom.empty_weight, geom.Lambda_LE, geom.c_r, geom.c_t, geom.span,  geom.num_engine, geom.engine, geom.W_F);
    plane = plane.applyLoadout(clean_loadout); % Just two sidewinders

%% Size The Plane (Optional)
    if run_sizing
        disp("Running Sizing...")

        plane = sizeAircraft(plane, missionList, @constraints_rfp, sizing_plot, 1.5);
        plane = plane.updateDerivedVariables();

        T = assignVar(N2lb(plane.WE), 'Empty Weight [lb]', CN, T);
        T = assignVar(plane.span, 'Wing Span [m]', CN, T);
        T = assignVar(plane.c_r, 'Root Chord [m]', CN, T);
        T = assignVar(plane.c_t, 'Tip Chord [m]', CN, T);

        [g_vec, ~] = constraints_rfp(plane, missionList);
        if(max(g_vec) > 0)
            disp("\n")
            warning("Sized aircraft does not satisfy all RFP constraints and is instead the least feasible (weighted) option.")
        end

    end
%% Sensitivities Plot

    if(sensitivities_plot)
        disp("Working on sensitvities plot...")
        values_to_change = { ...
                           "WE", "Empty Weight [N]" ; ...
                           % "c_r", "Root Chord [m]" ; ...
                           % "c_t", "Tip Chord [m]" ; ...
                           "span", "Span [m]" ; ...
                           "Lambda_LE", "LE Sweep [deg]" ; ...
                           "L_fuselage", "Fuselage Length [m]" ; ...
                           "A_max", "Max Fuse Area [m2]" ; ...
                           % "span", "Span [m]" ; ...
                           % "span", "Span [m]" ; ...
                           % "span", "Span [m]" ; ...
                           };

        sensitivitesPlot(plane, values_to_change, 1.5, missionList, @constraints_rfp, 15);
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
        buildPerformancePlots(plane, plane.MTOW, 30); % Can increase 50 for more resoultion at a time penalty
    end

%% Drag Polar
    if drag_polar
        disp("Building drag polar...")
        dragPolarPlot(plane);
    end
    
%% Assign Derived Aircraft Geometry
    disp("Writing Derived Geometry...")

    T = assignVar(N2lb(plane.MTOW), 'MTOW [lb]', CN, T);
    
    plane = plane.applyLoadout(strike_loadout); % Should have the highest payload weight. Technically can reduce by moving to wing tanks
    internal_fuel = plane.max_fuel_weight;
    plane = plane.applyLoadout(clean_loadout);
    T = assignVar(N2lb(internal_fuel), 'Internal Fuel Weight [lb]', CN, T);
    
    T = assignVar(plane.AR, 'Aspect Ratio', CN, T);
    T = assignVar(plane.tr, 'Taper Ratio', CN, T);
    T = assignVar(plane.c_avg, 'Average Chord [m]', CN, T);
    T = assignVar(plane.Lambda_TE, 'TE Sweep [deg]', CN, T);
    T = assignVar(plane.S_wing, 'Wing Area [m2]', CN, T);
    % T = assignVar( m2ft(plane.span * plane.fixed_input.fold_ratio), 'Folded Span [ft]', CN, T);
    % T = assignVar(plane.x_MAC_verstab, 'X VTAIL MAC [m]', CN, T);


%% Compute Performance Data
    disp("Computing Performance Data...")

    T = assignVar(plane.calcUnitCost(), 'Unit Cost [millions]', CN, T);
    T = assignVar(plane.calcSpotFactor(), 'Spot Factor', CN, T);

    T = assignVar(plane.calcProp(0, 0, 0)/1000, 'Max Military Thrust [kN]', CN, T);
    T = assignVar(plane.calcProp(0, 0, 1)/1000, 'Max AB Thrust [kN]', CN, T);

    plane.fixed_input = fixed_input_superclean; % For max mach calculation
    plane = plane.updateDerivedVariables();

    max_mach = plane.calcMaxMach(plane.WE, 1);
    T = assignVar(max_mach, 'Max Mach Number', CN, T);

    % plane.calcMaxMachFixedAlt(ft2m(30000), plane.mid_mission_weight, 1, 1.1)

    plane.fixed_input = fixed_input; % Back to normal
    plane = plane.updateDerivedVariables();

    landing_weight = getLandingWeight(plane);
    landing_speed = plane.calcLandingSpeed(0, landing_weight); % m/s
    T = assignVar(ms2kt(landing_speed), 'Landing Speed [kt]', CN, T);

    [maxAlt, ~, ~] = plane.calcMaxAlt(plane.mid_mission_weight, 1);
    T = assignVar(m2ft(maxAlt)/1000, 'Service Ceiling [kft]', CN, T);

    [climbRate, ~, ~] = plane.calcMaxClimbRate(0, plane.mid_mission_weight, 1);
    T = assignVar(climbRate, 'Max Climb Rate [m/s]', CN, T);

    num_engine = plane.num_engine;
    plane.num_engine = 1;
    [~, a0, ~, ~, ~] = queryAtmosphere(0, [0 1 0 0 0]); % sea level speed of sound
    excess_landing = plane.calcExcessPower(0, landing_speed/a0, plane.MTOW, 1); % MTOW landing weight, full AB, coming in to land
    plane.num_engine = num_engine;

    T = assignVar(m2ft(excess_landing)*60, 'Landing SEROC [ft/min]', CN, T);

    % Should be an actual maximum search
    [turn_rate, ~] = plane.getMaxTurnAtAlt(0, plane.mid_mission_weight); % h = 0
    T = assignVar(turn_rate, 'Max Turn Rate [deg/s]', CN, T);

    [turn_rate, ~] = plane.getMaxSustainedTurnAtAlt(0, plane.mid_mission_weight, 1); % h = 0, full AB
    T = assignVar(turn_rate, 'Max Sustained Turn Rate [deg/s]', CN, T);

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

if ~skip_max_ranges

    disp("Computing maximum mission ranges...")

    startRange = 10; %nm
    
    progressbar('Max Mission Ranges')
    max_air2air_range = fzero(@(R) W0_diff( plane, returnAir2AirMission( R, air2air_loadout ) ) , startRange ); % *** need to correct air2air loadout
    progressbar(1/3);
    max_air2ground_range = fzero(@(R) W0_diff( plane, returnAir2GroundMission( R, strike_loadout ) ) , startRange );
    progressbar(2/3);
    max_ferry_range = fzero(@(R) W0_diff( plane, returnFerryMission( R, ferry_loadout ) ) , startRange );
    progressbar(1);
    
    T = assignVar(max_air2air_range, 'Combat Mission Max Radius [nm]', CN, T);
    T = assignVar(max_air2ground_range, 'Strike Mission Max Radius [nm]', CN, T);
    T = assignVar(max_ferry_range, 'Ferry Mission Max Radius [nm]', CN, T);
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
        loadout, "Ferry");
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
        loadout, "Air2Air");
end
function air2ground_mission = returnAir2GroundMission(range, loadout)
    air2ground_mission = mission( [...
        flightSegment2("TAKEOFF") 
        flightSegment2("CLIMB", 0.85) % Check this mach
        flightSegment2("CRUISE", 0.85, NaN, nm2m(range)) % 700 nm flight
        flightSegment2("LANDING") % Saying this is decent
        flightSegment2("LOITER", NaN, ft2m(10000), 10) % 10 min loiter
        flightSegment2("CLIMB", 0.85) % Check this mach
        flightSegment2("CRUISE", 0.85, NaN, nm2m(50)) % Penetrate
        flightSegment2("COMBAT", 0.85, 1000, [30/60 0]) % quick combat ***
        flightSegment2("CLIMB", 0.85) % Check this mach
        flightSegment2("CRUISE", NaN, NaN, nm2m(range)) % 700 nm flight
        flightSegment2("LOITER", NaN, ft2m(10000), 20) % 20 min loiter
        flightSegment2("LANDING") ] , ...
        ...
        loadout, "Air2Ground");
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