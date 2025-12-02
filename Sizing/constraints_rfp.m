function [g_vec, g_names] = constraints_rfp(plane, missionList)

    % g_vec -> array of constraint values
    % g_names -> identifier for each constraint

    g_vec = [];
    g_names = [];

    % This is a space to get the maximum constraint and return the name of the currently active constraitns

    %% Mission Constraints - should be in all constraints files
    diff = W0_diff(plane, missionList); % This should be negative to be satisfied
    g1 = diff / plane.WE; % Provide scaling

    g_vec = [g_vec g1];
    g_names = [g_names "Mission Constraints"];

    %% 3.2.3 -> Approach airspeed shall be greater than 10% above stall speed, but less than 145 knots.
    % What weight should this be?

    g2 = plane.calcLandingSpeed(0, plane.MTOW) / kt2ms(145) - 1;
    g_vec = [g_vec g2];
    g_names = [g_names "145kt Landing"];

    %% 3.4.1 -> 8 deg/s sustained turn rate at 20kf

    %% 3.4.1 -> M 1.6 dash at 30kf
    % *** Corret to be mid mission fuel weight and air2air configuration

    fixed_input_copy = plane.fixed_input;
    fixed_input_superclean = fixed_input_copy; % Making another set of corrections for the mach mach condition (when you scrub down the plane and make it super sleek to set a record)

    % Drag corrections to match F18 performance data for max mach
    fixed_input_superclean.SWET_Scalar = 2;
    fixed_input_superclean.CDW_Scalar = 7/4;
    fixed_input_superclean.K1_Scalar = 1;
    
    plane.fixed_input = fixed_input_superclean;
    plane = plane.updateDerivedVariables();

    maxMach = plane.calcMaxMachFixedAlt(ft2m(30000), plane.WE, 1, 1.1);
    g3 = 1 - maxMach / 1.6;
    g_vec = [g_vec g3];
    g_names = [g_names "M1.6 Dash"];

    plane.fixed_input = fixed_input_copy;
    plane = plane.updateDerivedVariables();

    %% 3.4.5 -> M 0.85 sea level dash
    % *** Corret to be mid mission fuel weight and strike configuration
    maxMach = plane.calcMaxMachFixedAlt(0, plane.WE, 1, 0.6);
    g4 = 1 - maxMach / 0.85;
    g_vec = [g_vec g4];
    g_names = [g_names "M0.85 Dash"];

    %% 3.5.7 -> If multi-engine, approach SEROC not less than 500 ft/min

    %% 3.5.8 -> Unfolded wingspan shall not exceed 60 feet
    g5 = plane.span / ft2m(60) - 1;
    g_vec = [g_vec g5];
    g_names = [g_names "60ft Max Span"];

    %% 3.5.9 -> Foled wing span shall not exceed 35 ft
    %% 3.5.10 -> Overall aircraft length shall not exceed 50 feet
    %% 3.5.11 -> Overall aircraft height shall not exceed 18.5 feet
    %% 3.5.13 -> Maximum take-off gross weight shall not be greater than 90,000 lb

    g6 = plane.MTOW / lb2N(90000) - 1;
    g_vec = [g_vec g6];
    g_names = [g_names "45 ton MTOW"];

    %% Liftoff speed reqs


end