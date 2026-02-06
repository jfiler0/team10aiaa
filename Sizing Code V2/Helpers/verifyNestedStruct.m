function bool = verifyNestedStruct(struct, fields)
    % struct is a nested structure
    % chain is a string with period delimeters for each field
    % returns true if the nested field exist, false otherwise/errors out
    bool = true;

    for i = 1:length(fields)
        if(~isfield( struct, fields(i) ))
            bool = false;
            break;
        end
        struct = struct.( fields(i) );
    end

    if ~bool % detected nonexist field
        error("structure does not have fields: %s",join(fields, ".") )
    end
end