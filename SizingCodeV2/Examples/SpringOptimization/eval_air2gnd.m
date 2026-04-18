function [W_final, empty_weight] = eval_air2gnd(perf, radius_nm, dash_radius_nm, loadout)
    if nargin < 4
        loadout = ["AIM-9X" "Mk-83" "Mk-83" "FPU-12" "FPU-12" "FPU-12" "Mk-83" "Mk-83" "AIM-9x"];
    end

    geom = perf.model.geom;
    geom = setLoadout(geom, loadout);
    perf.model.geom = geom; perf.clear_data();
    
    empty_weight = weightRatio(0, geom);
    fuel_weight = weightRatio(1, geom) - empty_weight;
    
    fuel_weight = fuel_weight * 0.95; % TAKEOFF
    fuel_weight = do_cruise(perf, empty_weight, fuel_weight, nm2m(radius_nm-dash_radius_nm)); % CURISE OUT
    fuel_weight = do_combat(perf, empty_weight, fuel_weight, dash_radius_nm); % COMBAT
    fuel_weight = do_cruise(perf, empty_weight, fuel_weight, nm2m(radius_nm-dash_radius_nm)); % CURISE BACK
    fuel_weight = do_loiter(perf, empty_weight, fuel_weight, 20 * 60); % LOITER
    fuel_weight = fuel_weight * 0.98; % LANDING
    
    W_final = empty_weight + fuel_weight;
end

function fuel_weight = do_cruise(perf, empty_weight, fuel_weight, range)
    perf.clear_data();
    % range in meters
    h_cruise = ft2m(40000);
    v_cruise = kt2ms(480);
    N_seg = 10; % number of times to split it up
    range_step = range/N_seg;

    for i = 1:N_seg
        W0 = empty_weight + fuel_weight;
        perf.model.cond = levelFlightCondition(perf, h_cruise, v_cruise, W0); perf.clear_data();
        fuel_weight = fuel_weight - perf.mdotf * perf.model.settings.g_const * range_step / v_cruise;
    end
end

function fuel_weight = do_combat(perf, empty_weight, fuel_weight, dash_radius_nm)
    perf.clear_data();
    h_combat = ft2m(500); M = 0.85; % from req
    N_seg = 10; % number of times to split it up
    range_step = nm2m(2*dash_radius_nm)/N_seg;

    for i = 1:N_seg
        W0 = empty_weight + fuel_weight;
        perf.model.cond = levelFlightCondition(perf, h_combat, M, W0); perf.clear_data();
        fuel_weight = fuel_weight - perf.mdotf * perf.model.settings.g_const * range_step / perf.model.cond.vel.v;
    end
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