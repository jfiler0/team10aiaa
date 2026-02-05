function out = readNestedField(s, fields)
    % GOAL: Work through a s with a string array of field names to get the value

    % TODO: Get all constructors in the same format so they all need .v
    if(fields(1) == "geometry") % need to append .v
            fields = [fields "v"];
    end

    % TODO: May want a check to ensure the fields exist

    for k = 1:numel(fields)
        s = s.(fields(k));
    end
    out = s;
end
