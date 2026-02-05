function s = assignNestedFieldRecrusive(s, fields, val)
    % Recurisve call that checks if fields is a single string or an aray. If it is an array WE MUST GO DEEPER
    if isscalar(fields)
        s.(fields(1)) = val;
    else
        s.(fields(1)) = assignNestedFieldRecrusive(s.(fields(1)), fields(2:end), val);
    end
end