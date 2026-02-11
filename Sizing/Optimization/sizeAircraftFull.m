function plane = sizeAircraftFull(variables, plane, missionList, constrainFun)

    % EXPERIEMTNAL AT PRESENT
    % variables is a cell array. First column is the constructor identifier in plane to edit. Columns 2 & 3 are the bounds

    x0 = getX0Array(variables, plane);

    R_bounds = 100; % penalty for violting parameter bounds

    g_max = @(x) checkVariableBounds(variables, x);

    f = @(x) objective_constrained(updateVariables(variables, x, plane), missionList, constrainFun)  + g_max(x)*R_bounds;

    options = optimset( ...
        'Display', 'iter', ...      % Display iteration info
        'TolX', 1e-5, ...           % Tolerance on x
        'TolFun', 1e-5, ...         % Tolerance on function value
        'MaxIter', 50, ...         % Maximum iterations
        'MaxFunEvals', 1000 ...     % Maximum function evaluations
    );
    
    [x_opt, fval_opt, exitflag, output] = fminsearch(f, x0, options);

    % MTOW_opt    = x_opt(1);
    % scale_opt = x_opt(2);

    disp("Optimum Design: ")
    for i = 1:length(x_opt)
        iden = variables{i,1};
        fprintf("--[%s] = %.4g\n", iden, x_opt(i))
    end

    plane = updateVariables(variables, x_opt, plane);

end
function g_max = checkVariableBounds(variables, x)

    g_up = zeros(size(x)); % upper bound checks
    g_low = zeros(size(x)); % lower bound checks


     for i = 1:length(x)
        iden = variables{i,1};
        g_up(i) = x(i) / variables{i,3} - 1;
        g_low(i) = 1 - x(i) / variables{i,2};
     end

     g_max = max([g_up; g_low]);

end
function plane = updateVariables(variables, x, plane)
    % Uses the first column of variables as the constructor identifiers to look up
    % x is a double array that pairs with each one

    if(height(variables) ~= length(x))
        error("Length of variables identifiers and input doubles does not match")
    end

    for i = 1:length(x)
        iden = variables{i,1};
        plane.(iden) = x(i);
    end

     plane = plane.updateDerivedVariables();

end
function x0 = getX0Array(variables, plane)
    x0 = zeros([height(variables) 1]);

    for i = 1:length(x0)
        iden = variables{i,1};
        x0(i) = plane.(iden);
    end

end