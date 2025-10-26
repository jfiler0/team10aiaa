function value = getSetting(name)
    persistent settings
    
    % Load defaults if not already loaded
    if isempty(settings)
        settings = buildSettings();
    end
    
    % Check if the requested field exists
    if isfield(settings, name)
        value = settings.(name);
    else
        error('Setting "%s" does not exist.', name);
    end
end