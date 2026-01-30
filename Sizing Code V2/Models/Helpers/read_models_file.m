function models = read_models_file(name)
    % properly reads a saved model file

    fullPath = mfilename('fullpath');
    codeFolder = fileparts(fullPath);
    readFile = fullfile(codeFolder, "../Saved_Models/", name+".mat");

    models = load(readFile);
    models = models.model;

end