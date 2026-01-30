function build_models_file(model, file_name)
    % saves model file in the right folder

    fullPath = mfilename('fullpath');
    codeFolder = fileparts(fullPath);
    saveFile = fullfile(codeFolder, "../Saved_Models/", file_name+".mat");
    
    save(saveFile, 'model')

end