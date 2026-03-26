function interpObj = build_engine_lookup(engine_name)
    % Function looks in NPSS_Sweeps for a file (engine_name).mat
    % Throws an error if it does not exist
    % Otherwise returns a gridded interpolant object for (altitude (m), Mach Number, Throttle)
        % Note that here throttle is 0-0.9, 0.9-1 (afterburner) and needs to vary linearly with throttle
        % The throttle to thrust must be linear in both regimes (but can have different slopes)
        % This requires some processing in this function to convert from NPSS 0-150
    % The interpolant object is stored in models.mem and is created if it does not exist

    funcDir = fileparts(mfilename('fullpath'));
    sweepFilePath = fullfile(funcDir, "NPSS_Sweeps", engine_name + '.mat');

    if ~isfile(sweepFilePath)
        error("NPSS Sweep for engine '%s' does not exist at: '%s'", engine_name, sweepFilePath);
    end

    sweepFile = load(sweepFilePath);

    data = sweepFile.DataTable;

    max_military = data.PLA == 100;
    max_ab = data.PLA == 150;

    max_thrust_mil = scatteredInterpolant(data.("Mach Number")(max_military), data.("Altitude")(max_military), data.("Thrust")(max_military));
    max_thrust_ab = scatteredInterpolant(data.("Mach Number")(max_ab), data.("Altitude")(max_ab), data.("Thrust")(max_ab));

    data.throttle = zeros(size(data.PLA));

    max_thrust_ab(1, 0)

    for i = 1:height(data)
        mil_thrust = max_thrust_mil( data.("Mach Number")(i), data.Altitude(i) );
        if(data.PLA(i) <= 100)
            data.throttle(i) = data.Thrust(i) / mil_thrust;
        else
            data.throttle(i) = ( data.Thrust(i) - mil_thrust ) / ( max_thrust_ab( data.("Mach Number")(i), data.Altitude(i) )  - mil_thrust );
        end
    end

    data
end