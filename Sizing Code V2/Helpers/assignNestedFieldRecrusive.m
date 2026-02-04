function s = assignNestedFieldRecrusive(s, fields, val)
    % take this out so you dont run checks every time
    if isscalar(fields)
        s.(fields(1)) = val;
    else
        s.(fields(1)) = assignNestedFieldRecrusive(s.(fields(1)), fields(2:end), val);
    end
end