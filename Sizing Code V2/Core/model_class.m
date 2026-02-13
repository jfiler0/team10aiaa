classdef model_class < handle
    properties
        settings
        geom
        cond
        
        mem
    end
    
    methods
        % INITIALIZATION
        function obj = model_class(settings, geom, cond)
            obj.settings = settings;
            obj.geom = geom;
            obj.cond = cond;

            obj.clear_mem
        end

        %% HELPERS
        
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
        
        function value = transonicMerge(obj, sub_fun, sup_fun)
            % For functions that are ONLY a function mach number
            % Smoothes out the transition between subsonic and supersonic defensitions using splines

            % sup_fun and sub_fun must both be a function of a mach number and index vector. 
            % The mach number is run directly. The index allows the functions to work more generally with a vector of cases
            % to actually run through their respective functions
        
            transonic_range = obj.settings.transonic_range; % The range to do this 'merging'
            
            index_sub = obj.cond.M.v <= transonic_range(1);
            index_sup = obj.cond.M.v >= transonic_range(2);
            index_tran = logical( ~index_sub .* ~index_sup );
                I_tran_start = find(index_tran, 2, "first");
                I_tran_end = find(index_tran, 2, "last");

                index_tran_start = zeros(size(index_tran)); index_tran_end = index_tran_start;
                index_tran_start(I_tran_start) = 1; index_tran_end(I_tran_end) = 1;

            M_in_sub = obj.cond.M.v(index_sub);
            M_in_sup = obj.cond.M.v(index_sup);
            M_in_tran = obj.cond.M.v(index_tran);
        
            value_sub = sub_fun(M_in_sub, index_sub);
            value_sup = sup_fun(M_in_sup, index_sup);

            M_eps = obj.settings.transonic_M_eps;
            M_vec = [transonic_range(1)-M_eps transonic_range(1) transonic_range(2) transonic_range(2)+M_eps];
            
            value_spline_input = [ sub_fun(M_vec( 1:2), logical(index_tran_start) ), sup_fun( M_vec(3:4), logical(index_tran_end) ) ];

            value_trans = spline(M_vec, value_spline_input, M_in_tran);

            value = zeros(size(obj.cond.M.v));
            value(index_sub) = value_sub;
            value(index_sup) = value_sup;
            value(index_tran) = value_trans;
        end

        % function value = safe_cond_call(obj, name, indices)
        %     % Sometimes we need to call conditions and don't know if things have active indices or not
        %     % So, we want to check the length and then pass it back either as an array or as the scaler
        % 
        %     cond_vec = obj.cond.(name).v;
        %     len = length(cond_vec);
        % 
        %     if(len == 1) % Is a scaler. Just return it
        %         value = cond_vec;
        %     elseif(len ~= length(indices))
        %         error("Indices and condtion vector do not match.")
        %     else
        %         value = cond_vec(indices);
        %     end
        % end

        function clear_mem(obj)
            obj.mem = struct('CD0', [], 'CDi', [], 'CDw', [], 'CLa', [], 'COST', [], 'PROP', []);
        end

        %% ACUTUAL MODELS

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

                        % Could take CL out but is example of safe_cond_call
                        % sub_fun = @(M, I) M*0 + k1_sub * obj.safe_cond_call('CL', I) .^ 2;
                        % sup_fun = @(M, I) obj.safe_cond_call('CL', I) .^ 2 .* obj.geom.wing.AR.v .* (M.^2 - 1) ./ (4*obj.geom.wing.AR.v * sqrt(M.^2 - 1) -2) * cosd(obj.geom.wing.le_sweep.v);
                        % 
                        % value = obj.transonicMerge(sub_fun, sup_fun);

                        sub_fun = @(M, I) M*0 + k1_sub;
                        sup_fun = @(M, I) obj.geom.wing.AR.v .* (M.^2 - 1) ./ (4*obj.geom.wing.AR.v * sqrt(M.^2 - 1) -2) * cosd(obj.geom.wing.le_sweep.v);
    
                        k1 = obj.transonicMerge(sub_fun, sup_fun);

                        value = k1 .* obj.cond.CL.v .^2;
                                    
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

                        sub_fun = @(M, I) M*0 + 0; % Adding M*0 to the front forces it to form a vector

                        E_WD = obj.geom.fuselage.E_WD.v;
                        M_CD0_max = 1/(cosd(obj.geom.wing.le_sweep.v))^0.2;
                        sup_fun = @(M, I) (4.5 * pi / obj.geom.ref_area.v) * ( obj.geom.fuselage.max_area.v / obj.geom.fuselage.length.v ) ^ 2 * ...
                                E_WD * ( 0.74 + 0.37 * cosd(obj.geom.wing.le_sweep.v) ) * ( 1 - 0.3 * sqrt( M - M_CD0_max ));

                        value = obj.transonicMerge(sub_fun, sup_fun);
                                                    
                    case obj.settings.codes.CDw_IGNORE
                        value = 0;
                        
                    otherwise
                        error("Code '%i' has no recognized definition for the CDi model.", code)
                end
            end

        function CLa = CLa(obj, override, code)
            if nargin < 2
                override = obj.settings.codes.OVER_NONE;
            end
            if nargin < 3
                code = obj.settings.CLa_model;
            end
            
            compute_CLa = @() obj.compute_CLa_value(code);
            
            CLa = obj.compute_with_cache('CLa', override, compute_CLa, obj.settings.CLa_scaler);
        end

            function value = compute_CLa_value(obj, code)
                switch code
                    case obj.settings.codes.CLa_BASIC

                        sub_fun = @(M, I) deg2rad( 2*pi./sqrt(1-M.^2) );
                        sup_fun = @(M, I) deg2rad( 4./sqrt(M.^2-1) );

                        value = obj.transonicMerge(sub_fun, sup_fun);
                        
                    otherwise
                        error("Code '%i' has no recognized definition for the CLa model.", code)
                end
            end

        function COST = COST(obj, override, code)
            if nargin < 2
                override = obj.settings.codes.OVER_NONE;
            end
            if nargin < 3
                code = obj.settings.COST_model;
            end
            
            compute_COST = @() obj.compute_COST_value(code);
            
            COST = obj.compute_with_cache('COST', override, compute_COST, obj.settings.COST_scaler);
        end

            function value = compute_COST_value(obj, code)
                switch code
                    case obj.settings.codes.COST_BASIC
                        value = ( getcost(N2lb(obj.geom.weights.empty.v), obj.geom.input.kloc.v) / 500 )  / 1000000;
                        
                    otherwise
                        error("Code '%i' has no recognized definition for the COST model.", code)
                end
            end
        
        function PROP = PROP(obj, override, code)
            if nargin < 2
                override = obj.settings.codes.OVER_NONE;
            end
            if nargin < 3
                code = obj.settings.PROP_model;
            end
            
            compute_PROP = @() obj.compute_PROP_value(code);
            
            % The scalers are embeded in the equations now
            % [TA, TSFC, alpha]
            PROP = obj.compute_with_cache('PROP', override, compute_PROP, 1);
        end

            function PROP = compute_PROP_value(obj, code)
                switch code
                    case obj.settings.codes.PROP_BASIC
                        T_SL  = 288.15; %deg K
                        P_SL = 101330; % Pa
                        gamma = 1.4; 
                        TR = 1; % Note: Throttle Ratio ~1 for Fighter Aircraft (Sarojini + Mattingly)
                        
                        % Static and stagnation correction ratios
                        theta = obj.cond.T.v/T_SL; delta = obj.cond.P.v/P_SL; 
                        
                        theta_0 = theta .* (1 + (gamma-1)/2 * obj.cond.M.v.^2);
                        delta_0 = delta .* (1 + (gamma-1)/2 * obj.cond.M.v.^2).^(gamma/(gamma-1));
                        
                        % Lapse Ratios for Low-bypass Turbofans (See Mattingly, Aircraft Engine Design, 2e)
                        % Vectorized version using logical indexing - Thanks Claude
                        alpha_dry = zeros(size(theta_0));
                        alpha_AB = zeros(size(theta_0));
                        
                        % For theta_0 <= TR
                        idx_low = theta_0 <= TR;
                        alpha_dry(idx_low) = delta_0(idx_low) * 0.6; %Eqn. 2.45b
                        alpha_AB(idx_low) = delta_0(idx_low) * 1.0; % Eqn. 2.45a
                        
                        % For theta_0 > TR
                        idx_high = theta_0 > TR;
                        alpha_dry(idx_high) = 0.6 * delta_0(idx_high) .* (1 - 3.8 * (theta_0(idx_high) - TR) ./ theta_0(idx_high)); %Eqn. 2.45b
                        alpha_AB(idx_high) = delta_0(idx_high) .* (1 - 3.5 * (theta_0(idx_high) - TR) ./ theta_0(idx_high)); %Eqn. 2.45a
                        
                        % Thrusts (by definition of lapse rate)
                        F_th_mil = obj.geom.prop.T0_NoAB.v * alpha_dry; % (whatever unit thrust was passed with)
                        F_th_AB = obj.geom.prop.T0_AB.v * alpha_AB; % (whatever unit thrust was passed with)
                        
                        TSFC_mil = (0.9 + 0.30 * obj.cond.M.v) .* sqrt(theta); %hour^-1; Mattingly Eq.3.55a (No, these are lbm/lbf*hr)
                        TSFC_AB = (1.6 + 0.27 * obj.cond.M.v) .* sqrt(theta); %hour^-1; Mattingly Eq.3.55b (No, these are lbm/lbf*hr)
                    
                        TA = F_th_mil .* obj.cond.mil_throttle.v + obj.cond.ab_throttle.v .* ( F_th_AB - F_th_mil );
                        TSFC = TSFC_mil .* obj.cond.mil_throttle.v + obj.cond.ab_throttle.v .* ( TSFC_AB - TSFC_mil );
                            % TODO: Need to actually use cond.mil_throttle to get TSFC change with throttle
                        TSFC = lbmlbfhr_2_kgNs(TSFC); % Since the regression was not in metric units
                    
                        % Added in the max check and zeroing since it got weird for high mach at sea level
                        alpha = max(alpha_dry + obj.cond.ab_throttle.v .* (alpha_AB - alpha_dry), 0);
                        if(alpha < 0)
                            TA = 0;
                        end
                    
                        TA = TA * obj.settings.TA_scaler;
                        TSFC = TSFC * obj.settings.TSFC_scaler;

                        less_than_0 = TA < 0;
                        TA(less_than_0) = 0;
                        alpha(less_than_0) = 0;

                        PROP = [TA', TSFC', alpha'];
                        
                    otherwise
                        error("Code '%i' has no recognized definition for the COST model.", code)
                end
            end

    end
end