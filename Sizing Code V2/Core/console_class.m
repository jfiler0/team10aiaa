classdef console_class
    properties
        settings
        geom
        cond
        
        mem
    end
    
    methods
        % INITIALIZATION
        function obj = console_class()
            obj.settings = readSettings();
        end

        function obj = start(obj)
            jprint("=== Sizing V2 :: AVD Team 10 ===", 2)
            jprint("List available commands with: '?'", 1)
            jprint("Enter aircraft file name to load:")
            jprint("Not a recognized file. Use 'listAircraft' to get viable file names.", -1)
        end

        
    end
end

function jprint(text, code)
    % code defines what level of print to do
    %   0 -> standard white print out
    %   1 -> subheader
    %   2 -> primary header
    %   -1 -> warning

    % TODO: Add alternate color format for dark mode

    if nargin < 2
        code = 0;
    end

    switch code 
        case 0
            disp(text);
        case 1
            cprintf('*cyan', text + "\n")
        case 2
            cprintf('_*#45FF69', text + "\n")
        case -1
            cprintf('#FCA835', text + "\n")
        otherwise
            error("Unrecognized jprint code: %i", code)
    end
end