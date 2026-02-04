classdef aircraft_class < handle % <--- Inheriting from handle allows in-place updates

    properties
        models
        geom
        cond
        settings
    end

    methods
        function obj = aircraft_class(models, geom, cond, settings)
            obj.models = models;
            obj.geom = geom;
            obj.cond = cond;
            obj.settings = settings;
        end
        % recommended to run this again after settings are loaded to make sure it is up to date
        function setGeomVar(obj, structChain, value) 
            % structChain MUST be a string (not a character list) with . delimiters
            fields = [strsplit(structChain, '.'), 'v'];

            if(~verifyNestedStruct(obj.geom, fields))
                error("Given geom chain: [%s] does not exist.", structChain)
            end

            obj.geom = assignNestedField(obj.geom, fields, value);

            obj.geom = processGeometryInput(obj.geom);
            obj.geom = processGeometryWeight(obj.geom);
        end

        function out = call(obj, iden)
            % calls given model provided current geom, cond, settings
            out = obj.models.call(iden, obj.geom, obj.cond);
        end
        function out = vector_call(obj, iden, structChain, numVec)
            out = obj.models.vector_call(iden, obj.geom, obj.cond, structChain, numVec);
        end
    end
end