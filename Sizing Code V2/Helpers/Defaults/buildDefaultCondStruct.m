function cond = buildDefaultCondStruct()
    % Prefills it with the right units and some defaults. Be careful that this matches the aircraft_class
    cond = struct();

    cond.h = json_entry("Altitude", 0, "m");
    cond.T = json_entry("Temperture", 0, "K", NaN, true);
    cond.a = json_entry("Speed of Sound", 0, "m/s", NaN, true);
    cond.P = json_entry("Temperture", 0, "K", NaN, true);
    cond.rho = json_entry("Density", 0, "kg/m3", NaN, true);
    cond.mu = json_entry("Dynamic Viscoisty", 0, "Ns", NaN, true);

    cond.M = json_entry("Mach Number", 0, "");
    cond.vel = json_entry("Velocity", 0, "m/s");

    cond.CL = json_entry("Lift Coefficent", 0, "", NaN, true);

    cond.throttle = json_entry("Throttle", 0, "");
    cond.mil_throttle = json_entry("Military Throttle", 0, "", NaN, true);
    cond.ab_throttl = json_entry("Afterburner Throttle", 0, "", NaN, true);

    cond.qinf = json_entry("Dynamic Pressure", 0, "Pa", NaN, true);

    cond.n = json_entry("Load Factor", 0, "");
    cond.Lift = json_entry("Lift", 0, "N", NaN, true);

    cond.W = json_entry("Weight", 0, "N");
end