function CD0 = CD0_basic(in)
    % in contains geometry, conditions, settings
    c = -0.1289; d = 0.7506; % Regression from somewhere lol
    S_wet = in.settings.CD0_scaler * 0.09290304 * (10^c  * N2lb( in.geometry.weights.empty.v ).^d); % Converting S_wet in ft and W0 in lb
    Cf = 0.004; % Raymer gives this value for navy fighters
    CD0 = Cf * S_wet/in.geometry.ref_area.v;
end

% 0 would indicate not to interpolate at all and just call each time
% models(settings, [ model_def( "CD0", @CD0_basic, [model_input("geometry.weights.mtow", 10, [1E2 1E6]) model_input("geometry", "wing.span")] ) ] )

% Each model gets input.geometry input.conditions input.settings avaiable
% model is called as models.call("CD0", geometry, conditions) <- settings is saved

% model_def holds the function id, handler, and a list of input info
% each input is an order of struct hierarchy + interpolation info (first string is the first struct)