function bool = verifyNestedStruct(struct, fields, do_return)
    % struct is a nested structure
    % chain is a string with period delimeters for each field
    % returns true if the nested field exist, false otherwise/errors out
    bool = true;

    % Default mode is to have this throw the error here to stop the program.
    % If do_return is true, it does not halt the program and just returns false
    if nargin < 3
        do_return = false;
    end

    for i = 1:length(fields)
        if(~isfield( struct, fields(i) ))
            bool = false;
            break;
        end
        struct = struct.( fields(i) );
    end

    if ~bool && ~do_return % detected nonexist field
        error("structure does not have fields: %s",join(fields, ".") )
    end
end