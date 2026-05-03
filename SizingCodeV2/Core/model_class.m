classdef model_class < handle
    properties
        settings
        geom
        cond
        
        mem
        prop_interp = NaN;
    end
    
    methods
        % INITIALIZATION
        function obj = model_class(settings, geom, cond)
            obj.settings = settings;
            obj.geom = geom;

            if nargin < 3
                cond = NaN; % Allow setting cond to NaN if not all arguments are given
            end

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

            if ~isstruct(obj.cond) % is NaN otherwise
                error("Model condition is not defined.")
            end
            
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
                result = compute_func() .* scaler.ask(obj.cond.M.v); % now has the potential to be a vector and has ask command
                
                % Check if we should write to cache
                should_write = (override ~= obj.settings.codes.OVER_NO_WRITE && ...
                               override ~= obj.settings.codes.OVER_NO_READ_NO_WRITE);

                % Check if the result was correctly patterned
                % width since the prop model is three high
                if width(result) ~= obj.cond.Nc.v
                    if size(result) ~= [1 1]
                        % The only input should be scaler values. We don't want to pattern it otherwise
                        error("Something very strange has happend")
                    end
                    result = result(ones(1,obj.cond.Nc.v)); % index replication to match
                end
                
                if obj.cond.Nc.v > 1
                    % Don't write if the condition input is a vector
                    should_write = false;
                end
                
                if should_write
                    obj.mem.(property_name) = result;
                end
            end
        end
        
        function value = transonicMerge(obj, sub_fun, sup_fun)
            transonic_range = obj.settings.transonic_range;
            M = obj.cond.M.v;
        
            % Fast paths - avoid spline entirely for pure subsonic/supersonic
            if all(M <= transonic_range(1))
                value = sub_fun(M, true(size(M)));
                return
            end
            if all(M >= transonic_range(2))
                value = sup_fun(M, true(size(M)));
                return
            end
        
            index_sub  = M <= transonic_range(1);
            index_sup  = M >= transonic_range(2);
            index_tran = ~index_sub & ~index_sup;
        
            value = zeros(size(M));
        
            if any(index_sub)
                value(index_sub) = sub_fun(M(index_sub), index_sub);
            end
            if any(index_sup)
                value(index_sup) = sup_fun(M(index_sup), index_sup);
            end
            if any(index_tran)
                I_tran_start = find(index_tran, 2, 'first');
                I_tran_end   = find(index_tran, 2, 'last');
                index_tran_start = false(size(index_tran));
                index_tran_end   = false(size(index_tran));
                index_tran_start(I_tran_start) = true;
                index_tran_end(I_tran_end)     = true;
        
                M_eps = obj.settings.transonic_M_eps;
                M_vec = [transonic_range(1)-M_eps, transonic_range(1), ...
                         transonic_range(2),       transonic_range(2)+M_eps];
                value_spline_input = [ sub_fun(M_vec(1:2), index_tran_start), ...
                                        sup_fun(M_vec(3:4), index_tran_end) ];
                value(index_tran) = spline(M_vec, value_spline_input, M(index_tran));
            end
        end

        function clear_mem(obj)
            obj.mem = struct('CD0', [], 'CDi', [], 'CDw', [], 'CLa', [], 'COST', [], 'PROP', [], 'CDp', [], 'SpotFactor', []);
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
            
            CD0 = obj.compute_with_cache('CD0', override, compute_CD0, obj.settings.scalers.CD0_scaler);
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

                    case obj.settings.codes.CD0_FRICTION
                        value = fortran_cd0(obj.geom, obj.cond.M.v, obj.cond.h.v);
                        
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
            
            CDi = obj.compute_with_cache('CDi', override, compute_CDi, obj.settings.scalers.CDi_scaler);
        end
        
            function value = compute_CDi_value(obj, code)
                switch code
                    case obj.settings.codes.CDi_BASIC_SUBSONIC

                        e_osw = 4.61 * (1 - 0.045 * (obj.geom.wing.AR.v)^0.68 ) * cosd(obj.geom.wing.average_sweep.v)^0.15 - 3.1;
                        e_osw = min(e_osw, 0.85); % Since at low aspect ratios it starts to make no sense

                        k1_sub = 1 / (pi * e_osw * obj.geom.wing.AR.v);

                        sub_fun = @(M, I) M*0 + k1_sub;
                        sup_fun = @(M, I) obj.geom.wing.AR.v .* (M.^2 - 1) ./ (4*obj.geom.wing.AR.v * sqrt(M.^2 - 1) -2) * cosd(obj.geom.wing.average_sweep.v);
    
                        k1 = obj.transonicMerge(sub_fun, sup_fun);

                        value = k1 .* obj.cond.CL.v .^2;
                                    
                    case obj.settings.codes.CDi_IGNORE
                        value = 0;

                    case obj.settings.codes.CDi_IDRAG
                        value = zeros([1 obj.cond.Nc.v]);
                        for i = 1:obj.cond.Nc.v
                            value(i) = real( fortran_cdi(obj.geom, obj.cond.CL.v(i)) ); % real since we sometimes end up with imaginary values
                        end
                        
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
            
            CDw = obj.compute_with_cache('CDw', override, compute_CDw, obj.settings.scalers.CDw_scaler);
        end

            function value = compute_CDw_value(obj, code)
                switch code
                    case obj.settings.codes.CDw_BASIC

                        sub_fun = @(M, I) M*0 + 0; % Adding M*0 to the front forces it to form a vector

                        E_WD = obj.geom.fuselage.E_WD.v;
                        M_CD0_max = 1/(cosd(obj.geom.wing.average_sweep.v))^0.2;
                        sup_fun = @(M, I) (4.5 * pi / obj.geom.ref_area.v) * ( obj.geom.fuselage.max_area.v / obj.geom.fuselage.length.v ) ^ 2 * ...
                                E_WD * ( 0.74 + 0.37 * cosd(obj.geom.wing.average_sweep.v) ) * ( 1 - 0.3 * sqrt( M - M_CD0_max ));

                        value = obj.transonicMerge(sub_fun, sup_fun);
                                                    
                    case obj.settings.codes.CDw_IGNORE
                        value = 0;
                        
                    otherwise
                        error("Code '%i' has no recognized definition for the CDw model.", code)
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
            
            CLa = obj.compute_with_cache('CLa', override, compute_CLa, obj.settings.scalers.CLa_scaler);
        end

            function value = compute_CLa_value(obj, code)
                switch code
                    case obj.settings.codes.CLa_BASIC

                        sub_fun = @(M, I) deg2rad( 2*pi./sqrt(1-M.^2) ); % flat plate with prandtl-gluaret
                        sup_fun = @(M, I) deg2rad( 4./sqrt(M.^2-1) ); % ideal supersonic

                        value = obj.transonicMerge(sub_fun, sup_fun);

                    case obj.settings.codes.CLa_RAYMER % compensates for chaning wing sweep

                        fuse_area_est = 0.5 * obj.geom.fuselage.length.v * obj.geom.fuselage.diameter.v;
                        A_ratio = (2 * obj.geom.wing.area.v + fuse_area_est) / obj.geom.ref_area.v;
                        A = obj.geom.wing.AR.v;

                        beta = @(M) 1-M.*M;
                        eta = @(M) 2*pi * beta(M) / (2*pi);

                        sub_fun = @(M, I) A_ratio * 2 * pi * (2*A) ./ ( 2 + sqrt(4 + A^2 * beta(M).^2 .* ( 1 + tand(obj.geom.wing.average_qrtr_chd_sweep.v)^2 ./ beta(M).^2 ) ./ eta(M).^2) );
                        sup_fun = @(M, I) deg2rad( 4./sqrt(M.^2-1) ); % ideal supersonic

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
            
            COST = obj.compute_with_cache('COST', override, compute_COST, obj.settings.scalers.COST_scaler);
        end

            function value = compute_COST_value(obj, code)
                switch code
                    case obj.settings.codes.COST_BASIC
                        value = ( getcost(N2lb(obj.geom.weights.empty.v), obj.geom.input.kloc.v) / 500 )  / 1000000;

                    case obj.settings.codes.COST_XANDERSCRIPT
                        % the crazy cost estimation
                        cost_struct = xanderscript_modified(obj.geom, false, false);
                        value = cost_struct.unit_cost / 1E6; % convert to million
                        
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
            PROP = obj.compute_with_cache('PROP', override, compute_PROP, correction_factor(0, 1)); % add a correction factor of 1 since they are applied elsewhere for prop
        end
            
            % Note that TA is scaled
            function PROP = compute_PROP_value(obj, code)
                switch code
                    case obj.settings.codes.PROP_BASIC % scaled throttle as linear on TSFC
                        [TA, TSFC] = max_prop_info(obj.cond, obj.geom.prop.T0_NoAB.v, obj.geom.prop.T0_AB.v, obj.settings); % no longer tracking alpha
                        % gives TA, TSFC, and alpha for military (first row) and max ab (second row)
                    
                        TA = TA(1) .* obj.cond.mil_throttle.v + obj.cond.ab_throttle.v .* ( TA(2) - TA(1) );
                        TSFC = TSFC(1) .* obj.cond.mil_throttle.v + obj.cond.ab_throttle.v .* ( TSFC(2) - TSFC(1) );

                    case obj.settings.codes.PROP_HOOK % estimate of the power hook nonlinear tsfc/throttle: https://www.fzt.haw-hamburg.de/pers/Scholz/arbeiten/TextBensel.pdf
                        [TA, TSFC] = max_prop_info(obj.cond, obj.geom.prop.T0_NoAB.v, obj.geom.prop.T0_AB.v, obj.settings); % no longer tracking alpha
                        % gives TA, TSFC, and alpha for military (first row) and max ab (second row)
                    
                        % thrust still scales linearly with throttle
                        try
                            TA = TA(1, :) .* obj.cond.mil_throttle.v + obj.cond.ab_throttle.v .* ( TA(2, :) - TA(1, :) );
                        catch
                            disp("catch")
                        end

                        % tsfc is a hook with there being a set min from 0 - 0.9. From 0.9-1 it is linear between max ab and military
                        TSFC_min_throttle = 0.4; % min occurs at 40% throttle -> BIG INPUT TO HOW EFFICENT THE ENGINE IS
                        throttle = obj.cond.throttle.v;
                        ab_fil = throttle > 0.9; % obj.cond.mil_throttle.v  should be 1
                        mil_fil = ~ab_fil;
                        
                        TSFC_mil = TSFC(1, :);
                        TSFC_ab = TSFC(2, :);
                        TSFC = zeros(size(TA)); % get the right size

                        TSFC(ab_fil) = TSFC_mil(ab_fil) + obj.cond.ab_throttle.v(ab_fil) .* ( TSFC_ab(ab_fil) - TSFC_mil(ab_fil) );

                        TSFC_scaler = 0.3722 * (throttle / TSFC_min_throttle).^2 - 0.742 * (throttle / TSFC_min_throttle) + 1.37; % this is right as TSFC reltive to the min throttle
                        TSFC_scaler = TSFC_scaler / ( 0.3722 * (0.9 / TSFC_min_throttle).^2 - 0.742 * (0.9 / TSFC_min_throttle) + 1.37 ); % this converts to relative to the military throttle 0.9

                        TSFC(mil_fil) = TSFC_mil(mil_fil) .* TSFC_scaler(mil_fil);

                    case obj.settings.codes.PROP_NPSS
                        if ~isstruct(obj.prop_interp)
                            obj.prop_interp = load_engine_lookup(obj.geom.prop.engine.v);
                        end

                        TA = obj.prop_interp.TA(obj.cond.M_face.v, obj.cond.h.v, obj.cond.throttle.v) * obj.geom.prop.num_engine.v; % NUM ENGINE
                        TSFC = obj.prop_interp.TSFC(obj.cond.M_face.v, obj.cond.h.v, obj.cond.throttle.v);

                    case obj.settings.codes.PROP_HYBRID
                        [TA, ~] = max_prop_info(obj.cond, obj.geom.prop.T0_NoAB.v, obj.geom.prop.T0_AB.v); % no longer tracking alpha
                        % gives TA, TSFC, and alpha for military (first row) and max ab (second row)
                    
                        TA = TA(1) .* obj.cond.mil_throttle.v + obj.cond.ab_throttle.v .* ( TA(2) - TA(1) );

                        if ~isstruct(obj.prop_interp)
                            obj.prop_interp = load_engine_lookup(obj.geom.prop.engine.v);
                        end
                        TSFC = obj.prop_interp.TSFC(obj.cond.M_face.v, obj.cond.h.v, obj.cond.throttle.v);
                        
                    otherwise
                        error("Code '%i' has no recognized definition for the COST model.", code)
                end

                % seperating out the checks since they are the same across models

                TA = TA .* obj.settings.scalers.TA_scaler.ask(obj.cond.M.v);
                TSFC = TSFC .* obj.settings.scalers.TSFC_scaler.ask(obj.cond.M.v);

                less_than_0 = TA < 0;
                TA(less_than_0) = 0;

                PROP = [TA; TSFC];
            end
        
        function CDp = CDp(obj, override, code)
            if nargin < 2
                override = obj.settings.codes.OVER_NONE;
            end
            if nargin < 3
                code = obj.settings.CDp_model;
            end
            
            compute_CDp = @() obj.compute_CDp_value(code);
            
            CDp = obj.compute_with_cache('CDp', override, compute_CDp, obj.settings.scalers.CDp_scaler);
        end

            function value = compute_CDp_value(obj, code)
                switch code
                    case obj.settings.codes.CDp_CONST
                        value = 0;
                        for i = 1:length(obj.geom.stores)
                            store = obj.geom.stores(i);
                            value = value + store.frontal_area.v * obj.settings.CDp_CONST_CD / obj.geom.ref_area.v;
                        end
                    case obj.settings.codes.CDp_WAVE
                        if(isempty(obj.geom.stores))
                            value = 0;
                            return
                        end
                    
                        % Vectorized field extraction from struct array
                        frontal_areas  = [obj.geom.stores.frontal_area];
                        frontal_vals   = [frontal_areas.v];
                    
                        lengths        = [obj.geom.stores.length];
                        length_vals    = [lengths.v];
                    
                        diameters      = [obj.geom.stores.diameter];
                        diameter_vals  = [diameters.v];

                        area_scale = frontal_vals / obj.geom.ref_area.v;
                    
                        % Compute per-store constants (no Mach dependency)
                        sub_vals      = obj.settings.CDp_CONST_CD;
                        fineness_terms = (9 * pi^2 ./ (8 * (length_vals ./ diameter_vals).^2));
                        sup_vals      = sub_vals + fineness_terms;
                    
                        % Sum across all stores — now just two scalar constants
                        total_sub = sum(sub_vals.*area_scale);
                        total_sup = sum(sup_vals.*area_scale);
                    
                        % Single transonicMerge call on the summed scalars
                        sub_fun = @(M, I) M*0 + total_sub;

                        M_ref = 1.5;
                        sup_fun = @(M, I) obj.settings.scalers.CDp_EW_scaler.ask(M) .* total_sup * sqrt(M_ref^2 - 1) ./ sqrt(M.^2 - 1);
                        value = obj.transonicMerge(sub_fun, sup_fun);

                    otherwise
                        error("Code '%i' has no recognized definition for the CDp model.", code)
                end
            end

        function SpotFactor = SpotFactor(obj, override, code)
            if nargin < 2
                override = obj.settings.codes.OVER_NONE;
            end
            if nargin < 3
                code = obj.settings.SpotFactor_model;
            end
            
            compute_SpotFactor = @() obj.compute_SpotFactor_value(code);
            
            SpotFactor = obj.compute_with_cache('SpotFactor', override, compute_SpotFactor, obj.settings.scalers.SpotFactor_scaler);
        end

            function value = compute_SpotFactor_value(obj, code)
                switch code
                    case obj.settings.codes.SpotFactor_BASIC
                        proj_area = obj.geom.wing.fold_area.v + obj.geom.fuselage.area.v;
                        value = proj_area / obj.settings.spot_factor_reference;

                    otherwise
                        error("Code '%i' has no recognized definition for the SpotFactor model.", code)
                end
            end
    end
end