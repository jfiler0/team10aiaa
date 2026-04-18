function cond = levelFlightCondition(perf, h, MV, W)
    % h, M, and W can be vectors but they must be the same length
    % Goal: Compute the required throttle and CL to fly at the given flight conditions
    % Use the generateCondition function to prefill a cond struct. We will then edit the CL and throttle from there

    cond = P_Specified_Condition(perf, zeros(size(h)), h, MV, W);

    % Used to be its own function be got replaced by P_Specified
end