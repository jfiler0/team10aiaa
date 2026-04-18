function [total_weight, fuel_weight] = compute_rfp_landing_weight(perf, loadout)
    perf.clear_data();
    perf.model.geom = setLoadout(perf.model.geom, loadout);

    % The rfp asks for 20 min loiter at 10kf, then 2 landing attempts, finishing at 25% max fuel weight, and 50% store weight
    % The input loadout should include 50% store weight (not dropping tanks)

    empty_weight = weightRatio(0, perf.model.geom);

    fuel_weight = fzero(@(W) fun(W), perf.model.geom.weights.max_fuel_weight.v * 0.5);

    function res = fun(fuel_weight)
        fuel_weight = do_loiter(perf, empty_weight, fuel_weight, 20*60);
        fuel_weight = fuel_weight * 0.95; % two landing attempts (using 0.95 instead of 0.98)
        fuel_weight = fuel_weight * 0.95; % two landing attempts (using 0.95 instead of 0.98)

        res = empty_weight + fuel_weight - weightRatio(0.25, perf.model.geom); % have 25% max fuel weight remaining
    end

    total_weight = empty_weight + fuel_weight;
end

function fuel_weight = do_loiter(perf, empty_weight, fuel_weight, endurance)
    perf.clear_data();
    % endurance in seconds
    h_loiter = ft2m(10000);
    v_loiter = kt2ms(300);
    N_seg = 10;
    endurance_step = endurance / N_seg;

    for i = 1:N_seg
        W0 = empty_weight + fuel_weight;
        perf.model.cond = levelFlightCondition(perf, h_loiter, v_loiter, W0);
        fuel_weight = fuel_weight - perf.mdotf * perf.model.settings.g_const * endurance_step;
    end
end