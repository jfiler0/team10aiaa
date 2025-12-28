function model = model_def(id, handle, inputs)
    % id = what the lookup is for the function. Very important as this is used across the program
    % handle = @whatever-function-to-call
    %    the functions should take in the input with input.geometry, input.condition
    % inputs = from model_input which defines interpolation information
    
    model = struct();
    model.id = id;
    model.handle = handle;
    model.inputs = inputs([inputs.res] ~= 1); % filter out any with an input of 1
    model.num_inputs = length(inputs);
    model.has_interp = min(inputs.do_interp);
    if( max(inputs.do_interp) ~= model.has_interp)
        warning("Interpolation scemes have been defined mixed with fixed calls for model: '%s'. Defaulting to no interp.", model.id)
    end
    model.interp_loaded = false;
    model.interp = [];

end