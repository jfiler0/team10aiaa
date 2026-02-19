function struct = json_entry(name, value, units, geom, derived_override)
    % name = some string to call this entry. Can have spaces but avoid special characters. This is the selection for gui but not used
        % anywhere else in the actual analyisis
    % value = whatever the value is. Can be NaN or [] if it should not be assigned yet
    % is_derived = a boolean. If false, it is a primary variable that can be changed/optimized. If not, it is for calculation and export
    % units = HOW TO HANDLE
    % geom -> needed to evaluate derived parms. Does work if not passed in on primary calls

    if nargin < 4
        geom = NaN;
    end
    if nargin < 5
        % When true this forces the derived setting to true. Otherwise it defaults to the string check
        derived_override = false;
    end

    struct.n = name;
    struct.u = units;
    struct.c = []; 
    % placeholder for a list of connected structures inside geometry that must be updated if this variable is changed
    % bit of a danger for loops. Oh well. I am sure they won't become an issue

    % TODO: Generally this needs to not be called so often

    % check if the unit is 's' which designates a string input. This can only be a primary variable
    if struct.u == 's' || any( [ isa(value, 'double'), isa(value, 'int') ] ) % this is a primary var and can take value
        struct.d = derived_override; % Having derived_override is needed for the default condition struct
        struct.eval = 0;
        struct.v = value;
    elseif isa(value, 'string')
        if ~isstruct(geom)
            error('json_entry was called with no defined geom (not enough arguments)')
        end
        struct.d = true;
        struct.eval = value;
        struct.v = eval(value);
    else
        error("Invalid input variable type")
    end
end