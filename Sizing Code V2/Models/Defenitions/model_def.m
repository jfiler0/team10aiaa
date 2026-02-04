function model = model_def(id, handle, inputs, interp_method)
    % id = what the lookup is for the function. Very important as this is used across the program
    % handle = @whatever-function-to-call
    %    the functions should take in the input with input.geometry, input.condition
    % vectorized = a boolean toggle to if the handle can perfom vector operations
    % inputs = from model_input which defines interpolation information
    
    model = struct();
    model.id = id;
    model.idx = NaN; % the associated location of the model within the models class
    model.handle = handle;
    model.inputs = [inputs([inputs.res] ~= 0)]; % filter out any with an input of 0 ( method of disabling)
    model.num_inputs = length(model.inputs);
    model.vectorized = max([inputs.vectorized]); % this toggles different behaviors in models. Making this false is more stable (but slower of course). 
    % If enabled, it is important to ensure the handle function can process vectorized inputs

    model.interp_inputs = model.inputs([model.inputs.res] > 1);
    model.num_interp_inputs = length(model.interp_inputs);

    if model.num_inputs > 0
        model.has_interp = model.num_interp_inputs > 0;
    else
        model.has_interp = false;
    end
    model.interp_loaded = false;
    model.interp = [];

    if nargin < 4 % did not define an interpolation scheme (linear/pchip/spline)
        model.interp_method = 'linear';
    else
        model.interp_method = interp_method;
    end
end