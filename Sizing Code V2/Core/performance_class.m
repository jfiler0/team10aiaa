classdef performance_class < handle % <--- Inheriting from handle allows in-place updates (memory based/pointers)

    properties
        aircraft % link to the aircraft - curious if this is still as memory or not
        data % struct storing key performance info as it is generated
    end

    methods
        function obj = performance_class(models, geom, cond, settings)
            % Main function to call and create the aircraft object
            obj.models = models;
            obj.geom = geom;
            obj.cond = cond;
            obj.settings = settings;
        end

        function setGeomVar(obj, structChain, value) 
            % TODO: Run a check to see if this a primary variable and throw error otherwise
            
            % structChain MUST be a string (not a character list) with . delimiters
            % Easiest way is to do aircraft.geom and look at the fields
            
            fields = [strsplit(structChain, '.'), 'v'];

            % Make sure the field we want to change actually exists. If we don't it will be silent and just create the field
            if(~verifyNestedStruct(obj.geom, fields))
                error("Given geom chain: [%s] does not exist.", structChain)
            end

            % Update the primary variable
            obj.geom = assignNestedField(obj.geom, fields, value);

            % Recacluate everything
            % TODO: This is inefficent and can be streamlined
            obj.geom = processGeometryDerived(obj.geom);
            obj.geom = processGeometryWeight(obj.geom);
        end

        function out = call(obj, iden)
            % Wrapper for the models object
            % calls given model provided current geom, cond, settings
            out = obj.models.call(iden, obj.geom, obj.cond);
        end
        function out = vector_call(obj, iden, structChain, numVec)
            % Wrapper for the models object
            out = obj.models.vector_call(iden, obj.geom, obj.cond, structChain, numVec);
        end
    end
end