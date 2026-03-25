function interpObj = build_engine_lookup(engine_name)
    % Function looks in NPSS_Sweeps for a file (engine_name).mat
    % Throws an error if it does not exist
    % Otherwise returns a gridded interpolant object for (altitude (m), Mach Number, Throttle)
        % Note that here throttle is 0-0.9, 0.9-1 (afterburner) and needs to vary linearly with throttle
        % This requires some processing in this function to convert from NPSS 0-150
    % The interpolant object is stored in models.mem and is created if it does not exist

    funcDir = fileparts(mfilename('fullpath'));
    sweepFilePath = fullfile(funcDir, "NPSS_Sweeps", engine_name + '.mat');

    if ~isfile(sweepFilePath)
        error("NPSS Sweep for engine '%s' does not exist at: '%s'", engine_name, sweepFilePath);
    end

    sweepFile = load(sweepFilePath);

    data = sweepFile.DataTable

end