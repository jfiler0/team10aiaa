function [T, a, P, rho, mu] = queryAtmosphere(alt, values_to_get)
    % values_to_get: [T a P rho mu] logical array, assign 1 or 0. More speed improvements
    % For example, if you just want temperature you can call queryAtmosphere(0, [1 0 0 0 0])
    
    % T - K - Free Stream Temperature
    % a - m/s - Speed of Sound
    % P - Pa - Free Stream Pressure
    % rho - kg/m3 - Free Stream Density
    % mu - Pa - Dynamic Viscosity
    
    % There are alot of improvements done on this function because it is regularly called a ton of times. Especially in V1 of the code (V2
    % is a bit more efficent in not recalculating atmosphere). So, small improvements here are useful.
    
    persistent cachedAtmosphere
    % This way we only need to load the .mat once as it is comparatively very expensive
    
    % The user is expected to have ran build_atmosphere_lookup (this is called when initialize is run). The lookup is not normally tracked
    % with git so this has to be preloaded
    if isempty(cachedAtmosphere)
        % Load the lookup built with build_atmosphere_lookup
        funcDir = fileparts(mfilename('fullpath'));
        atmFile = fullfile(funcDir, 'atmosphere_lookup.mat');
        if ~isfile(atmFile)
            error('Atmosphere lookup file not found. Build it with build_atmosphere_lookup first.');
        end
        tmp = load(atmFile, 'atmosphere');
        cachedAtmosphere = tmp.atmosphere;
    end
    
    if isnan(alt) % Going to use this as a special case to get alt limits. Bit scuffed but should work. No good reason for alt to be NaN otherwise
        T = cachedAtmosphere.alt(1);
        a = cachedAtmosphere.alt(end);
        P = 0;
        rho = 0;
        mu = 0;
        warning("\nAtmosphere has become NaN")
        return
    end
    if imag(alt)~=0
        % I used to just take the real part and move on. But imaginary altitudes are indicative of serious issues
        error("\nqueryAtmosphere alt became imaginary: %.3f + i %.3f ", real(alt),imag(alt))
    end

    % Quick bounds check
    if min(alt) < cachedAtmosphere.alt(1) || max(alt) > cachedAtmosphere.alt(end)
        fprintf("\nWARNING: Altitude call is out of lookup range: %.2f meters", alt);
    end
    
    % Initialize (since it may not go into the if statements. Hard setting it as 0 is a bit dangerous but oh well
    T = NaN; a = NaN; P = NaN; rho = NaN; mu = NaN;

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
