function read_struct = readAircraftFile(file_name)
    % Input the name of the aircraft file, file_name (without the file extension!)
    % This centralizes finding where the file is read from
    % Note that this can only read from the "Aircraft Files" folder

    fullPath = mfilename('fullpath');
    codeFolder = fileparts(fullPath);
    readFile = fullfile(codeFolder, "../..","Aircraft Files", file_name+".json");
    
    read_struct = readstruct(readFile);

end