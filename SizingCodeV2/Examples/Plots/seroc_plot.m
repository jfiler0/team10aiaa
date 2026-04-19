function seroc_plot(perf, N)
    num_engines = perf.model.geom.prop.num_engine.v;
    perf.model.geom.prop.num_engine.v = 1;
    perf.model.geom = updateGeom(perf.model.geom, perf.model.settings);

    perf.model.clear_mem(); perf.clear_data();

    W_vec = linspace(perf.model.geom.weights.empty.v, perf.model.geom.weights.mtow.v, N);

    v_vec = zeros(size(W_vec));

    for i = 1:length(v_vec)
        [v_land, ~, ~, ~] = compute_landing_speed(perf, W_vec(i));
        v_vec(i) = 1.05 * v_land; % 1.05 VPA?
    end

    perf.clear_data(); perf.model.cond = generateCondition(perf.model.geom, 0, v_vec, 1, W_vec, 1);
    excess_ab = perf.ExcessPower; 
    perf.clear_data(); perf.model.cond = generateCondition(perf.model.geom, 0, v_vec, 1, W_vec, 0.9);
    excess_mil = perf.ExcessPower;

    perf.clear_data(); perf.model.cond = generateCondition(perf.model.geom, perf.model.settings.tropical_day_alt, v_vec, 1, W_vec, 1);
    excess_ab_tr = perf.ExcessPower;
    perf.clear_data(); perf.model.cond = generateCondition(perf.model.geom, perf.model.settings.tropical_day_alt, v_vec, 1, W_vec, 0.9);
    excess_mil_tr = perf.ExcessPower;

    figure(Name="Excess Power")
    hold on
    plot(N2lb(W_vec)/1000, m2ft(excess_ab)*60/100, 'r-', DisplayName="Afterburning")
    plot(N2lb(W_vec)/1000, m2ft(excess_mil)*60/100, 'b-', DisplayName="Military")
    plot(N2lb(W_vec)/1000, m2ft(excess_ab_tr)*60/100, 'r--', DisplayName="Afterburning (Tropical Day)")
    plot(N2lb(W_vec)/1000, m2ft(excess_mil_tr)*60/100, 'b--', DisplayName="Military (Tropical Day)")

    xlabel("Weight [1000 lb]");
    ylabel("Rate of Climb [100ft/min]")
    title("Single Engine Rate of Climb at 1.05 VPA")
    grid on
    axis tight
    legend(Location="northeast")

    perf.model.clear_mem(); perf.clear_data();

    % just in case it does not update
    perf.model.geom.prop.num_engine.v = num_engines;
    perf.model.geom = updateGeom(perf.model.geom, perf.model.settings);
end