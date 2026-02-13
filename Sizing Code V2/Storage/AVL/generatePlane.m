function generatePlane(geom)

% See AVL User Primer for more information

% The first 5 non comment, not blank lines must contain:
% Title
% Mach Number
% iYsym iZsym Zsym
% Sref Cref Brefe
% Xref Yref Zref
% CDp (optional)

file_name = 'aircraft.avl';

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

%% MAIN WING

surf1 = default_surf("MainWing");

span = geom.wing.span.v;

strake_norm_length = 0.7; % as a ratio of root chod
strake_norm_span = 0.2; % as a ratio of span

flap_width = 0.3; % as a ratio of span
flap_length = 0.2; % as a ratio of local chord

aileron_width = 0.3; % as a rtio of span
aileron_length = 0.1; % as a ratio of local chord

flap = build_control("flap", flap_length, [0 1 0], 1);
aileron = build_control("aileron", aileron_length, [0 1 0], -1);

semi_span = 0.5 * span;
rad = geom.fuselage.diameter.v/2; % fuselage radius

sec1 = build_sec([geom.wing.le_x.v rad 0], geom.wing.root_chord.v); % THIS IS GHOST
sec5 = build_sec([geom.wing.le_x.v + semi_span * sind(geom.wing.le_sweep.v), rad + semi_span semi_span * sind(geom.wing.dihedral.v)], geom.wing.tip_chord.v);

sec2 = betw_sec(sec1, sec5, strake_norm_span);
sec3 = betw_sec(sec1, sec5, strake_norm_span + flap_width);
sec4 = betw_sec(sec1, sec5, 1 - aileron_width);

strake_length = strake_norm_length * sec1.Chord;
sec1.Xle = sec1.Xle - strake_length;
sec1.Chord = sec1.Chord + strake_length;

sec2.control = flap;
sec4.control = aileron;

surf1.sections = [sec1 sec2 sec3 sec4 sec5]; 

write_surface(surf1);
divider()

%% ELEVATOR

elevator_root_chord = 2;
elevator_tip_chord = 1;
eleavtor_semispan = 1.5;
elevator_dihedral = -5;

elevator_length = 0.15; % as a ratio of local chord
aft_fuse_diam = geom.prop.diam.v * 2;

surf2 = default_surf("Elevator");
elevator = build_control("elevator", elevator_length, [0 1 0], 1);

elevator_le_pos = geom.fuselage.length.v - elevator_root_chord;

sec1 = build_sec([elevator_le_pos, aft_fuse_diam/2, 0], elevator_root_chord, elevator);
sec2 = build_sec([elevator_le_pos + eleavtor_semispan * sind(geom.wing.le_sweep.v), aft_fuse_diam/2 + eleavtor_semispan, eleavtor_semispan * sind(elevator_dihedral)], elevator_tip_chord);

surf2.sections = [sec1 sec2]; 

write_surface(surf2);
divider()

%% VTAIL

vtail_root_chord = 2;
vtail_tip_chord = 1;
vtail_semispan = 1.5;
elevator_dihedral = 60;

rudder_length = 0.15;
rudder_sweep = geom.wing.le_sweep.v;

surf3 = default_surf("VTail");
elevator = build_control("rudder", rudder_length, [0 1 0], 1);

vtail_le_pos = geom.fuselage.length.v - vtail_root_chord;

sec1 = build_sec([vtail_le_pos, cosd(elevator_dihedral)*aft_fuse_diam/2, sind(elevator_dihedral)*aft_fuse_diam/2], vtail_root_chord, elevator);
sec2 = build_sec([vtail_le_pos + vtail_semispan * sind(rudder_sweep), cosd(elevator_dihedral)*(aft_fuse_diam/2 + eleavtor_semispan), sind(elevator_dihedral)*(aft_fuse_diam/2 + eleavtor_semispan)], vtail_tip_chord);

surf3.sections = [sec1 sec2]; 

write_surface(surf3);
divider()

%% FUSELAGE

fuse_coords = [ ...
geom.fuselage.length.v, aft_fuse_diam/2
elevator_le_pos, aft_fuse_diam/2 ; 
geom.wing.le_x.v + geom.wing.root_chord.v, rad ; ...
geom.wing.le_x.v - strake_length, rad ; ...
0, 0 ];

fuse_coords = [ fuse_coords ; flip(fuse_coords(1:(end-1), 1)) , flip(-fuse_coords(1:(end-1), 2)) ];

Nbody = 15; 
Bspace = 1;

add("BODY")
data_code([Nbody Bspace], "Fuselage", [1 0])

data_code([0 0 0], "TRANSLATE")

dat_name = 'fuse.dat';

generate_dat( fullfile(codeFolder, dat_name), fuse_coords(:,1), fuse_coords(:, 2) );

add("BFIL")
add(dat_name)

%% END OF THE FILE

fclose(fileID); % Close file

end

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

function sec = betw_sec(sec1, sec2, ratio)
    % Returns a section with a LE position and chord. 0 is sec1, 1 is sec2
    LE_coords_1 = [sec1.Xle, sec1.Yle, sec1.Zle];
    LE_coords_2 = [sec2.Xle, sec2.Yle, sec2.Zle];

    Chord_1 = sec1.Chord;
    Chord_2 = sec2.Chord;

    LE_coords = LE_coords_1 + (LE_coords_2 - LE_coords_1) * ratio;
    Chord = Chord_1 + (Chord_2 - Chord_1) * ratio;

    sec = build_sec(LE_coords, Chord);
    
end

function sec = build_sec(LE_coords, Chord, control)
    sec = struct();
    sec.Xle = LE_coords(1);
    sec.Yle = LE_coords(2);
    sec.Zle = LE_coords(3);

    sec.Chord = Chord;

    sec.Ainc = 0;
    sec.Nspanwise = 0; % disabled if 0
    sec.Sspace = 0; % disabled if 0

    % sec.NACA = NACA; % lots of ways of gettings foil - this to be simple for now

    if nargin < 3
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

    if isstruct(sec.control)
        add("CONTROL")
        add(sprintf("%s  %.3f  %.3f  %.3f  %.3f  %.3f %.1f", sec.control.name, sec.control.gain, sec.control.Xhinge, sec.control.XYZhvec(1), sec.control.XYZhvec(2), sec.control.XYZhvec(3), sec.control.SgnDup ))
    end

    blank()
end

function generate_dat(file_path, x1, x2)
    fileID = fopen(file_path, 'w');
    
    % Format all values in both columns
    n = length(x1);
    strs1 = strings(n, 1);
    strs2 = strings(n, 1);
    
    for i = 1:n
        strs1(i) = fmt_val(x1(i), false);
        strs2(i) = fmt_val(x2(i), false);
    end
    
    % Find maximum width for both columns
    max_width1 = max(strlength(strs1));
    max_width2 = max(strlength(strs2));
    
    % Print each row with proper spacing
    for i = 1:n
        % Right-align both columns
        fprintf(fileID, '%s  %s\n', ...
            pad(strs1(i), max_width1, 'left'), ...
            pad(strs2(i), max_width2, 'left'));
    end
end