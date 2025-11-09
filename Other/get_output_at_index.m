% Because for some reason this isn't native in matlab

function out = get_output_at_index(func_handle, index)
    % Call the function with as many outputs as it supports
    nout = max(nargout(func_handle), max(index));  % ensure enough outputs
    [varargout{1:nout}] = func_handle();
    out = varargout{index};
end