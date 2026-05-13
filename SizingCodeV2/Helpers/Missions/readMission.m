function mission_obj = readMission(file_name)
    fullPath = mfilename('fullpath');
    codeFolder = fileparts(fullPath);
    readFile = fullfile(codeFolder, "../..", "AircraftFiles/Missions", file_name + ".mat");
    if ~isfile(readFile)
        error("Mission file '%s' does not exist in 'AircraftFiles/Missions' folder.", file_name);
    end
    data = load(readFile, 'mission_obj');
    mission_obj = data.mission_obj;
end