% Objective is now negative so goal is to MINIMIZE
function [objf_cons, cost, g_vec] = objective_constrained(plane, missionList, constrainFun)

    objf = plane.calcUnitCost();
    cost = objf;

    [g_vec, ~] = constrainFun(plane, missionList);

    g_max = max(g_vec);

    R = 500; % Penalty parameter

    objf_cons = objf + R * g_max;
end