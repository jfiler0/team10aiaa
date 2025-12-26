function CD0 = CD0_basic(input, geom, settings)

    SWET_Scalar = 1;
    
    c = -0.1289; d = 0.7506; % Regression from somewhere lol
    S_wet = SWET_Scalar * 0.09290304 * (10^c  * N2lb( geom.weights.empty )^d); % Converting S_wet in ft and W0 in lb
    Cf = 0.004; % Raymer gives this value for navy fighters
    CD0 = Cf * S_wet/geom.ref_area;

end