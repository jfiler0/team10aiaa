function interpObj = load_engine_lookup(engine_name, force_rebuild)
    arguments
        engine_name string
        force_rebuild logical = false
    end

    funcDir = fileparts(mfilename('fullpath'));
    sweepFilePath = fullfile(funcDir, "NPSS_Sweeps", engine_name + '.mat');
    interpFilePath = fullfile(funcDir, "Prop_Interps", engine_name + '.mat');
    devFilePath = fullfile(funcDir, "Prop_Interps", engine_name + '_dev.mat'); % saving extra info about engine lookup. Mainly for engine_lookup_testing
    if (~isfile(interpFilePath) || force_rebuild)
        fprintf("Building interpolation file for %s engine. This only needs to be done once per computer...\n", engine_name)
        [interpObj, devObj] = build_engine_lookup(sweepFilePath);
        save(interpFilePath, "interpObj");
        save(devFilePath, "devObj");
        fprintf("Engine interp file complete and saved at '%s'\n", interpFilePath);
    else
        storage = load(interpFilePath);
        interpObj = storage.interpObj;
    end
end