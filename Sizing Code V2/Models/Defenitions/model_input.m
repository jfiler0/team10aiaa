function input = model_input(structChain, res, limits)
    % structChain = should be a string with periods to define different levels
    % res = the number of interpolation points
    % limits = [lower bound, upper bound]

    input = struct();
    input.structChain = strsplit(structChain, '.');
    
    if nargin < 2
        res = 0;
    end
    input.res = res;
    
    if nargin < 3 || res <= 1
        input.ub = NaN;
        input.lb = NaN;
        input.do_interp = false;
    else
        input.ub = max(limits);
        input.lb = min(limits);
        input.do_interp = true;
    end
end