function out = readNestedField(s, fields)
    if(fields(1) == "geometry") % need to append .v
            fields = [fields "v"];
    end

    for k = 1:numel(fields)
        s = s.(fields(k));
    end
    out = s;
end
