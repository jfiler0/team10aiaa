function writeAircraftFile(geom)
    % Input the structure object. The name will be generated from the id
    % Writes to the "Aircraft Files" folder

    fullPath = mfilename('fullpath');
    codeFolder = fileparts(fullPath);
    saveFile = fullfile(codeFolder, "../..","AircraftFiles", geom.id.v + ".json");
        % If this is updated, readAircraftFile must also be corrected
    
    jsonText = jsonencode(geom, 'PrettyPrint', true);
    
    % Write JSON text to a file
    fileID = fopen(saveFile, 'w');
    fwrite(fileID, jsonText, 'char');
    fclose(fileID);
end