% See AVL User Primer for more information

clear; clc; close all;
% The first 5 non comment, not blank lines must contain:
% Title
% Mach Number
% iYsym iZsym Zsym
% Sref Cref Brefe
% Xref Yref Zref
% CDp (optional)

file_name = 'test.avl';

fullPath = mfilename('fullpath');
codeFolder = fileparts(fullPath);
file_path = fullfile(codeFolder, file_name);

global fileID;
fileID = fopen(file_path, 'w'); % Open file for writing

%% Defining Parameters
aircraft_name = "Test Aircraft";
mach = 0.5;

iYsym = 0; 
    % 1 -> symmetric about XZ - solid wall. -1 -> antisymmetric, XZ is const Cp. 0 -> no y-symmetry assumed
iZsym = 0; 
Zsym = 0;
    % 1 -> symetric about XY - solid wlal. -1 -> antisymmetric, XY is const Cp. 0 -> no z-symmetry assumed
Sref = 1; % Reference area used for all coefficents
Cref = 1; % Reference chord for pitching moments
Bref = 1; % Reference span for rol, yaw moments
Xref = 0; Yref = 0; Zref = 1;
    % For moments/rotation rates, for trimming this should be CG
CDp = 0.02; % Default profile drag coefficent applied at XYZref

%% START OF THE FILE

com("Aircraft Name:")
add(aircraft_name); 
blank()
data_arr(mach, "Mach")
data_arr([iYsym iZsym Zsym], ["iYsym", "iZsym", "Zsym"], [1 1 0])
data_arr([Sref Cref Bref], ["Sref", "Cref", "Bref"])
data_arr([Xref Yref Zref], ["Xref", "Yref", "Zref"])
data_arr(CDp, "CDp")
divider()

%% Lets Make Some Surfaces

surf1 = default_surf("CustomSurf");

surf1.NOWAKE = 1;

flap = build_control("flap", 0.1, [0 1 0], 1);

sec1 = build_sec([0 0 0], 1, "0012", flap);
sec2 = build_sec([0 1 0], 1, "0012");

surf1.sections = [sec1 sec2]; 

%% Write the Surface
blank()
write_surface(surf1);

%% END OF THE FILE

fclose(fileID); % Close file

% Base add of a string
function add(string)
    global fileID;
    fprintf( fileID, string + "\n");
end

% Add a string with comment start
function com(string)
    global fileID;
    fprintf( fileID, "# " + string + "\n");
end

% Adds a blank line
function blank()
    global fileID;
    fprintf( fileID, "\n");
end

% To keep things divided
function divider()
    global fileID;
    fprintf( fileID, "\n#--------------------------------------------------\n");
end

% Prints out the array of data along with their names with good padding and formatting
function data_arr(data, names, is_int)
    global fileID;
    num_cols = length(data);
    
    % If is_int is not provided, treat all as floats (0)
    if nargin < 3
        is_int = zeros(1, num_cols);
    end
    
    % Apply formatter with flags
    data_strs = strings(1, num_cols);
    for i = 1:num_cols
        data_strs(i) = fmt_val(data(i), is_int(i));
    end
    
    % Inject comment prefix into first header
    names(1) = "# " + names(1);
    
    % Calculate widths
    col_widths = zeros(1, num_cols);
    for i = 1:num_cols
        col_widths(i) = max(strlength(names(i)), strlength(data_strs(i)));
    end
    
    % Build and print lines
    header_line = "";
    data_line = "";
    for i = 1:num_cols
        header_line = header_line + pad(names(i), col_widths(i), 'right') + "  ";
        data_line   = data_line   + pad(data_strs(i), col_widths(i), 'right') + "  ";
    end
    
    fprintf(fileID, strtrim(header_line) + "\n" + strtrim(data_line) + "\n");
end

function data_code(data, code, is_int)
    global fileID;
    fprintf(fileID, string(code) + "\n");
    
    num_cols = length(data);
    if nargin < 3; is_int = zeros(1, num_cols); end
    
    data_strs = strings(1, num_cols);
    for i = 1:num_cols
        data_strs(i) = fmt_val(data(i), is_int(i));
    end
    
    fprintf(fileID, join(data_strs, "  ") + "\n");
end

function s = fmt_val(val, as_int)
    % Default to float if as_int is not provided
    if nargin < 2; as_int = false; end
    
    if as_int
        % Format as a simple integer string
        s = sprintf('%d', round(val));
    else
        % Existing logic for floats
        if (abs(val) > 0 && abs(val) < 0.01) || abs(val) >= 100
            s = sprintf('%.7E', val);
        else
            s = sprintf('%.7f', val);
        end
        
        % Clean up trailing zeros but keep .0
        if contains(s, '.')
            s = regexprep(s, '0+$', '');
            if endsWith(s, '.')
                s = s + "0";
            end
        end
        
        % Clean scientific notation
        if contains(s, 'E')
            s = regexprep(s, '0+E', 'E');
            s = strrep(s, '.E', '.0E');
        end
    end
    s = string(s);
end

function surf = default_surf(name)
    % Generates a blank components with optional fields prefilled
    surf = struct();
    surf.name = name;

    % curently from b737
    surf.Nchordwise = 12; % number of chordwise horseshoe vortices placed on the surface
    surf.Cspace = 1; % chordwise vortex spacing parameter
    surf.Nspanwise = 26; %  number of spanwise horseshoe vorticesplaced on the surface [optional]
    surf.Sspace = -1.1; %  spanwise vortex spacing parameter [optional]

    surf.COMPONENT = 0; % multiple surfaces with the same component ID will be grouped
    surf.YDUPLICATE = 0; % shorthand device for creating another surface which is a geometric mirror image of the one being defined
        % for simulation geometric symmetry without aerodynamic symmetry
    
    % SCALE - for easy rescaling of the surface about its own coordinates
    surf.Xscale = 1;
    surf.Yscale = 1;
    surf.Zscale = 1;

    % TRANSLATE - to move the given component points
    surf.dX = 0;
    surf.dY = 0;
    surf.dZ = 0;

    surf.ANGLE = 0; % Change incidence angle of the entire surface

    surf.NOWAKE = 0; % Another nearby aircraft, with both aircraft maneuvering together. This would be for trim calculation in formation flight.
        % Kutta not enforced. No lift but will have moment
    surf.NOALBE = 0; % surface is unaffected by freestream direction changes
        % surfaces such as a ground plane, wind tunnel walls
    surf.NOLOAD = 0; % Do not add forces/moments to reported totals
        % Typically used with NOALBE to remove groundplane/etc from forces
    
    surf.sections = []; % need to add them
end

function sec = build_sec(LE_coords, Chord, NACA, control)
    sec = struct();
    sec.Xle = LE_coords(1);
    sec.Yle = LE_coords(2);
    sec.Zle = LE_coords(3);

    sec.Chord = Chord;

    sec.Ainc = 0;
    sec.Nspanwise = 0; % disabled if 0
    sec.Sspace = 0; % disabled if 0

    % sec.NACA = NACA; % lots of ways of gettings foil - this to be simple for now

    if nargin < 4
        control = 0;
    end

    sec.control = control; % if 0, it is disabled. Otherwise it is a control struct
end

function cont = build_control(name, Xhinge, XYZhvec, SgnDup)

    cont.name = name; % this groups controls by name
    cont.gain = 1; % default
    cont.Xhinge = Xhinge;
        % x/c location of hinge.
        % If positive, control surface extent is Xhinge..1 (TE surface)
        % If negative, control surface extent is 0..-Xhinge (LE surface)
    cont.XYZhvec = XYZhvec;
        % vector giving hinge axis about which surface rotates
        % + deflection is + rotation about hinge vector by righthand
        % rule
        % Specifying XYZhvec = 0. 0. 0. puts the hinge vector along
        % the hinge
    cont.SgnDup = SgnDup;
        % sign of deflection for duplicated surface
        % An elevator would have SgnDup = +1
        % An aileron would have SgnDup =-1
end

function write_surface(surf)
    add("SURFACE")
    add(surf.name)
    blank()
    
    data_arr([surf.Nchordwise, surf.Cspace, surf.Nspanwise, surf.Sspace], ["Nchordwise", "Cspace", "Nspanwise", "Sspace"], [1, 0 1, 0])

    data_code(surf.COMPONENT, "COMPONENT", 1);
    data_code(surf.YDUPLICATE, "YDUPLICATE");
    data_code([surf.Xscale, surf.Yscale, surf.Zscale], "SCALE");
    data_code([surf.dX, surf.dY, surf.dZ], "TRANSLATE");
    data_code(surf.ANGLE, "ANGLE");

    if(surf.NOWAKE == 1)
        add("NOWAKE");
    end
    if(surf.NOALBE == 1)
        add("NOALBE");
    end
    if(surf.NOLOAD == 1)
        add("NOLOAD");
    end

    for i = 1:numel(surf.sections)
        write_section(surf.sections(i));
    end
end

function write_section(sec)
    add("SECTION");

    vals = [sec.Xle, sec.Yle, sec.Zle, sec.Chord, sec.Ainc];
    names = ["Xle", "Yle", "Zle", "Chord", "Ainc"];

    if(sec.Nspanwise > 0)
        vals = [vals sec.Nspanwise]; names = [names "Nspanwise"];
    end
    if(sec.Sspace > 0)
        vals = [vals sec.Sspace]; names = [names "Sspace"];
    end
    data_arr(vals, names)

    % blank()
    % add("NACA")
    % add(sec.NACA)

    blank()

    if isstruct(sec.control)
        add("CONTROL")
        add(sprintf("%s  %.3f  %.3f  %.3f  %.3f  %.3f %.1f", sec.control.name, sec.control.gain, sec.control.Xhinge, sec.control.XYZhvec(1), sec.control.XYZhvec(2), sec.control.XYZhvec(3), sec.control.SgnDup ))
    end

    blank()
end