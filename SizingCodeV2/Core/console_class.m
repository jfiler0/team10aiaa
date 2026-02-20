classdef console_class < handle
    properties
        settings
        geom
        cond

        model
        perf

        run
        
        mem
    end

    % TODO: Work on case sensitivity
    
    methods
        % INITIALIZATION
        function obj = console_class()
            obj.settings = readSettings();
            obj.run = true; % once this is set to false the program ends
            obj.mem = struct();
        end

        function obj = start(obj, commandList)
            % commandList allows starting the console with a predfiend set of user inputs. This makes it easier to test
            if nargin > 1
                obj.mem.commandList = commandList;
            end

            jprint("=== Sizing V2 :: AVD Team 10 ===", 2)
            jprint("    Program structure is similar to XFOIL. Use ? to ask for the active set of commands at each level. Some commands switch level/operation. For example, you start in the LOAD function. Here, you can perform operations to load, save, edit, and read aircraft files. A layer deeper is INSPECT which is the start of the analyisis layer. It will have its own list of functions discoverable using ?", 0, true, true)
            jprint("    There are some rules to know. When entering inputs, spaces act as delimeters. You enter: 'command arg1 arg2 arg3' (for however many arguments it asks). Avoid special characters. q allows you to exit.", 0, true, true)
            jprint("    Finally, note that the console gui is more limited than actual scripting. This is a good place to analyze existing geometries and do rough plotting. However, you can create your own scripts to interact with the program. This is only the front end.", 0, true, true)
            jprint("List available commands with: '?'", 1)
            obj.load_loop;
        end

        function [userInput, args] = getInput(obj, header)
        % thanks chat again
            % TODO: Can have way to read ""s so that user can enter values with spaces
        
            jprint("[" + header + "] << ", -2, false);
        
            if( isempty(obj.mem.commandList) )
                raw = input('', 's');
            else
                % There are still so more commands we want to run
                raw = obj.mem.commandList(1);
                jprint(raw);
                obj.mem.commandList(1) = [];
            end
        
            % Convert to string and trim whitespace and make it al LOWERCASE
            raw = lower( strtrim(string(raw)) );
        
            % Handle empty input
            if strlength(raw) == 0
                userInput = "";
                args = string.empty;
                return
            end
        
            % Split on one-or-more whitespace
            parts = split(raw);
        
            userInput = parts(1);
        
            if numel(parts) > 1
                args = parts(2:end);
            else
                args = string.empty;
            end
        end

        %% MAIN LOOPS

        function obj = load_loop(obj)
            while obj.run
                [userInput, args] = obj.getInput("load");

                switch  userInput
                    case '?'
                        commands = [...
                            "?" "List available commands"; ...
                            "q" "Quit program"; ...
                            "listAircraft" "Print out all viable aircraft files which can be loaded"; ...
                            "load name" "Load an aircraft geometry by file name (exclude .json extension)"; ...
                            "edit param value" "Change aircraft geometry. Must be a struct path like: wing.span (must be a primary variable). See available with 'geomInfo'. 'value' argument is optional."; ...
                            "geomInfo" "Creates a table of properties associated with loaded geometry"; ...
                            "save name" "Creates a new aircraft file with the given name. If 'name' argument for provided, it uses the current file name." ; ...
                            "startAVL" "Creates an AVL session with the current geometry loaded as a .AVL file"
                            "INSPECT" "Enter command set for analyzing a geometry at point conditions" ; ...
                            "EDITLOADOUT" "Enter a command set for changing the current loadout with a set of predefined stores." ...
                            ];

                        printCommands( commands );
                    case 'q'
                        jprint("Exiting...", 1)
                        obj.run = false;
                    % These are critical ^^. Start of actual functions:

                    case 'listaircraft'
                        fileList = dir(fullfile("Aircraft Files/", '*.json'));
                        names = string({fileList.name}); % so we can use printArray. Otherwise it is a character array
                        names = erase(names, ".json"); % to keep it clean
                        printArray( names );

                    case 'load'
                        obj.geom = loadAircraft(args(1));
                        % loadout is now initially saved
                        % TODO: Since loadouts don't follow the same format, they are breaking lots of stuff
                        jprint("Working geometry set using " + obj.geom.id.v + ".json: " + obj.geom.name.v)

                    case 'edit'
                        structPath = args(1);
                        structChain = strsplit(structPath, '.');

                        does_exist = verifyNestedStruct(obj.geom, structChain, true);

                        if does_exist
                            % check if it is a derived variable
                            if readNestedField(obj.geom, structChain, 'd')
                                jprint("The given parmeter is derived: '" + structPath + "'. Select a primary parameter.", -1)
                            else
                                % ask for the value
                                current_value = readNestedField(obj.geom, structChain); % defaults to 'v'
                                if isempty(args(2)) % see if the user gave a value in the second argument
                                    % if not, ask
                                    [value, ~] = obj.getInput(structPath + " = "); % this is a string
                                else
                                    % if they did, set it
                                    value = args(2);
                                end

                                % Need to convert value type to same types as current_value
                                value = matchType(value, current_value);

                                obj.geom = editGeom(obj.geom, structPath, value, true);
                            end
                        else
                            jprint("The given parmeter does not exist: '" + structPath+"'", -1)
                        end

                    case 'geominfo'
                        T = geomInfoTable(obj.geom);
                        printTableConsole( sortrows(T) );

                    case 'save'
                        if isempty(args) % check if an argyments were passed in. If not:
                            name = obj.geom.id.v; % use the current name
                            jprint("No name entered. Saving as current file: '" + name+"'")
                        else
                            % otherwise we can just use the provided argument
                            name = args(1);
                        end

                        % matlab provides a helpful function to make sure no weird file names are used
                        name = matlab.lang.makeValidName( string(name), 'ReplacementStyle', 'delete');

                        % identify where it would go to check for overwrites
                        fullPath = mfilename('fullpath');
                        codeFolder = fileparts(fullPath);
                        savePath = fullfile(codeFolder, "../Aircraft Files", name+".json");

                        do_write = true;
                        if isfile(savePath) % if this already exists, make sure the user actually wants to overwrite it
                            jprint("This file already exists. Overwrite it? [Y/N]", -1)
                            [userInput, ~] = obj.getInput("replace");
                            % Any input not Y will lead to it continuing without writing
                            if( strcmp(userInput, 'Y') )
                                do_write = true;
                            else
                                jprint("save operation cancelled", -1)
                            end
                        end
                        if do_write
                            obj.geom = editGeom(obj.geom, "id", name);
                            writeAircraftFile(obj.geom);
                            jprint("Wrote current geometry to: " + savePath);
                        end
                    case 'startavl'
                        generatePlane(obj.geom);
                        start_avl;
                    case 'editloadout'
                        if isempty(obj.geom)
                            jprint("Must load an aircraft first.", -1)
                        else
                            obj.editloadout_loop;
                        end

                    case 'inspect'
                        if isempty(obj.geom)
                            jprint("Must load an aircraft first.", -1)
                        else
                            obj.inspect_loop;
                        end

                    case 'fun'
                        obj.run = false;
                        do_fun();

                    % Catch all
                    otherwise
                        notRecognized;
                end
            end
        end

        function obj = editloadout_loop(obj)
            while obj.run
                [userInput, args] = obj.getInput("edit_loadout");

                switch  userInput
                    case '?'
                        commands = [...
                            "?" "List available commands"; ...
                            "q" "Quit program"; ...
                            "listStores" "Print out all viable stores that can be loaded"; ...
                            "loadoutInfo" "Show the current stores loaded on the aicraft"
                            "rackInfo" "Display rack positions (y/span)"
                            "editRack rackNum newPos" "Change the rack position for a given index. Position is normalized by wing span."
                            "setRack rackNum storeName" "Set a store to a given rack number. Leave no storeName to set it as empty. If rack number does not exist, it is created."
                            "removeRack rackNum" "Deletes the rack and the "
                            "LOAD" "Return to command set for loading a geoemtry "
                            ];

                        printCommands( commands );
                    case 'q'
                        jprint("Exiting...", 1)
                        obj.run = false;
                    % These are critical ^^. Start of actual functions:

                    case 'liststores'
                        jprint("Not implemented.", -1);
                    case 'loadoutinfo'
                        jprint("Not implemented.", -1);
                    case 'rackinfo'
                        jprint("Not implemented.", -1);
                    case 'editrack'
                        jprint("Not implemented.", -1);
                    case 'setrack'
                        jprint("Not implemented.", -1);
                    case 'removerack'
                        jprint("Not implemented.", -1);
                    case 'load'
                        obj.load_loop;

                    % Catch all
                    otherwise
                        notRecognized;
                end
            end
        end

        function obj = inspect_loop(obj)
            while obj.run
                [userInput, args] = obj.getInput("inspect");

                switch  userInput
                    case '?'
                        commands = [...
                            "?" "List available commands"; ...
                            "q" "Quit program"; ...
                            "setCond" "Set a condition to run analyisis at"; ...
                            "printData" "Runs avaiable models and performance functions and prints table of outputs"; ...
                            "printComps" "Uses Raymer estimations to predict weight for a bunch of different system components" ; ...
                            "printCostBreakdown" "Prints the tables from xanderscript.m"
                            "LOAD" "Return to command set for loading a geoemtry "; ...
                            "GRAPHING" "Enter command set for creating different default graphs"; ...
                            "MISSIONS" "Enter command set for running mission files"; ...
                            "STABILITY" "Enter command set for evaluating design stability"; ...
                            ];

                        printCommands( commands );
                    case 'q'
                        jprint("Exiting...", 1)
                        obj.run = false;
                    
                        % These are critical ^^. Start of actual functions:

                    case 'setcond'
                        % h, M_vel, n, W, throttle
                        % H, MV, N, W, T
                        
                        jprint("Cycling through five condition inputs. Enter new value or leave blank to skip");
                        jprint("Couple key things to remember. The MV input can either be mach number of velocity. If the value is above 5, it is treated as velocity. The weight input cutoff is 1. If 1, it is set to MTOW. If 0, empty weight. If above 1, it hard sets the current weight to the value in N. Finally, throttle scales without afterburner up to 0.9 (max military power). 0.9-1 sets the afterburner throttle. 1 is full afterburner. 0.95 is 50% afterburner.", 0, true, true)

                        H = str2double( obj.getInput("H (alt, m)") );
                        MV  = str2double( obj.getInput("MV (mach number or velocity, m/s)") );
                        N = str2double( obj.getInput("N (load factor)") );
                        W = str2double( obj.getInput("W (normalized or in N)") );
                        T = str2double( obj.getInput("T (throttle)") );

                        if( isempty(obj.cond) && anynan([H MV N W T]))
                            % No condition object is defined and not all the inputs were provided
                            jprint("All condition elements must be provided for the first condition defenition", -1)
                        else
    
                            if isnan(H) ; H = obj.cond.h.v; end
                            if isnan(MV) ; MV = obj.cond.vel.v; end
                            if isnan(N) ; N = obj.cond.n.v; end
                            if isnan(W) ; W = obj.cond.W.v; end
                            if isnan(T) ; T = obj.cond.throttle.v; end
    
                            obj.cond = generateCondition(obj.geom, H, MV, N, W, T);

                            T = geomInfoTable(obj.cond);

                            printTableConsole(T)
                        end

                    case 'printdata'
                        if isempty(obj.cond)
                            jprint("Cannot run analyisis until a point condition is specified using 'setCond'.", -1)
                        else
                            if(isempty(obj.model) || isempty(obj.perf))
                                obj.model = model_class(obj.settings, obj.geom, obj.cond);
                                obj.perf = performance_class(obj.model);
                            end

                            obj.model.clear_mem();

                            % since they don't seem to update
                            obj.model.cond = obj.cond;
                            obj.model.geom = obj.geom;
                            % obj.perf.model = obj.model; - for some reason this isn't needed lol

                            sigfigs = 5;

                            data = { ...
                                "CD0", "Parasite Drag Coefficent", obj.model.CD0, "" ; ...
                                "CDi", "Induced Drag Coefficent", obj.model.CDi, "" ; ...
                                "CDw", "Wave Drag Coefficent", obj.model.CDw, "" ; ...
                                "CDp", "Drag Coefficent from stores", obj.model.CDp, "" ; ...
                                "CD", "Total Drag Coefficent", obj.perf.CD, "" ; ...
                                "CLa", "Lift slope", obj.model.CLa, "" ; ...
                                "CL", "Lift Coefficent", obj.cond.CL.v, "" ; ...
                                "LD", "Lift Over Drag Ratio", obj.perf.LD, "" ; ...
                                "D", "Drag", obj.perf.Drag / 1000, "kN" ; ...
                                "L", "Lift", obj.perf.Lift / 1000, "kN" ; ...
                                "TA", "Thrust Available", obj.perf.TA / 1000, "kN" ; ...
                                "TSFC", "Thrust Specific Fuel Conumption", obj.perf.TSFC, "sec" ; ...
                                "alpha", "Thrust Lapse", obj.perf.alpha, "" ; ...
                                "mdotf", "Fuel Flow Rate", obj.perf.mdotf, "kg/s" ; ...
                                "TE", "Excess Thrust", obj.perf.ExcessThrust / 1000, "kN" ; ...
                                "PE", "Excess Power", obj.perf.ExcessPower, "m/s" ; ...
                                "phi_dot", "Turn Rate", obj.perf.TurnRate, "deg/s" ; ...
                                "phi_dot", "Level Turn Rate", obj.perf.LevelTurnRate, "deg/s" ; ...
                                "theta", "Climb Angle (no axial accelleration)", obj.perf.ClimbAngle, "deg" ; ...
                                "C", "Unit Cost", obj.model.COST, "million" ; ...
                                "Sp", "Spot Factor (relative to F18)", obj.model.SpotFactor, "" };

                            % probably a way to vectorizes this. I dont care anymore
                            for i = 1:height(data)
                                data{i,3} = round(data{i,3}, sigfigs, 'significant');
                            end

                            T = cell2table(data, 'VariableNames', {'Parameter', 'Name', 'Value', 'Unit'});

                            printTableConsole(T);                            
                        end
                    case 'printcomps'
                        sigfigs = 5;
                        
                        weight_comps = getRaymerWeightStruct(obj.geom);
                        Field_Name = fieldnames(weight_comps);
                        Weight = round( struct2array(weight_comps)' , 5, 'significant' );
                        Units = repmat("N", length(Weight), 1);
                        T = table(Field_Name, Weight, Units);
                        printTableConsole(T);
                    case 'printcostbreakdown'
                        if obj.settings.COST_model ~= obj.settings.codes.COST_XANDERSCRIPT
                            jprint("Currently only possible with XANDER_SCRIPT model");
                        else
                            xanderscript_modified(obj.geom, true, false);
                        end
                    case 'load'
                        obj.load_loop;

                    case 'graphing'
                        obj.graphing_loop;

                    case 'missions'
                        jprint("Not implemented yet.", -1)

                    case 'stability'
                        jprint("Not implemented yet.", -1)

                    % Catch all
                    otherwise
                        notRecognized;
                end
            end
        end

        function obj = graphing_loop(obj)
            while obj.run
                [userInput, args] = obj.getInput("graphing");

                switch  userInput
                    case '?'
                        commands = [...
                            "?" "List available commands"; ...
                            "q" "Quit program"; ...
                            "costBreakdown" "Creates a set of figures as an overview of cost. From xanderscript."; ...
                            "geomView" "Opens a figure with the loaded outlines for the fuselage, wing, elevator, and vtail"
                            "LOAD" "Return to command set for loading a geoemtry"; ...
                            "INSPECT" "Return to command set for analyzing a geometry at point conditionsy"; ...
                            ];

                        printCommands( commands );
                    case 'q'
                        jprint("Exiting...", 1)
                        obj.run = false;
                    
                        % These are critical ^^. Start of actual functions:

                    case 'costbreakdown'
                        if obj.settings.COST_model ~= obj.settings.codes.COST_XANDERSCRIPT
                            jprint("Currently only possible with XANDER_SCRIPT model");
                        else
                            xanderscript_modified(obj.geom, false, true);
                        end
                    case 'geomview'
                        displayAircraftGeom(obj.geom);
                    case 'load'
                        obj.load_loop;

                    case 'inspect'
                        obj.inspect_loop;

                    % Catch all
                    otherwise
                        notRecognized;
                end
            end
        end
    end
end

function printArray(array)
    % Prints out an array of strings
    for i = 1:length(array)
        jprint(array(i))
    end
end

function printCommands(commands)
    jprint("Available commands:", 2)
% thanks chat
    % commands must be an Nx2 string array:
    % [ commandName   description ]

    if isempty(commands)
        jprint("No commands available.", -1);
        return
    end

    % Optional: compute padding for alignment
    cmdWidth = max(strlength(commands(:,1)));

    for i = 1:size(commands,1)

        cmd = commands(i,1);
        desc = commands(i,2);

        % Pad command for clean column alignment
        padding = repmat(' ', 1, cmdWidth - strlength(cmd));
        formattedCmd = cmd + padding + "  :  ";

        % Print command name (header type 1) without newline
        jprint(formattedCmd, 1, false);

        % Print description (standard) with newline
        jprint(desc, 0);
    end
end

function notRecognized()
    % Seperate this out as it is a common statement. This way it can be easily edited
    jprint("Not a recognized command. Use '?' for display available commands", -1)
end

function jprint(text, code, do_return, do_wrap)
    % code defines what level of print to do
    %   0 -> standard white print out
    %   1 -> subheader
    %   2 -> primary header
    %   -1 -> warning
    %   -2 -> Input line coloring

    % do_return is defaulted to true. If set to false you can do multiple colors in a line
    % do_wrap is disabled by defaut (how matlab normally is. Otherwise it uses the wraptext function
    
    % TODO: Add alternate color format for dark mode

    if nargin < 2
        code = 0;
    end
    if nargin < 3
        do_return = true;
    end
    if nargin < 4
        do_wrap = false;
    end

    % Since the new cprint uses %s, we need to manually do this through some basic recurison by splitting by the \n delimiter and recalling
    % for each line
    if do_wrap
        text = wraptext( char(text) );
        text_arr = split(text, '\n'); 
        for i = 1:length(text_arr)
            jprint(text_arr{i}, code, true, false)
        end
    else
        append = "";
    
        if do_return
            append = append + "\n";
        end
    
        switch code
            case 0
                fprintf("%s" + append, text);
            case 1
                cprintf('*cyan', "%s" + append, text)
            case 2
                cprintf('_*#45FF69', "%s" + append, text)
            case -1
                cprintf('#FCA835', "%s" + append, text)
            case -2
                cprintf('*#FF3BEF', "%s" + append, text)
            otherwise
                error("Unrecognized jprint code: %i", code)
        end
    end
end

% some real gpt
function printTableConsole(T)

    if isempty(T) || width(T) == 0
        jprint("Empty table.", 0);
        return
    end

    % Convert entire table to string array
    Tstr = varfun(@string, T);
    headers = string(T.Properties.VariableNames);

    nRows = height(Tstr);
    nCols = width(Tstr);

    % Preallocate matrix of strings (including header row)
    data = strings(nRows + 1, nCols);

    % First row = headers
    data(1,:) = headers;

    % Remaining rows = table content
    for c = 1:nCols
        data(2:end,c) = Tstr.(c);
    end

    % Determine column widths
    colWidths = zeros(1, nCols);
    for c = 1:nCols
        colWidths(c) = max(strlength(data(:,c)));
    end

    % ---- Print Header ----
    printRow(data(1,:), colWidths);

    % ---- Print Separator ----
    sepLine = "";
    for c = 1:nCols
        sepLine = sepLine + "|" + repmat('-',1,colWidths(c)+2);
    end
    sepLine = sepLine + "|";
    jprint(sepLine, 0);

    % ---- Print Data Rows ----
    for r = 2:size(data,1)
        printRow(data(r,:), colWidths);
    end

end

function printRow(rowData, colWidths)

    line = "";

    for c = 1:numel(rowData)

        cellText = rowData(c);

        padding = repmat(' ', 1, colWidths(c) - strlength(cellText));

        line = line + "| " + cellText + padding + " ";
    end

    line = line + "|";

    jprint(line, 0);

end

function T = geomInfoTable(geom)

    rows = {};
    rows = collectEntries(geom, "", rows);

    if isempty(rows)
        T = table;
        return
    end

    rows = vertcat(rows{:});
    T = struct2table(rows);

end

function rows = collectEntries(s, parentPath, rows)

    paths_to_ignore = ["racks" "stores"]; % These do not follow json_entry and need their own things

    if ~isstruct(s)
        return
    end

    fields = fieldnames(s);

    for i = 1:numel(fields)

        fname = fields{i};

        if strlength(parentPath) > 0
            currentPath = parentPath + "." + fname;
        else
            currentPath = string(fname);
        end

        value = s.(fname);

        % We are not about to go down a struct that is not in json_entry format
        if( ~any(contains(paths_to_ignore, string(fname))) )

            % ---- Leaf detection ----
            if isstruct(value) && isfield(value, "v") && isfield(value, "n")
    
                entry = struct();
                entry.Name  = string(value.n);
                entry.Value = string(value.v);          % allow mixed types
                entry.Units = string(value.u);
                entry.Path  = string(currentPath);
                entry.Derived = string(value.d);
    
                rows{end+1} = entry; %#ok<AGROW>
    
            elseif isstruct(value)
    
                rows = collectEntries(value, currentPath, rows);
    
            end
        end
    end
end

function converted_val = matchType(value_in, value_to_match)
    % thanks claude
    % Note the type of value_to_match and convert value_in to match it (as converted_val)

    % Convert value type to match current_value's type
    
    if isnumeric(value_to_match)
        % Convert to double
        converted_val = str2double(value_in);
        if isnan(converted_val)
            jprint("Invalid numeric input. Reverting to previous value.", -1)
            converted_val = value_to_match;
        end
    elseif islogical(value_to_match)
        % Convert to boolean
        value_lower = lower(strtrim(value_in));
        if ismember(value_lower, {'true', '1', 'yes', 't', 'y'})
            converted_val = true;
        elseif ismember(value_lower, {'false', '0', 'no', 'f', 'n'})
            converted_val = false;
        else
            jprint("Invalid boolean input.  Reverting to previous value.", -1)
            converted_val = value_to_match;
        end
    elseif ischar(value_to_match) || isstring(value_to_match)
        % Keep as string (already correct type)
        converted_val = char(value_in); % Ensure it's char if original was char
    else
        jprint("Unknown data type for parameter to set.  Reverting to previous value.", -1)
        converted_val = value_to_match;
    end
end