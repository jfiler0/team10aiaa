function time_hr = esimtate_max_loiter(perf)
    empty_weight = weightRatio(0, perf.model.geom);
    fuel_weight = weightRatio(1, perf.model.geom) - empty_weight;

    time = fzero(@(endurance) do_loiter(perf, empty_weight, fuel_weight, endurance), 100);

    time_hr = time/3600;
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
        perf.model.cond = levelFlightCondition(perf, h_loiter, v_loiter, W0); perf.clear_data();
        fuel_weight = fuel_weight - perf.mdotf * perf.model.settings.g_const * endurance_step;
    end
end