function input = model_input(structChain, vectorized, res, limits)
    % structChain = should be a string with periods to define different levels
    % res = the number of interpolation points
    % limits = [lower bound, upper bound]

    input = struct();
    input.structChain = strsplit(structChain, '.');

    if nargin < 2
        vectorized = false;
    end
    input.vectorized = vectorized;
    
    if nargin < 3
        res = 1; % 0 means disabled. 1 is just on but no interpolation. Above 1 triggers interpolation
    end
    input.res = res;
    
    if nargin < 4
        if res > 1
            error("If interpolation is enabled, limits argument must be included")
        end
        input.ub = NaN;
        input.lb = NaN;
    else
        input.ub = max(limits);
        input.lb = min(limits);
    end
end