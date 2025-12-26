function writeAircraftFile(geom)
    % Input the structure object + the name of the aircraft file (without the file extension!)
    % Writes to the "Aircraft Files" folder

    fullPath = mfilename('fullpath');
    codeFolder = fileparts(fullPath);
    saveFile = fullfile(codeFolder, "..","Aircraft Files", geom.id+".json");
    
    jsonText = jsonencode(geom, 'PrettyPrint', true);
    
    % Write JSON text to a file
    fileID = fopen(saveFile, 'w');
    fwrite(fileID, jsonText, 'char');
    fclose(fileID);

end