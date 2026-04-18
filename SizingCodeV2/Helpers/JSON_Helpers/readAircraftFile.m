function read_struct = readAircraftFile(file_name)
    % Input the name of the aircraft file, file_name (without the file extension!)
    % This centralizes finding where the file is read from
    % Note that this can only read from the "Aircraft Files" folder

    fullPath = mfilename('fullpath');
    codeFolder = fileparts(fullPath);
    readFile = fullfile(codeFolder, "../..","AircraftFiles", file_name+".json");
        % if this is updated, writeAircraftFile must also be corrected

    if ~isfile(readFile)
        warning("Aircraft file '%s' does not exist in 'AircraftFiles' folder. Defaulting to superhornet.", file_name);
        readFile = fullfile(codeFolder, "../..","AircraftFiles", "f18_superhornet.json");
    end
    
    read_struct = readstruct(readFile);
end