function out = readNestedField(s, fields)
    % GOAL: Work through a s with a string array of field names to get the value

    fields = [fields "v"];
    verifyNestedStruct(s, fields); % throws an error in function if it can't find the field

    for k = 1:numel(fields)
        s = s.(fields(k));
    end
    out = s;
end
