% can be called generally with a mach number (or a vector of them) an return corresponding scalers

classdef correction_factor
    properties
        mach_vec
        scale_vec
        interpolant
        is_scaler
    end

    methods
        function obj = correction_factor(mach_vec, scale_vec)
            obj.mach_vec = mach_vec; % if only one mach number is given (or like 0, it is a constant)
            obj.scale_vec = scale_vec;
            
            if(length(mach_vec) ~= length(scale_vec))
                error("mach_vec must be in equal length to scale_vec")
            end

            if(length(obj.mach_vec) > 1)
                obj.is_scaler = false;
                obj.interpolant = griddedInterpolant(mach_vec, scale_vec, 'linear', 'linear');
            else
                obj.is_scaler = true;
                obj.interpolant = [];
            end
        end

        function output = ask(obj, mach)
            % mach can be a vector
            if(obj.is_scaler)
                output = mach * 0 + obj.scale_vec;  % preserves size without allocation - just in case we still need it in vector form
            else
                % output = interp1(obj.mach_vec, obj.scale_vec, mach,'linear','extrap');
                output = obj.interpolant(mach);
            end
        end
    end
end