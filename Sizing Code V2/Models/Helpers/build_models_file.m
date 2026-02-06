function build_models_file(model, file_name)
    % saves a model file (from models_class) in the right folder so it can be loaded for the sim

    fullPath = mfilename('fullpath');
    codeFolder = fileparts(fullPath);
    saveFile = fullfile(codeFolder, "../Saved_Models/", file_name+".mat");
        % If this is updated, read_models_file must be corrected
    
    save(saveFile, 'model')
end