function interpObj = load_engine_lookup(engine_name, force_rebuild)
    arguments
        engine_name string
        force_rebuild logical = false
    end

    funcDir = fileparts(mfilename('fullpath'));
    sweepFilePath = fullfile(funcDir, "NPSS_Sweeps", engine_name + '.mat');
    interpFilePath = fullfile(funcDir, "Prop_Interps", engine_name + '.mat');
    if (~isfile(interpFilePath) || force_rebuild)
        fprintf("Building interpolation file for %s engine. This only needs to be done once per computer...\n", engine_name)
        interpObj = build_engine_lookup(sweepFilePath);
        save(interpFilePath, "interpObj");
        fprintf("Engine interp file complete and saved at '%s'\n", interpFilePath);
    else
        storage = load(interpFilePath);
        interpObj = storage.interpObj;
    end
end