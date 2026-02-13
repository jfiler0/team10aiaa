classdef model_class < handle
    properties
        settings
        geom
        cond
        mem
    end
    
    methods
        function obj = model_class(settings, geom, cond)
            obj.settings = settings;
            obj.geom = geom;
            obj.cond = cond;
            obj.mem = struct('CD0', [], 'CDi', [], 'CDw', []);
        end
        
        % Generic method that handles all caching/override logic
        function result = compute_with_cache(obj, property_name, override, compute_func, scaler)
            % property_name - string field name in obj.mem (e.g., 'CD0')
            % override - override code from settings.codes
            % compute_func - function handle that computes the value
            % scaler - scaling factor to apply
            
            if nargin < 3
                override = obj.settings.codes.OVER_NONE;
            end
            
            % Check if we should read from cache
            should_read = ~isempty(obj.mem.(property_name)) && ...
                         (override ~= obj.settings.codes.OVER_NO_READ && ...
                          override ~= obj.settings.codes.OVER_NO_READ_NO_WRITE);
            
            if should_read
                result = obj.mem.(property_name);
            else
                % Compute the value using the provided function
                result = compute_func() * scaler;
                
                % Check if we should write to cache
                should_write = (override ~= obj.settings.codes.OVER_NO_WRITE && ...
                               override ~= obj.settings.codes.OVER_NO_READ_NO_WRITE);
                
                if should_write
                    obj.mem.(property_name) = result;
                end
            end
        end
        
        % Now CD0 becomes much simpler
        function CD0 = CD0(obj, override, code)
            if nargin < 2
                override = obj.settings.codes.OVER_NONE;
            end
            if nargin < 3
                code = obj.settings.CD0_model;
            end
            
            % Define the computation as a nested function
            compute_CD0 = @() obj.compute_CD0_value(code);
            
            CD0 = obj.compute_with_cache('CD0', override, compute_CD0, obj.settings.CD0_scaler);
        end
        
            % Separated computation logic
            function value = compute_CD0_value(obj, code)
                switch code
                    case obj.settings.codes.CD0_BASIC
                        c = -0.1289; d = 0.7506;
                        S_wet = 0.09290304 * (10^c * N2lb(obj.geom.weights.empty.v).^d);
                        Cf = 0.004;
                        value = Cf * S_wet/obj.geom.ref_area.v;
                        
                    case obj.settings.codes.CD0_IGNORE
                        value = 0;
                        
                    otherwise
                        error("Code '%i' has no recognized definition for the CD0 model.", code)
                end
            end
        
        % CDi becomes equally simple
        function CDi = CDi(obj, override, code)
            if nargin < 2
                override = obj.settings.codes.OVER_NONE;
            end
            if nargin < 3
                code = obj.settings.CDi_model;
            end
            
            compute_CDi = @() obj.compute_CDi_value(code);
            
            CDi = obj.compute_with_cache('CDi', override, compute_CDi, obj.settings.CDi_scaler);
        end
        
            function value = compute_CDi_value(obj, code)
                switch code
                    case obj.settings.codes.CDi_BASIC_SUBSONIC
                        e_osw = 0.85;
                        k1_sub = 1 / (pi * e_osw * obj.geom.wing.AR.v);
                        value = k1_sub * obj.cond.CL.v ^ 2;
    
                        % K1 = transonicMerge(@(in) k1_sub, ... 
                        %     @(in) in.geom.wing.AR.v * (in.cond.M.v.^2 - 1) ./ (4*in.geom.wing.AR.v * sqrt(in.cond.M.v.^2 - 1) -2) * cosd(in.geom.wing.le_sweep.v) , ...
                        %         in );
                                    
                    case obj.settings.codes.CDi_IGNORE
                        value = 0;
                        
                    otherwise
                        error("Code '%i' has no recognized definition for the CDi model.", code)
                end
            end

        function CDw = CDw(obj, override, code)
            if nargin < 2
                override = obj.settings.codes.OVER_NONE;
            end
            if nargin < 3
                code = obj.settings.CDw_model;
            end
            
            compute_CDw = @() obj.compute_CDw_value(code);
            
            CDw = obj.compute_with_cache('CDw', override, compute_CDw, obj.settings.CDw_scaler);
        end

            function value = compute_CDw_value(obj, code)
                switch code
                    case obj.settings.codes.CDw_BASIC
                        value = 0.02;
                        % E_WD = in.geom.fuselage.E_WD.v;
                        % M_CD0_max = 1/(cosd(in.geom.wing.le_sweep.v))^0.2;
                        % 
                        % % some imaginary values pop out sometimes
                        % CDW = real( transonicMerge(@(in) 0, ... 
                        %     @(in) (4.5 * pi / in.geom.ref_area.v) * ( in.geom.fuselage.max_area.v / in.geom.fuselage.length.v ) ^ 2 * ...
                        %         E_WD * ( 0.74 + 0.37 * cosd(in.geom.wing.le_sweep.v) ) * ( 1 - 0.3 * sqrt( in.cond.M.v - M_CD0_max )) , ...
                        %         in ) );
                                                    
                    case obj.settings.codes.CDw_IGNORE
                        value = 0;
                        
                    otherwise
                        error("Code '%i' has no recognized definition for the CDi model.", code)
                end
            end
    end
end