function build_atmosphere_lookup(h_min, h_max, N)
    % build_atmosphere_lookup
    %   - h_min and h_max are in meters
    %   - N is the resolution of the lookup. Small penalty for large N
    % GOAL: Save a callable lookup of atmosia. Atmosia is EXTREMLY slow and is horrid for this kind of optimization

    % All heights in meters

    alt_range = linspace(h_min, h_max, N);
    
    % Fill in our data
    [T_vec, a_vec, P_vec, rho_vec, ~, mu_vec] = atmosisa(alt_range);
    
    % Assign our data fields. Gridded interp is better than other spline/interp1 methods for speed
    atmosphere.alt = alt_range;
    atmosphere.T_interp   = griddedInterpolant(atmosphere.alt, T_vec,   'linear', 'linear');
    atmosphere.a_interp   = griddedInterpolant(atmosphere.alt, a_vec,   'linear', 'linear');
    atmosphere.P_interp   = griddedInterpolant(atmosphere.alt, P_vec,   'linear', 'linear');
    atmosphere.rho_interp = griddedInterpolant(atmosphere.alt, rho_vec, 'linear', 'linear');
    atmosphere.mu_interp  = griddedInterpolant(atmosphere.alt, mu_vec,  'linear', 'linear');

    % Save to .mat file in the same folder
    funcDir = fileparts(mfilename('fullpath'));
    save(fullfile(funcDir, 'atmosphere_lookup.mat'), 'atmosphere');
end