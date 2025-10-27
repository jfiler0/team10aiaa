function [T, a, P, rho, mu] = queryAtmosphere(alt, values_to_get)
    % values_to_get: [T a P rho mu] logical array, assign 1 or 0. More speed improvements
    % For example, if you just want temperature you can call queryAtmosphere(0, [1 0 0 0 0])

    % T - K - Free Stream Temperature
    % a - m/s - Speed of Sound
    % P - Pa - Free Stream Pressure
    % rho - kg/m3 - Free Stream Density
    % mu - Pa - Dynamic Viscosity

    persistent cachedAtmosphere
    
   if isempty(cachedAtmosphere)
        funcDir = fileparts(mfilename('fullpath'));
        atmFile = fullfile(funcDir, 'atmosphere_lookup.mat');
        if ~isfile(atmFile)
            error('Atmosphere lookup file not found. Build it with build_atmosphere_lookup first.');
        end
        tmp = load(atmFile, 'atmosphere');
        cachedAtmosphere = tmp.atmosphere;
    end

    % Quick bounds check
    if alt < cachedAtmosphere.alt(1) || alt > cachedAtmosphere.alt(end)
        error("Altitude call is out of lookup range.");
    end
    
    % Initialize
    T = 0; a = 0; P = 0; rho = 0; mu = 0;

    if values_to_get(1)
        T = cachedAtmosphere.T_interp(alt);
    end
    if values_to_get(2)
        a = cachedAtmosphere.a_interp(alt);
    end
    if values_to_get(3)
        P = cachedAtmosphere.P_interp(alt);
    end
    if values_to_get(4)
        rho = cachedAtmosphere.rho_interp(alt);
    end
    if values_to_get(5)
        mu = cachedAtmosphere.mu_interp(alt);
    end
end
