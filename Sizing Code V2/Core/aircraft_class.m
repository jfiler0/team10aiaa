classdef aircraft_class < handle % <--- Inheriting from handle allows in-place updates (memory based/pointers)

    properties
        % Does not look like much but each of these are big constructors or classes with lots in them
        models
        geom
        cond
        settings
    end

    methods
        function obj = aircraft_class(models, geom, settings)
            % Main function to call and create the aircraft object
            obj.models = models;
            obj.geom = geom;
            obj.cond = buildDefaultCondStruct(); % but everything is 0 - need to update
            obj.settings = settings;

            % TODO: Improve this standard so it is trimmed
            obj.updateCondition(0, 0.4, 0.1, 0.5, 0.9);
        end

        function setGeomVar(obj, structChain, value) 
            % TODO: Run a check to see if this a primary variable and throw error otherwise
            % TODO: How to make sure models knows to reset
            
            % structChain MUST be a string (not a character list) with . delimiters. Don't include the .v
            % Easiest way is to do aircraft.geom and look at the fields

            % Update the primary variable
            obj.geom = assignNestedField(obj.geom, strsplit(structChain, '.'), value); % this checks if the field exists

            % Recacluate everything
            % TODO: This is inefficent and can be streamlined
            obj.geom = processGeometryDerived(obj.geom);
            obj.geom = processGeometryWeight(obj.geom);
        end

        function updateCondition(obj, h, M_vel, CL, W, throttle)
            % specify either altitude and mach or altitude and velocity (tells which it is from magnitude)

            % THROTTLE - There is both AB throttle and normal throttle. 
            %   Max military power when throttle = 0.9
            %   Full AB is throttle = 1

            obj.cond.h.v = h;
            [obj.cond.T.v, obj.cond.a.v, obj.cond.P.v, obj.cond.rho.v, obj.cond.mu.v] = queryAtmosphere(h, [1 1 1 1 1]);
        
            if(M_vel < 5) % pretty much no plane is going under 5 m/s but this can be made more robust if it becomes an issu
                obj.cond.M.v = M_vel;
                obj.cond.vel.v = M_vel * obj.cond.a.v;
            else
                obj.cond.M.v = M_vel / obj.cond.a.v;
                obj.cond.vel.v = M_vel;
            end
        
            obj.cond.CL.v = CL;
            obj.cond.mil_throttle.v = min([throttle 0.9])/0.9; % Goes from 0-1 from output between throttle=0-0.9
            obj.cond.ab_throttle.v = (max([throttle 0.9]) - 0.9)/0.1; % Stays 0 unitl throttle = 0.9 and grows to 1between 0.9-1
        
            obj.cond.qinf.v = 0.5 * obj.cond.rho.v * obj.cond.vel.v * obj.cond.vel.v;

            % TODO: Need to conditions using json_entry
            obj.cond.Lift.v = obj.geom.ref_area.v * obj.cond.qinf.v * obj.cond.CL.v;

            % If W is less than 1 it must be a 0-1 scaler instead of actual weight. So use linear scale between WE and W0
            if(W <= 1) 
                obj.cond.W = obj.geom.weights.empty.v + (obj.geom.weights.mtow.v - obj.geom.weights.empty.v) * W;
            else
                % Otherwise just set it
                obj.cond.W = W;
            end
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