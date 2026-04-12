function writeMissionStruct(mission, name, loadout)
    % Input the structure object. The name will be generated from the id
    % Writes to the "Aircraft Files" folder

    if nargin < 3
        loadout = "";
    end

    name = matlab.lang.makeValidName(name);

    mission_obj = struct();
    mission_obj.name = json_entry("Name", name, "s");
    mission_obj.data = mission;
    mission_obj.loadout = loadout;

    fullPath = mfilename('fullpath');
    codeFolder = fileparts(fullPath);
    saveFile = fullfile(codeFolder, "../..","AircraftFiles/Missions", mission_obj.name.v + ".json");
        % If this is updated, readMissionStruct must also be corrected
    
    jsonText = jsonencode(mission_obj, 'PrettyPrint', true);
    
    % Write JSON text to a file
    fileID = fopen(saveFile, 'w');
    fwrite(fileID, jsonText, 'char');
    fclose(fileID);
end