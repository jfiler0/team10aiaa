classdef models_class < handle % <--- Inheriting from handle allows in-place updates (memory based/pointers)
    
    % Ngl. Most of my pain so far for V2 has been in this class. But it is very powerful. It seperates the 'backend'
        % of what each model is actually doing from the useful outputs we want. It gives nice tools to generate
        % interpolats and efficently use the vector calculations in matlab. Will it save more time than I spent writing it?
        % No. Probably not.

    % Note that unlike aircraft_class, this class obj is prebuilt and saved as a .mat file to be called instead. Uses build_models_file
    % For example, simple_model.m in "Mode_Builders" which makes simple_model.mat in "Saved_Models"

    properties
        input_temp % Saves the current geometry, condition, and settings that are being used. Updated when calls are ran
            % TODO: Don't like the extra copying of the entire struct required to continue using input_temp
        model_list
            % array of models using model_def objects (they all must be there)
        num_models
            % saved since this is not changed during the simulation and is needed across the class
    end

    methods
        function obj = models_class(model_list)
            obj.model_list = model_list;
            obj.num_models = numel(obj.model_list);
            for i = 1:obj.num_models
                % Later we need to recopy a model to its place in obj.model_list without knowing i. So we save it here.
                obj.model_list(i).idx = i;
            end

            obj.input_temp = struct(); % Just to predefine type
            obj.updateSettings(readSettings()); % read settings from current file
        end

        % Recommended to run this again after settings are loaded to make sure it is up to date
        function updateSettings(obj, settings) 
            obj.input_temp.settings = settings;
        end
        function out = call(obj, id, geometry, condition)
            % Used to call when there are no vectors.
            
            % TODO: Try removing this now that aircraft_class is being used
            if nargin < 4
                condition = NaN;
            end
   
            obj.input_temp.geometry = geometry;
            obj.input_temp.condition = condition;
                % Update geometry and condition with the new ones

            model = obj.findModel(id); % may be a bottleneck
                % Searches through available models for an id that matches like "CDW" or "CDi"

            out = obj.internal_call(model, obj.input_temp, 1); % Pass this all into internal_call
        end
        function out = vector_call(obj, id, geometry, condition, structChain, numVec)
            % Run call but update a variable defined by structChain to be each value in numVec

            % BE CAREFUL ABOUT ENSUING structChain IS A REAL VAR. It will fail silently
                % TODO: Add a check to make sure the structChain is real

            % Will generate an assocaited output vector as if the call function is looped (of equal length to numVec)
            % if the model handle can be vectorized, it will generate a input struct array and pass it in. Otherwise, it will just loop
            
            if nargin < 4
                condition = NaN;
            end

            obj.input_temp.geometry = geometry;
            obj.input_temp.condition = condition;

            out = zeros(size(numVec));

            structChain = strsplit(structChain, '.'); % goes from this.type.of.format to "this type of format"
            
            model = obj.findModel(id);

            if model.vectorized && checkForMatchingChain(model, structChain)
                % the function can take the input directly as a vector
                obj.input_temp = assignNestedField(obj.input_temp, structChain, numVec);
                out = obj.internal_call(model, obj.input_temp, length(numVec));
                obj.input_temp = assignNestedField(obj.input_temp, structChain, numVec(end)); % don't want to accicently save vectors
            else
                % need to for loop through (function is not vectorized for the given input)
                for i = 1:length(numVec)
                    obj.input_temp = assignNestedField(obj.input_temp, structChain, numVec(i));
                    out(i) = obj.internal_call(model, obj.input_temp, 1);
                end
            end
        end
        function out = internal_call(obj, model, input, vec_length)
            % Now with all the info we need (what the model is, if it can be vectorized)

            % Check if this can be run through interpolation instead
            if model.has_interp
                % TODO: Does this need to check if given input is interpolated?
                if ~model.interp_loaded
                    % Turns out even if we don't send model back to aircraft it still updates. Joys of memory and pointers
                    model.interp = buildInterpolationModel(model,  input);
                        % Generation interpolation
                    model.interp_loaded = true;
                        % Make sure we don't load it again (unless something changes)
                        % TODO: Need to connect aircraft geometry changes to a flag to check interp here
                    obj.model_list(model.idx) = model; % Updates any changes to the model -> and somehow gets back to aircraft cause memory
                end
                
                out = model.interp(input, vec_length); % Call the interpoation
            else
                % Call without interpolation
                out = model.handle(input); % Goes to the handle provided for the associated id (in Analyisis_Functions)
            end
        end
        function model = findModel(obj, id)
            % Find the index that matches the given id in the model list
            [~, idx] = find(strcmp(id, [obj.model_list.id]) );
            model = obj.model_list(idx);
            if(isempty(idx))
                error("Do not see a model '%s' in the list.")
            end
        end
        
        % TODO: Figure out if this function is needed somewhere since it got put into internal_call
        % function loadInterps(obj, geometry, condition)
        %     obj.input_temp.geometry = geometry;
        %     obj.input_temp.condition = condition;
        % 
        %     for i = 1:obj.num_models
        %         model = obj.model_list(i);
        %         if model.has_interp
        %             model.interp = buildInterpolationModel(model, obj.input_temp);
        %             model.interp_loaded = true;
        %         end
        %         obj.model_list(i) = model;
        %     end
        % end
    end
end

function interp = buildInterpolationModel(model, in)
    % TODO: Comment the hell out of this
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

    % linear/nearest/next/previous/pchip/cubic/spline/makima
    F = griddedInterpolant(def_vecs, values, model.interp_method, 'linear'); % spline is less stable but better accuracy for less points
    % interp = @(in) F(expandInputs(in, model));
    % This ensures that if you ask for 1 point, you get a 1xL row vector
    interp = @(in, vec_length) reshape(F(expandInputs(in, model, vec_length)), [], outLen);
end

function interpInputs = expandInputs(in, model, vec_length)
    % Take the input info and grab the needed inputs from model to pass into interp as an anymous function
    % Key part of the interpolation function. 

    interpInputs = zeros([vec_length, model.num_interp_inputs]); % Predefine with enough room for the vector calls

    % TODO: ngl I forgot what this function really did
    for i = 1:model.num_interp_inputs
        interpInputs(:, i) = readNestedField(in, model.interp_inputs(i).structChain);
    end
end

function boolRes = checkForMatchingChain(model, structChain)
    % TODO: Is this duplicated by verifyNestedStruct now?
    % Given some input structChain, see if the given model has it defiend as an input. Returns true/false

    boolRes = false;
    i = 1;
    while i <= model.num_inputs
        if( min(strcmp(structChain, model.inputs(i).structChain)) ) % this compares each element (will see what happens with mismatched lengths. Min in case any are false)
            boolRes = true;
            break;
        end
        i = i + 1;
    end
end