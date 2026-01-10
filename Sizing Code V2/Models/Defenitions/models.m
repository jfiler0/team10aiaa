classdef models < handle % <--- Inheriting from handle allows in-place updates

    properties
        input_temp
        model_list
        num_models
    end

    methods
        function obj = models(model_list)
            obj.model_list = model_list;
            obj.num_models = numel(obj.model_list);
            for i = 1:obj.num_models
                obj.model_list(i).idx = i;
            end

            obj.input_temp = struct();
            obj.updateSettings(readSettings()); % read settings from current file
        end
        % recommended to run this again after settings are loaded to make sure it is up to date
        function updateSettings(obj, settings)
            obj.input_temp.settings = settings;
        end
        function out = call(obj, id, geometry, condition)
            if nargin < 4
                condition = NaN;
            end

            obj.input_temp.geometry = geometry;
            obj.input_temp.condition = condition;

            out = obj.internal_call(id, obj.input_temp);
        end
        function out = vector_call(obj, id, geometry, condition, structChain, numVec)
            % BE CAREFUL ABOUT ENSUING structChain IS A REAL VAR. It will fail silently
            % will generate an assocaited output vector as if the call function is looped
            % if the model handle can be vectorized, it will generate a input struct array and pass it in. Otherwise, it will just loop
            
            if nargin < 4
                condition = NaN;
            end

            obj.input_temp.geometry = geometry;
            obj.input_temp.condition = condition;

            out = zeros(size(numVec));

            structChain = strsplit(structChain, '.');
            
            for i = 1:length(numVec)
                obj.input_temp = assignNestedField(obj.input_temp, structChain, numVec(i));
                out(i) = obj.internal_call(id, obj.input_temp);
            end
        end
        function out = internal_call(obj, id, input)
            model = obj.findModel(id);

            if model.has_interp
                % need to check history of inputs with res = 1
                if model.has_history
                    history = getHistoryInputs(model, obj.input_temp);

                    if history ~= model.history
                        model.history = history;
                        model.interp_loaded = false;
                        disp("update required")
                    end
                end
                if ~model.interp_loaded
                    % somehow build the interp
                    model.interp = buildInterpolationModel(model,  input);
                    model.interp_loaded = true;
                end
                obj.model_list(model.idx) = model;
                out = model.interp(input);
            else
                % Call without interpolation
                out = model.handle(input);
            end
        end
        function model = findModel(obj, id)
            [~, idx] = find(strcmp(id, [obj.model_list.id]) );
            model = obj.model_list(idx);
            if(isempty(idx))
                error(sprintf("Do not see a model '%s' in the list.", id))
            end
        end
        function loadInterps(obj, geometry, condition)
            obj.input_temp.geometry = geometry;
            obj.input_temp.condition = condition;

            for i = 1:obj.num_models
                model = obj.model_list(i);
                if model.has_interp
                    model.interp = buildInterpolationModel(model, obj.input_temp);
                    model.interp_loaded = true;
                end
                if model.has_history
                    model.history = getHistoryInputs(model, obj.input_temp);
                end
                obj.model_list(i) = model;
            end
        end
    end
end

function interp = buildInterpolationModel(model, in)
    nDim = model.num_interp_inputs;
    def_vecs = cell(1, nDim);
    res_vec = zeros(1, nDim);
    
    for i = 1:nDim
        input = model.interp_inputs(i);
        def_vecs{i} = linspace(input.lb, input.ub, input.res);
        res_vec(i) = input.res;
    end

    G = cell(1, nDim);
    [G{:}] = ndgrid(def_vecs{:});

    % Determine Output Length
    % Run the model once with the base 'in' to see how long the output is
    sample_out = model.handle(in);
    outLen = numel(sample_out);

    % Initialize values matrix
    % For a 2D grid [10, 10] and 5 outputs, size is [10, 10, 5]
    if nDim == 1
        values = zeros(res_vec, 1, outLen); 
    else
        values = zeros([res_vec, outLen]);
    end

    % Fill the values matrix
    for i = 1:numel(G{1}) % Loop through the input grid points
        temp_in = in; 
        for j = 1:nDim
            temp_in = assignNestedField(temp_in, model.interp_inputs(j).structChain, G{j}(i));
        end
        
        % Get the vector result
        res = model.handle(temp_in);
        
        % Assign the vector into the (N+1) dimension of the matrix
        % We use linear indexing for the grid dims, and ':' for the output dim
        if nDim == 1
            values(i, 1, :) = res;
        else
            % This syntax handles N-dimensions and maps 'i' to the grid location
            % while filling the final vector dimension
            idx = cell(1, nDim + 1);
            [idx{1:nDim}] = ind2sub(res_vec, i);
            idx{end} = ':';
            values(idx{:}) = res;
        end
    end

    F = griddedInterpolant(def_vecs, values, 'linear', 'none');
    % interp = @(in) F(expandInputs(in, model));
    % This ensures that if you ask for 1 point, you get a 1xL row vector
    interp = @(in) reshape(F(expandInputs(in, model)), [], outLen);
end

function s = assignNestedField(s, fields, val)
    % s: The original structure
    % fields: A string array or cell array of field names, e.g., ["a", "b", "c"]
    % val: The value to assign at the end of the chain

    if(fields(1) == "geometry") % need to append .v
        fields = [fields "v"];
    end
    if(fields(1)=="condition")
        % disp("hol up")
    end

    % fields % THIS SHOULD NOT ALWAYS BE WE

    % need to update conditions

    s = assignNestedFieldRecrusive(s, fields, val);
end
function s = assignNestedFieldRecrusive(s, fields,val)
    % take this out so you dont run checks every time
    if isscalar(fields)
        s.(fields(1)) = val;
    else
        s.(fields(1)) = assignNestedFieldRecrusive(s.(fields(1)), fields(2:end), val);
    end
end

function out = readNestedField(s, fields)
    if(fields(1) == "geometry") % need to append .v
            fields = [fields "v"];
    end

    for k = 1:numel(fields)
        s = s.(fields(k));
    end
    out = s;
end

function interpInputs = expandInputs(in, model)
    % take the input info and grab the needed inputs from model to pass into interp as an anymous function
    interpInputs = zeros([1, model.num_interp_inputs]);

    for i = 1:model.num_interp_inputs
        interpInputs(i) = readNestedField(in, model.interp_inputs(i).structChain);
    end
end

function history = getHistoryInputs(model, input)
    history = zeros([1 model.num_history_inputs]);
    for i = 1:model.num_history_inputs
        history(i) = readNestedField(input, model.history_inputs(i).structChain);
    end
end