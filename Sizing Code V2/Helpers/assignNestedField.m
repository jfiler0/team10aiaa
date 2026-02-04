function s = assignNestedField(s, fields, val)
    % s: The original structure
    % fields: A string array or cell array of field names, e.g., ["a", "b", "c"]
    % val: The value to assign at the end of the chain

    if ~verifyNestedStruct(s, fields)
        error("structure does not have fields: %s", fields)
    end

    if(fields(1) == "geometry") % need to append .v
        fields = [fields "v"];
    end

    s = assignNestedFieldRecrusive(s, fields, val);
end