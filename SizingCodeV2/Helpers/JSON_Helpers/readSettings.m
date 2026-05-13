function read_struct = readSettings()
    % This centralizes finding where the file is read from
    % Assumes settings is directly in the Sizing V2 folder

    fullPath = mfilename('fullpath');
    codeFolder = fileparts(fullPath);
    readFile = fullfile(codeFolder, "../..","settings.json");
        % If this update, build_default_settings must also be corrected
    
    read_struct = readstruct(readFile);

    % now with our new scalers we need to loop theough the settings.scalers and convert it back to the correction_factor class

    scalers = fieldnames(read_struct.scalers);

    for i = 1:height(scalers)
        read_struct.scalers.(scalers{i}) = correction_factor(read_struct.scalers.(scalers{i}).mach_vec, read_struct.scalers.(scalers{i}).scale_vec);
    end

end