function writeMission(mission_obj)
    fullPath = mfilename('fullpath');
    codeFolder = fileparts(fullPath);
    saveFile = fullfile(codeFolder, "../..", "AircraftFiles/Missions", mission_obj.name.v + ".mat");
    save(saveFile, 'mission_obj');
end