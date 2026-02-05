function s = assignNestedField(s, fields, val)
    % s: The original structure
    % fields: A string array of field names, e.g., ["a", "b", "c"]
    % val: The value to assign at the end of the chain

    % GOAL: Return the struct using a set of field names with the value changed

    if ~verifyNestedStruct(s, fields)
        error("structure does not have fields: %s", fields)
    end

    if(fields(1) == "geometry") % need to append .v
        fields = [fields "v"];
    end

    % With things processed, we run a recrusive call to run through the struct

    % TODO: Consider changing this to a for loop like readNestedField for speed
    s = assignNestedFieldRecrusive(s, fields, val);
end