function plot_models(aircraft, N)
    % NAME: plot_models
    % INPUTS:
    %   aircraft == the primary aicraft class taken from aircraft_class with all model information
    %   N == integer to define resolution of plots (for linspace)
    % PURPOSE:
    %   Runs all models. Which allows easy checks to make sure sensitivies are correct and nothing is broken

    % Note that the geometry and condition run is inherited from the aircraft call

    % Parasite Drag
    figure('Name', "CD0")
    WE_vec = linspace(aircraft.geom.weights.empty.v/2, aircraft.geom.weights.empty.v*2, N);
    CD0_vec = aircraft.vector_call("CD0", "geometry.weights.empty", WE_vec );
    plot(WE_vec, CD0_vec)
    xlabel("Empty Weight [N]")
    ylabel("CD0")
    axis tight
    title("Parasite Drag")

    % Wave Drag
    figure('Name', "CDW");
    M_vec = linspace(0.5, 2, N);
    CDW_vec = aircraft.vector_call("CDW", "condition.M", M_vec );
    plot(M_vec, CDW_vec)
    xlabel("Mach Number")
    ylabel("CDW")
    axis tight
    title("Wave Drag")
    
    % Unit Cost
    figure('Name', "Unit Cost");
    cost_vec = aircraft.vector_call("cost", "geometry.weights.empty", WE_vec );
    plot(WE_vec, cost_vec)
    xlabel("Empty Weight [N]")
    ylabel("Cost [millions]")
    axis tight
    title("Unit Cost")
end