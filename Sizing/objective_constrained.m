% Objective is now negative so goal is to MINIMIZE
function [objf_cons, cost, g_vec] = objective_constrained(MTOW, scale, plane, missionList, constrainFun)

    plane.span = plane.span * scale;
    plane.c_r = plane.c_r * scale;
    plane.c_t = plane.c_t * scale;
    plane.MTOW = MTOW;

    plane = plane.updateDerivedVariables();

    objf = plane.calcUnitCost();
    cost = objf;

    [g_vec, ~] = constrainFun(plane, missionList);

    g_max = max(g_vec);

    R = 500; % Penalty parameter

    objf_cons = objf + R * g_max;
end