function out = readNestedField(s, fields, property)
    % GOAL: Work through a s with a string array of field names to get the value

    % property -> the character to add on from json_entry 'n' -> name, 'u' -> units, 'd' -> boolean if derived

    % This is the most often called setting so this is standard
    if nargin < 3
        property = "v";
    end

    fields = [fields property];
    verifyNestedStruct(s, fields); % throws an error in function if it can't find the field

    for k = 1:numel(fields)
        s = s.(fields(k));
    end
    out = s;
end
