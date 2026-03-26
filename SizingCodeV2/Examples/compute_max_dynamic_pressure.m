function q_max = compute_max_dynamic_pressure(perf, W)
    % Give W as total weight in N or as 0-1 (WE to MTOW)
    % Returns q_max in Pa

    % This was a complex optimization function. But it just tries to push the alitude to -inf. So, just running max max at sealevel is sufficent
    M_opt = compute_max_mach_at_h(perf, W, 0);
    cond = levelFlightCondition(perf, 0, M_opt, W);
    q_max = cond.qinf.v;
end