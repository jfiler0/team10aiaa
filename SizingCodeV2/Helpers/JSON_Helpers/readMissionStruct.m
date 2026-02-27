function read_struct = readMissionStruct(file_name)
    % Input the name of the aircraft file, file_name (without the file extension!)
    % This centralizes finding where the file is read from
    % Note that this can only read from the "Aircraft Files" folder

    fullPath = mfilename('fullpath');
    codeFolder = fileparts(fullPath);
    readFile = fullfile(codeFolder, "../..","AircraftFiles/Missions", file_name+".json");
        % if this is updated, writeAircraftFile must also be corrected

    if ~isfile(readFile)
        error("Mission file '%s' does not exist in 'AircraftFiles/Missions' folder.", file_name);
    end
    
    read_struct = readstruct(readFile);
end