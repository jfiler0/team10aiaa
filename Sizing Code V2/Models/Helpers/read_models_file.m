function models = read_models_file(name)
    % properly reads a saved model file using build_models_file from models_class

    fullPath = mfilename('fullpath');
    codeFolder = fileparts(fullPath);
    readFile = fullfile(codeFolder, "../Saved_Models/", name+".mat");
        % If this is changed, build_models_file must be corrected

    models = load(readFile);
    models = models.model;
end