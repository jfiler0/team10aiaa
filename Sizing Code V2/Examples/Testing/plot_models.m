function plot_models(geom, model, N)
    % NAME: plot_models
    % INPUTS:
    %   aircraft == the primary aicraft class taken from aircraft_class with all model information
    %   N == integer to define resolution of plots (for linspace)
    % PURPOSE:
    %   Runs all models. Which allows easy checks to make sure sensitivies are correct and nothing is broken

    % Note that the geometry and condition run is inherited from the aircraft call

    model.cond = generateCondition(geom, 0, 0.3, 1, 0.5, 0.75);
    model.clear_mem;

    % Parasite Drag
    figure('Name', "CD0")

    MTOW_vec = linspace(geom.weights.mtow.v/2, geom.weights.mtow.v*2, 50);
    CD0_vec = geom_vector_call(geom, model, @model.CD0, "weights.mtow", MTOW_vec);

    plot(MTOW_vec, CD0_vec)
    xlabel("MTOW [N]")
    ylabel("CD0")
    axis tight; grid on;
    title("Parasite Drag")

    % Unit Cost
    figure('Name', "Unit Cost");

    cost_vec = geom_vector_call(geom, model, @model.COST, "weights.mtow", MTOW_vec);

    plot(MTOW_vec, cost_vec)
    xlabel("MTOW [N]")
    ylabel("Cost [millions]")
    axis tight; grid on;
    title("Unit Cost")

    % Wave Drag
    figure('Name', "CDW");
    
    model.clear_mem
    M_vec = linspace(0.3, 2, N);
    model.cond = generateCondition(geom, model.cond.h.v, M_vec, model.cond.n.v, model.cond.W.v, model.cond.throttle.v);

    CDW_vec = model.CDw;
    plot(M_vec, CDW_vec)
    xlabel("Mach Number")
    ylabel("CDW")
    axis tight; grid on;
    title("Wave Drag")

    % CDi
    figure('Name', "CDi")
    plot(M_vec, model.CDi)
    xlabel("Mach Number")
    ylabel("CDa")
    axis tight; grid on;
    title("Induced Drag")

    % CLa
    figure('Name', "CLa")
    CLa_vec = model.CLa;
    plot(M_vec, CLa_vec)
    xlabel("Mach Number")
    ylabel("CLa")
    axis tight; grid on;
    title("CLa")

    % Propulsion
    figure('Name',"Propulsion")

    PROP = model.PROP;
    TA = PROP(:, 1);
    TSFC = PROP(:, 2);
    alpha = PROP(:, 3);

    plot(M_vec, TA);
    xlabel("Mach Number")
    ylabel("Thrust Available [N]")
    yyaxis right
    plot(M_vec, TSFC);
    ylabel("TSFC [s]")

    axis tight; grid on;
    title("Propulsion TA and TSFC")
end