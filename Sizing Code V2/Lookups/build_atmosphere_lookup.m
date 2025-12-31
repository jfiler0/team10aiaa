function build_atmosphere_lookup(h_min, h_max, N)

    % All heights in meters

    alt_range = linspace(h_min, h_max, N);
    
    [T_vec, a_vec, P_vec, rho_vec, ~, mu_vec] = atmosisa(alt_range);
    
    atmosphere.alt = alt_range;
    %                                                                    INTERP    EXTRAP
    atmosphere.T_interp   = griddedInterpolant(atmosphere.alt, T_vec,   'linear', 'linear');
    atmosphere.a_interp   = griddedInterpolant(atmosphere.alt, a_vec,   'linear', 'linear');
    atmosphere.P_interp   = griddedInterpolant(atmosphere.alt, P_vec,   'linear', 'linear');
    atmosphere.rho_interp = griddedInterpolant(atmosphere.alt, rho_vec, 'linear', 'linear');
    atmosphere.mu_interp  = griddedInterpolant(atmosphere.alt, mu_vec,  'linear', 'linear');

    % Save to .mat file in the same folder
    funcDir = fileparts(mfilename('fullpath'));
    save(fullfile(funcDir, 'atmosphere_lookup.mat'), 'atmosphere');

end