function [PR, corners] = payload_range_diagram(perf, W_OEW, W_fuel_max, W_MTOW, ...
                                                h_cruise, M_cruise, h_loiter, M_loiter, ...
                                                reserveFrac)
    if nargin < 9, reserveFrac = 0.05; end
    g = 9.81;
    W_pld_max = 0.18 * W_MTOW;
    payload_vec_N = linspace(0, W_pld_max, 10);

    PR.payload_kg   = payload_vec_N / g;
    PR.range_km     = nan(size(payload_vec_N));
    PR.loiter_hr    = nan(size(payload_vec_N));
    PR.fuel_used_kg = nan(size(payload_vec_N));

    for i = 1:numel(payload_vec_N)
        W_pld  = payload_vec_N(i);
        W_fuel = W_MTOW - W_OEW - W_pld;
        if W_fuel <= 0, continue; end
        W_fuel = min(W_fuel, W_fuel_max);
        W_burn = W_fuel * (1 - reserveFrac);
        Wi = W_MTOW;
        Wf = Wi - W_burn;
        W_avg = (Wi + Wf)/2;

        % Cruise
        perf.model.cond = levelFlightCondition(perf, h_cruise, M_cruise, W_avg, ...
                            perf.model.settings.codes.MV_DEC_MACH);
        perf.clear_data(); perf.model.clear_mem();
        V_cr  = perf.model.cond.vel.v;
        LD_cr = perf.LD;
        c_cr  = perf.mdotf * g * LD_cr / W_avg;
        PR.range_km(i) = (V_cr/c_cr) * LD_cr * log(Wi/Wf) / 1e3;

        % Loiter
        perf.model.cond = levelFlightCondition(perf, h_loiter, M_loiter, W_avg, ...
                            perf.model.settings.codes.MV_DEC_MACH);
        perf.clear_data(); perf.model.clear_mem();
        LD_lo = perf.LD;
        c_lo  = perf.mdotf * g * LD_lo / W_avg;
        PR.loiter_hr(i) = (1/c_lo) * LD_lo * log(Wi/Wf) / 3600;

        PR.fuel_used_kg(i) = W_burn / g;
    end

    corners = [];   % unused with this sweep approach, kept for signature compatibility
end