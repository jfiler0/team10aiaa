classdef console_class < handle
    properties
        settings
        geom
        cond

        run
        
        mem
    end

    % TODO: Work on case sensitivity
    % TODO: Deal with empty input
    
    methods
        % INITIALIZATION
        function obj = console_class()
            obj.settings = readSettings();
            obj.run = true; % once this is set to false the program ends
        end

        function obj = start(obj)
            jprint("=== Sizing V2 :: AVD Team 10 ===", 2)
            jprint("List available commands with: '?'", 1)
            obj.load_loop;
        end

        function obj = load_loop(obj)
            while obj.run
                [userInput, args] = getInput("load");

                switch  userInput
                    case '?'
                        commands = [...
                            "?" "List available commands"; ...
                            "q" "Quit program"; ...
                            "listAircraft" "Print out all viable aircraft files which can be loaded"
                            "load [name]" "Load an aircraft geometry by file name (exclude .json extension)"
                            "INSPECT" "Enter command set for analyzing a geometry at point conditions"
                            ];

                        printCommands( commands );
                    case 'q'
                        jprint("Exiting...", 1)
                        obj.run = false;
                    % These are critical ^^. Start of actual functions:

                    case 'listAircraft'
                        fileList = dir(fullfile("Aircraft Files/", '*.json'));
                        names = string({fileList.name}); % so we can use printArray. Otherwise it is a character array
                        names = erase(names, ".json"); % to keep it clean
                        printArray( names );

                    case 'load'
                        obj.geom = readAircraftFile(args(1));
                        jprint("Working geometry set using " + obj.geom.id.v + ".json: " + obj.geom.name.v)

                    case 'INSPECT'
                        if isempty(obj.geom)
                            jprint("Must load an aircraft first.", -1)
                        else
                            obj.inspect_loop;
                        end

                    % Catch all
                    otherwise
                        notRecognized;
                end
            end
        end

        function obj = inspect_loop(obj)
            while obj.run
                [userInput, args] = getInput("inspect");

                switch  userInput
                    case '?'
                        commands = [...
                            "?" "List available commands"; ...
                            "q" "Quit program"; ...
                            "LOAD" "Return to command set for loading a geoemtry "
                            "geomInfo" "Creates a table of properties associated with loaded geometry"
                            "setCond" "Set a condition to run analyisis at"
                            ];

                        printCommands( commands );
                    case 'q'
                        jprint("Exiting...", 1)
                        obj.run = false;
                    % These are critical ^^. Start of actual functions:

                    case 'LOAD'
                        obj.load_loop;

                    case 'geomInfo'
                        jprint("Not implemented yet.", -1)

                    case 'setCond'
                        jprint("Not implemented yet.", -1)

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

function [userInput, args] = getInput(header)
% thanks chat again

    jprint("[" + header + "] << ", -2, false);

    raw = input('', 's');

    % Convert to string and trim whitespace
    raw = strtrim(string(raw));

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


function notRecognized()
    % Seperate this out as it is a common statement. This way it can be easily edited
    jprint("Not a recognized command. Use '?' for display available commands", -1)
end

function jprint(text, code, do_return)
    % code defines what level of print to do
    %   0 -> standard white print out
    %   1 -> subheader
    %   2 -> primary header
    %   -1 -> warning
    %   -2 -> Input line coloring

    % do_return is defaulted to true. If set to false you can do multiple colors in a line
    
    % TODO: Add alternate color format for dark mode

    if nargin < 2
        code = 0;
    end
    if nargin < 3
        do_return = true;
    end

    if do_return
        text = text + "\n";
    end

    switch code 
        case 0
            fprintf(text);
        case 1
            cprintf('*cyan', text)
        case 2
            cprintf('_*#45FF69', text)
        case -1
            cprintf('#FCA835', text)
        case -2
            cprintf('*#FF3BEF', text)
        otherwise
            error("Unrecognized jprint code: %i", code)
    end
end