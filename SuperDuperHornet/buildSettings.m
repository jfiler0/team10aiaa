function settings = buildSettings()
    % Default simulation settings
    settings.XFOIL_ITER_LIMIT  = 150;          % Maximum XFOIL iterations
    settings.ALPHA_RESOLUTION   = 35;          % Number of points between alpha_min & alpha_max
    settings.ALPHA_MIN          = -10;          % Minimum angle of attack (deg)
    settings.ALPHA_MAX          = 25;          % Maximum angle of attack (deg)
    settings.SURFACE_DEFLECTION = 10;
    settings.SURF_DEF_RES       = 5;           % This is symmetric. So 2 means 5 per condition (2 on each side and no deflection)
    settings.RE_MIN             = 2e6;         % Minimum Reynolds number
    settings.RE_MAX             = 5e8;         % Maximum Reynolds number
    settings.RE_RES             = 12;           % Number of Re points to sample
end
