function struct = json_entry(name, value, is_derived, units)
    % name = some string to call this entry. Can have spaces but avoid special characters. This is the selection for gui
    % value = whatever the value is. Can be NaN or [] if it should not be assigned yet
    % is_derived = a boolean. If false, it is a primary variable that can be changed/optimized. If not, it is for calculation and export
    % units = HOW TO HANDLE

    struct.n = name;
    struct.v = value;
    struct.d = is_derived;
    struct.u = units;
end