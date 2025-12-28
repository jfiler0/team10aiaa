classdef models

    properties
        input_temp
        model_list
        num_models
    end

    methods
        function obj = models(settings, model_list)

            obj.model_list = model_list;
            obj.num_models = numel(obj.model_list);

            obj.input_temp = struct();
            obj.input_temp.settings = settings;
            
        end
        function out = call(obj, id, geometry, condition)
            if nargin < 4
                condition = NaN;
            end

            [~, idx] = find(strcmp(id, [obj.model_list.id]) );
            model = obj.model_list(idx);

            obj.input_temp.geometry = geometry;
            obj.input_temp.condition = condition;

            if model.has_interp
                if ~model.interp_loaded
                    % somehow build the interp
                    model.interp = buildInterpolationModel(model,  obj.input_temp);
                    model.interp_loaded = true;
                    obj.model_list(idx) = model;
                end
                out = model.interp(obj.input_temp);
            else
                % Call without interpolation
                out = model.handle(obj.input_temp);
            end
        end
        function obj = loadInterps(obj, geometry, condition)
            obj.input_temp.geometry = geometry;
            obj.input_temp.condition = condition;

            for i = 1:obj.num_models
                model = obj.model_list(i);
                if model.has_interp
                    model.interp = buildInterpolationModel(model, obj.input_temp);
                    model.interp_loaded = true;
                    obj.model_list(i) = model;
                end
            end

        end
    end
end

function interp = buildInterpolationModel(model, in)

    nDim = model.num_inputs;
    def_vecs = {};
    for i = 1:nDim
        input = model.inputs(i);
        def_vecs{i} = linspace(input.lb, input.ub, input.res);
    end

    % zeros([model.inputs.res])

    G = cell(1, nDim);
    [G{:}] = ndgrid(def_vecs{:});

    values = zeros([model.inputs.res]);

    for i = 1:numel(values)
        for j = 1:nDim
            in = assignNestedField(in, model.inputs(j).structChain, G{j}(i));
        end
        values(i) = model.handle(in);
    end

    % loop through values using G values and getNestedField with handle

    F = griddedInterpolant(def_vecs, values, 'linear', 'none');
    interp = @(in) F(expandInputs(in, model));
end

function s = assignNestedField(s, fields, val)
    % s: The original structure
    % fields: A string array or cell array of field names, e.g., ["a", "b", "c"]
    % val: The value to assign at the end of the chain

    if numel(fields) == 1
        s.(fields(1)) = val;
    else
        s.(fields(1)) = assignNestedField(s.(fields(1)), fields(2:end), val);
    end
end

function out = readNestedField(s, fields)
    for k = 1:numel(fields)
        s = s.(fields(k));
    end
    out = s;
end

function interpInputs = expandInputs(in, model)
    % take the input info and grab the needed inputs from model to pass into interp as an anymous function
    interpInputs = zeros([1, model.num_inputs]);

    for i = 1:model.num_inputs
        interpInputs(i) = readNestedField(in, model.inputs(i).structChain);
    end
end