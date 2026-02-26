function read_struct = readSettings()
    % This centralizes finding where the file is read from
    % Assumes settings is directly in the Sizing V2 folder

    fullPath = mfilename('fullpath');
    codeFolder = fileparts(fullPath);
    readFile = fullfile(codeFolder, "../..","settings.json");
        % If this update, build_default_settings must also be corrected
    
    read_struct = readstruct(readFile);
end