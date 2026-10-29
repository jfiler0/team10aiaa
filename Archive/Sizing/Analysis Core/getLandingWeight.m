function W_landing = getLandingWeight(plane)
    % Need to calculate landing weight
    % FROM RFP:
        % Arrestment landing weight shall include sufficient fuel for 20 minutes loiter at 
        % 10,000 ft and two landing attempts, 25% maximum fuel weight, and 50% store weight.

    landing_loadout = buildLoadout(["AIM-9X", "FPU-12", "MK-83", "MK-83"]); % half of the strike loadout

    seg_list = [ flightSegment2("LOITER", NaN, 10000, 20) ; flightSegment2("LANDING") ; flightSegment2("TAKEOFF") ; flightSegment2("LANDING") ; flightSegment2("TAKEOFF") ];

    landing_mission = mission( seg_list , ...
        ...
        landing_loadout, "Landing Missions");

    fun = @(W_start) getFuelRemaining(landing_mission, plane, W_start) - plane.max_fuel_weight * 0.25;

    W_landing = fzero(fun, plane.MTOW/2);

    function fuel_remaining = getFuelRemaining(mission, plane, W_start)
            [~, ~, ~, fuel_remaining] = mission.solveMission(plane, false, W_start);
    end
end