classdef planeObj
    % MATLAB classes are quite powerful. They enable you to pass and update a large amount of information without needing to keep track of
    % many variables and worrying about matching syntax across external function. The planeObj class holds all the geometric, aerodynamic,
    % and mission information about a plane design. This class does not include optimization or does it solve for the actual geometry to do
    % anything. However, it will tell you how well specific set of parameters performs.

    % In other words, this class holds all the pure analysis calls when it comes to quantifying how well a design performs.

    % When combined with a set of constraints and an optimization function this will identify viable designs. This can either be used to
    % apply a fixed W0 and fuselage parameters and solve for a wing. Or see how fixing the wing sweep influences the optimial design. All
    % that fun will use the analyisis setup in the plane Obj function.

    % Notice that functions inside the class (as long as you pass in obj by calling it as obj.fun) will have access to all the properties
    % defined in the properties function below and all the methods in the methods section.

    properties
        % Whenever you start a class object like this, you have to tell MATLAB every obj.VARIABLE type variables exist
        name

        % Parameters that should be optimized (inputs)
        WE % Empty weight
        MTOW % Max takeoff weight
        Lambda_LE % deg
        Lambda_TE % deg
        c_avg % m
        tr % taper ratio

            % Tail Parameters
            VH % Horizontal Tail Volume Ratio
            VV % Vertical Tail Volume Ratio

        % How can these become inputs...
        L_fuselage % m
        A_max % m2
        A_0 % m2
        E_WD % no idea what this is
        x_rootchord % distance of beginning of leading edge of wing from tip of nose 
        g_limit

        fixed_input

        % Parameters when missions and loadouts are applied
        CD0_Payload
        loadout
        W_P % payload weight (weapon type stores)
        W_Tanks % external fuel tank EMPTY weight

        % Parameters that remain fixed (need to edit the input function if you want them moved into the deisgn space)
        type % Name of the regrssion to use in Raymer for We/W0
        raymer % Stores raymer coefficents
        KLOC % kilo lines of code
        num_engine
        engineData % [T0_NoAB, T0_AB]
        W_F % fixed weight
        a0 % deg
        cl_alpha = 0.1; % foil lift sope
        tc = 0.04; % airfoil thickness
        max_alpha % max angle of attack in deg
        mach_range % vector [min mach, max mach] for interpolation range
        transonic_range % spline interpolation range
        alt_range % vector [min alt, max alt] in meters

        % Parameters that are derived
        c_t % m
        c_r % m
        span % m
        semi_span % m
        AR
        S_wing % m2
        S_ref % m2
        MAC_wing % mean aerodynamic chord
        y_MAC_wing % Y location of MAC; distance of MAC out the right wing from the centerline 
        x_MAC_wing % X location of MAC; distance of MAC from tip of nose 
        Lambda_qc % deg
        S_wet  % m2
        e_notoswald
        e_osw       
        k1_sub
        k2_sub
        CD0_Body
        CD0
        M_CD0_max % Although it is really max wave drag (parasite drag is friction)
        D % m (fuselage diameter currently assumed to be circular and taken from A_max)
        Lambda_max_t % max
        S_exposed % m2
        F % lift parameter
        S_flapped  % m2
        Delta_flap_param % effects the amount of extra lift gained
        Lambda_HL % deg
            
            % Tail parameters that are derived
                % Horizontal
                S_h % Planform Area
                l_ht % Tail arm
                v_hc % Airfoil Thickness
                AR_h % Aspect Ratio
                lam_h % Taper ratio
                c_t_h % tip chord
                c_r_h % root chord
                MAC_h % mean aerodynamic chord
                b_h % span
                LAM_h % sweep angle
                GAM_h % dihedral angle
                inc_h % angle of incidence

                % Vertical
                S_v % Planform Area
                l_vt % Tail arm
                v_tc % Airfoil Thickness
                AR_v % Aspect Ratio
                lam_v % Taper ratio
                c_t_v % tip chord
                c_r_v % root chord
                MAC_v % mean aerodynamic chord
                b_v % span
                LAM_v % sweep angle
                GAM_v % dihedral angle
                inc_v % angle of incidence

        % filling out these interpolation function helps considerably with speed
        CLa_interp
        CDW_interp
        K1_interp
        K2_interp
    end

    methods
        
        %% Primary class defenition functions (used on creation and updates)
        function obj = planeObj(fixed_input, name, WE, Lambda_LE, c_r, c_t, span, num_engine, engine, W_F) 
            % Note it returns the obj variable to be used. Use as plane = planeObj(...)
            obj.name = name;

            %% Assign inputs
            obj.WE = WE; % Newtons
            obj.Lambda_LE = Lambda_LE; % deg
            obj.c_r = c_r;
            obj.c_t = c_t;
            obj.span = span;
            obj.num_engine = num_engine;
            
            %% Bunch of fixed parameters (***)
            obj.L_fuselage = fixed_input.L_fuselage; % m
            obj.A_max = fixed_input.A_max; 
            obj.A_0 = 0; % m2
            obj.E_WD = 2.2; % *** Still don't know what this is
            obj.g_limit = fixed_input.g_limit; % Just fixing for performance code
            obj.fixed_input = fixed_input;

            % Storing the raymer coefficents is much faster than reading the table every loop
            obj.type = fixed_input.type; % For regression lookup
            obj.raymer = struct(); % Raymer coefficents
            [obj.raymer.A, obj.raymer.C] = getRaymerCoefficents(obj.type);
            obj.KLOC = fixed_input.KLOC;

            % Parameters depending on loadout
            obj.W_P = 0; % payload - set when loadout is applied
            obj.CD0_Payload = 0;

            % Parameters that remain fixed
            obj.engineData = engine_getData(engine); % Saves key engien data as an array [T0_NoAB, T0_AB]
            obj.W_F = W_F; % fixed weight
            
            obj.a0 = -1; % deg (zero lift aoa)
            obj.cl_alpha = 0.1; % foil lift sope
            obj.tc = 0.04; % airfoil thickness
            obj.max_alpha = fixed_input.max_alpha; % deg 

            obj.mach_range = [0.2 3]; % Anything above 2 and prop equations go wild
            obj.transonic_range = [0.95 1.3];
            obj.alt_range = [0 ft2m(60000)];

            obj = obj.updateDerivedVariables(); %% Fills in the remaining constructor variables we need
        end

        function obj = updateWE(obj, MTOW)
            % Function to let you adjust empty weight from a new takeoff weight (invese of below)
            obj.MTOW = MTOW;
            obj.WE = MTOW * obj.raymer.A * N2lb(obj.MTOW)^(obj.raymer.C);
        end
        
        function obj = updateDerivedVariables(obj)
           
            % empty_weight_fraction = obj.WE / obj.MTOW = 2.34*N2lb(obj.MTOW)^(-0.13) ; % Use historical data
            % obj.WE = obj.MTOW * 2.34 * N2lb(obj.MTOW)^(-0.13)
            % obj.MTOW = lb2N( ( N2lb(obj.WE) / 2.34)^(1/0.87) );
            obj.MTOW = obj.fixed_input.MTOW_Scalar * lb2N( ( N2lb(obj.WE) / obj.raymer.A )^(1 / (1 + obj.raymer.C) ) );

            %% Standard Wing Geometry Stuff
            obj.c_avg = 0.5*(obj.c_t + obj.c_r); % Average chord
            obj.tr = obj.c_t / obj.c_r; % Taper Ratio
            obj.semi_span = obj.span / 2;
            obj.Lambda_TE =  atand( tand(obj.Lambda_LE) - 2*(obj.c_r - obj.c_avg) / obj.semi_span );
            obj.AR = obj.span / obj.c_avg;
            obj.S_wing = obj.span*obj.c_avg;
            obj.S_ref = obj.S_wing; % Typical defenition for reference area
            
            %% Tail Geometry - HW 7 S&C 
            xwing = 17.79; % beginning of root chord from nose
                
            obj.MAC_wing = (2/3)*obj.c_r*(1 + obj.tr + obj.tr.^2)/(1+obj.tr);
            obj.y_MAC_wing = (obj.span/6)*((1 + 2*obj.tr)/(1+obj.tr));
            obj.x_MAC_wing = obj.x_rootchord + obj.y_MAC_wing*tan(deg2rad(obj.Lambda_LE));

            %% Homework 4 - Drag
            obj.Lambda_qc = atand(tand(obj.Lambda_LE) - ( 1 - obj.tr)/(obj.AR*(1+obj.tr))); % Compute the quarter-chord sweep angle (deg) - HW4
            
            c = -0.1289; d = 0.7506; % Regression from somewhere lol
            obj.S_wet = obj.fixed_input.SWET_Scalar * 0.09290304*(10^c  * N2lb(obj.WE)^d); % Converting S_wet in ft and W0 in lb
            Cf = 0.0035; % For fighters?
            CD_min = Cf * obj.S_wet/obj.S_ref;
            
            % Induced Drag Polar
            obj.e_notoswald = 2/(2 - obj.AR + sqrt(4 + obj.AR^2 * (1 + (tand(obj.Lambda_LE))^2))); % Lambda_LE, not Lmabda_max
            obj.e_osw = (4.61 * (1-0.045*obj.AR^0.68)) * cosd(obj.Lambda_LE)^0.15 - 3.1; %MUST USE RAYMER 12.50
            % *** May want substitution for low swept wings

            %CL_alpha - for the wing?
            CL_alpha_wing = obj.cl_alpha/(1 + 57.3 * obj.cl_alpha/(pi * obj.e_notoswald * obj.AR));
            CL_min_D = CL_alpha_wing*-obj.a0/2;
            
            % Can reuse these later
            obj.k1_sub = 1 / (pi * obj.e_osw* obj.AR);
            obj.k2_sub = -2 * obj.k1_sub * CL_min_D;
            
            % CD_0
            obj.CD0_Body = CD_min + obj.k1_sub*CL_min_D^2 + obj.k2_sub*CL_min_D; % Actually has k2 term
            obj.CD0 = obj.CD0_Body + obj.CD0_Payload;

            obj.M_CD0_max = 1/(cosd(obj.Lambda_LE))^0.2; % The only supersonic drag variable that is not dependent on Cl or M

            %% Homework 4 - Lift
            obj.Lambda_max_t = ( obj.Lambda_LE - obj.Lambda_TE )/2; % *** Feel like this should be addition instead for some reason
            obj.D = 2*sqrt(obj.A_max/pi); % Assuming roughly circular cross section to get fuselage diameter/width
            obj.S_exposed = obj.S_wing * 1.3; % *** Trying to account for body lift/strakes/tail anything not in here
            obj.F = 1.07 * (1 + obj.D/obj.span)^2; % Lift Factor
            obj.F = 1; % *** Needs to be fixed

            obj.S_flapped = obj.S_wing * 0.6; % *** Obviously has a big impact on landing CL
            obj.Delta_flap_param = 0.9; % Factor depending on the type of flap
            obj.Lambda_HL = obj.Lambda_TE; % *** What is the actual way to calculate the hinge line

            %% Interpolants
            M_vec = linspace(obj.mach_range(1), obj.mach_range(2), 100); % Can change last number to increase/decrease resolution
            obj.CLa_interp = obj.buildCLaInterpolant(M_vec);
            obj.CDW_interp = obj.buildCDWInterpolant(M_vec);
            obj.K1_interp = obj.buildK1Interpolant(M_vec);
            obj.K2_interp = obj.buildK2Interpolant(M_vec);

        end

        function obj = applyLoadout(obj, loadout)
            % loadout variable must compre from buildLoadout function
            obj.W_P = loadout.weight_weapons;
            obj.W_Tanks = loadout.weight_tanks_empty;
            obj.CD0_Payload = loadout.CD0;
            obj.CD0 = obj.CD0_Body + obj.CD0_Payload;
            obj.loadout = loadout;
        end
        
        %% Iterpolation creators for updateDerviedVariables
        function CLa_interp = buildCLaInterpolant(obj, M_vec)
            % *** Where are these suppose to go?
            %beta = sqrt((1-M_vec.^2)); %MACH - real to try try and fix things above M 1 (*** is this fine)
            % eta = rad2deg(obj.cl_alpha) ./ (2*pi./beta); % Airfoil Efficiency - MACH

            % CL_alpha_sub = (2*pi*obj.AR) ./ (2+ sqrt(4 + (obj.AR.^2 * beta.^2)/eta.^2 .* (1 + ( tand(obj.Lambda_max_t).^2 )./beta.^2) ) ) * (obj.S_exposed/obj.S_ref)* obj.F; % Ssurface = Sref
            CL_alpha_sub = deg2rad( 2*pi./sqrt(1-M_vec.^2) ); % The difference between these is pretty big ***
            CL_alpha_supersonic = deg2rad( 4./sqrt(M_vec.^2-1) );

            CLa = obj.generateTransonicSpline(CL_alpha_sub, CL_alpha_supersonic, M_vec);
            CLa_interp = griddedInterpolant(M_vec, CLa, 'linear');
        end
        
        function CDW_interp = buildCDWInterpolant(obj, M_vec)
            CD_wave = obj.fixed_input.CDW_Scalar * 4.5 * pi / obj.S_ref * ((obj.A_max - obj.A_0)/obj.L_fuselage)^2 * obj.E_WD * (0.74 + 0.37 * cosd(obj.Lambda_LE)) * (1 - 0.3*sqrt(M_vec - obj.M_CD0_max));
            CDW = obj.generateTransonicSpline(zeros(size(CD_wave)), CD_wave, M_vec);
            CDW_interp = griddedInterpolant(M_vec, CDW, 'linear');
        end
        
        function K1_interp = buildK1Interpolant(obj, M_vec)
            k1_sup = obj.AR * (M_vec.^2 - 1) ./ (4*obj.AR*sqrt(M_vec.^2 - 1) -2) * cosd(obj.Lambda_LE); % supersonic range
            k1 = obj.generateTransonicSpline(obj.k1_sub * ones(size(k1_sup)), k1_sup, M_vec);
            K1_interp = griddedInterpolant(M_vec, k1, 'linear');
        end
        
        function K2_interp = buildK2Interpolant(obj, M_vec)
            k2_sup = zeros(size(M_vec));
            k2 = obj.generateTransonicSpline(obj.k2_sub * ones(size(M_vec)), k2_sup, M_vec);
            K2_interp = griddedInterpolant(M_vec, k2, 'linear');
        end

        %% Helper function for iterpolations (needed for transonic regime)
        function out_vec = generateTransonicSpline(obj, subsonic_range, supersonic_range, M_vec)
            subsonic_range(obj.transonic_range(1) < M_vec) = NaN;
            supersonic_range(obj.transonic_range(2) > M_vec) = NaN;
            range = max(subsonic_range, supersonic_range);

            x = find(~isnan(range));
            y = range(x);

            out_vec = interp1(x, y, 1:numel(range), 'spline', 'extrap');
        end
        
        %% Core analyisis functions
        function [CL_max_clean, CL_max_flapped, CLa] = calcCL(obj, M)
            CLa = obj.CLa_interp(M);
            CL_max_clean = CLa * (obj.max_alpha - obj.a0);
            CL_max_flapped = CL_max_clean + obj.Delta_flap_param *obj.S_flapped/obj.S_ref * cosd(obj.Lambda_HL);
        end
        
        function [CD, CD0, CDi, CDW] = calcCD(obj, CL, M)
            CD0 = obj.CD0;
            CDi = obj.K1_interp(M) * CL^2 + obj.K2_interp(M) * CL;
            CDW = obj.CDW_interp(M);
            CD = CD0 + CDi + CDW;
        end
        
        function [TA, TSFC, alpha, mdotf] = calcProp(obj, M, h, AB_perc)
            [TA, TSFC, alpha] = engine_query(obj.engineData, M, h, AB_perc);
            TA = TA * obj.num_engine;
            mdotf = TA * TSFC;
        end
        
        function trimCL = calcTrimCL(obj, h, M, W)
            % Can simulate higher load factors by just multiplying W

            [~, CL_max_flapped, ~] = obj.calcCL(M);

            [q, ~, ~, ~] = metricFreestream(h, M);

            trimCL = W / (q * obj.S_ref); % n = 1
            if( trimCL > CL_max_flapped )
                trimCL = NaN; % So that we can easily catch areas that are not trimmable
            end
        end
        
        function stallSpeed = calcStallSpeed(obj, h, W)
            [~, a, ~, rho, ~] = queryAtmosphere(h, [0 1 0 1 0]);
            % For some reason an imaginary comp shows up so real helps
            f = @(V) real( W - get_output_at_index(@() obj.calcCL(V / a), 2) * obj.S_ref * rho * V^2 ); % I don't know why @() is required but it does work
            x0 = 0.5 * a;
            stallSpeed = fzero(f , x0);
        end
        
        function takeoffSpeed = calcTakeoffSpeed(obj, h, W)
            % Can vary h to see change with alt. W is likely obj.MTOW
            takeoffSpeed = 1.2 * obj.calcStallSpeed(h, W);
        end
        
        function landingSpeed = calcLandingSpeed(obj, h, W)
            % Can vary h to see change with alt.
            landingSpeed = 1.3 * obj.calcStallSpeed(h, W);
        end
        
        % Note the absolute max turn rate seems to always be at sea level
        function [turn_rate, n] = getMaxTurn(obj, h, M, W)
            % Input: h (alt) = m, M (mach number), W (weight) = N, g_limit
            % Output: turn_rate = deg/s, n (load factor)
            % Example: [turn_rate, n] = f18.getMaxTurn(1000, 0.8, f18.MTOW)

            % g_limit will cap the load factor. If you want it to be uncapped you can enter inf

            [CL_max_clean, ~, ~] = calcCL(obj, M);
            [q, V, ~, ~] = metricFreestream(h, M);
            L_max = q * CL_max_clean * obj.S_ref;
            n = min( L_max / W, obj.g_limit);
            turn_rate = rad2deg( n * 9.8051 / V);
            
        end
        
        function [excessPower, speed, mach] = getMaxTurnOverall(obj, AB_perc, M_guess)
            % If the guess was not provided use fall back (should be standard)
            % This is needeed in calcMaxAltHelper for stability
            if(nargin < 5)
                M_guess = 0.5;
            end

            [~, a, ~, ~, ~] = queryAtmosphere(h, [0 1 0 0 0]);
            fun = @(V) -obj.calcExcessPower(h, V / a, W, AB_perc); % negative for maximization
            opts = optimset('Display','off','TolX',1e-3,'MaxFunEvals',200);
        
            % Solve for max excess power speed
            [speed, excessPower] = fminsearch(fun, M_guess * a, opts);
            mach = speed / a;
            excessPower = -excessPower;
        end

        function cost = calcUnitCost(obj)
            % Exports cost in the millions per aircraft
            cost= ( getcost(N2lb(obj.WE), obj.KLOC) / 500 )  / 1000000; % Divide by 500 since getcost assumes 500 aircraft in the program, and convert to mil
        end

        function area = calcFoldedWingProjection(obj, fold_ratio)
            % fold_ratio = 0.1 -> 10% of the wing is folded

            % The FA18E has a wingspan of 40.4 ft and when folded goes to 27.5. Thus for it, fold_ratio = 1 - 27.5 / 40.4 = 0.3193
            % We then get a area of 49.1823 when projected which is now the spot facto = 1 reference

            fold_span = obj.span * ( 1 - fold_ratio);
            fold_tipChord = obj.c_r + (obj.c_r - obj.c_t) * ( 1 - fold_ratio);
            area = fold_span * ( fold_tipChord + obj.c_r) / 2;
        end
        
        function spotFactor = calcSpotFactor(obj, fold_ratio)
            % fold_ratio = 0.1 -> 10% of the wing is folded
            % f18.calcSpotFactor(0.3193)
            area = obj.calcFoldedWingProjection(fold_ratio);
            spotFactor = area / 51.033; % From F18 comparison. Setting it to 1 when area matches
        end
       
        function excessPower = calcExcessPower(obj, h, M, W, AB_perc)
            % IN: h (alt) = m , M (mach number), W (current weight) = N, AB_perc
            % OUT: excessPower = m/s
           
            [q, V, ~, ~] = metricFreestream(h, M);
            trimCL = obj.calcTrimCL(h, M, W);
            [CD, ~, ~, ~] = obj.calcCD(trimCL, M);

            [TA, ~, ~, ~] = obj.calcProp(M, h, AB_perc);

            excessPower = V * (TA - CD * obj.S_ref * q) / W;

        end
        
        % Note the absolute excess power seems to always be at sea level
        function [excessPower, speed, mach] = calcMaxExcessPower(obj, h, W, AB_perc, M_guess)
            % If the guess was not provided use fall back (should be standard)
            % This is needeed in calcMaxAltHelper for stability
            if(nargin < 5)
                M_guess = 0.5;
            end

            [~, a, ~, ~, ~] = queryAtmosphere(h, [0 1 0 0 0]);
            fun = @(V) -obj.calcExcessPower(h, V / a, W, AB_perc); % negative for maximization
            opts = optimset('Display','off','TolX',1e-3,'MaxFunEvals',200);
        
            % Solve for max excess power speed
            [speed, excessPower] = fminsearch(fun, M_guess * a, opts);
            mach = speed / a;
            excessPower = -excessPower;
        end
        
        function [climbRate, climbAngle, climbSpeed] = calcMaxClimbRate(obj, h, W, AB_perc)
            [climbRate, climbSpeed] = obj.calcMaxExcessPower(h, W, AB_perc);

            if(climbRate > climbSpeed) % The aircraft can climb directly vertical
                climbAngle = 90;
            else
                climbAngle = atand(climbRate / climbSpeed);
            end
            if(isnan(climbRate))
                climbSpeed = NaN; %Otherwise it will return even if it is not a viable flight condition
            end
        end
        
        function [maxAlt, maxAltMach, excessPower] = calcMaxAlt(obj, W, AB_perc)
            climb_rate_min = 0.508; % m/s -> this comes from the standard 100 ft / min excess power req for service ceiling 
            mach_save = 0.5; % Tracking mach between iterations is an enormous help for speed and stability

            % Ode to matlab nested functions in new versions
            function diff = helper(h)
                [excessPower, ~, mach_save] = obj.calcMaxExcessPower(h, W, AB_perc, mach_save);
                diff = excessPower - climb_rate_min;
                if isnan(diff), diff = -1e2; end
            end

            maxAlt = fzero(@helper, [10 30000]); % This might be problamatic
            [excessPower, ~, maxAltMach] = calcMaxExcessPower(obj, maxAlt, W, AB_perc, mach_save); % Have to recalculate to get remaining output
        end
        
        function maxMach = calcMaxMachFixedAlt(obj, h, W, AB_perc, M_guess)
            if nargin < 5 % So that we can pass in guesses with calcMaxMach
                M_guess = 2;
            end
            function objf = helper(M)
                excess = obj.calcExcessPower(h, M, W, AB_perc);
                objf = 1 / M - 10* min(excess, 0); % If excess is less than 0 it begins to penalize
            end

            opts = optimset('Display','off','TolX',1e-3,'MaxFunEvals',100);
            maxMach = fminsearch(@helper, M_guess, opts); % Bit sensitive to the initial guess here but 1000 seems to work
        end
        
        function [maxMach, maxMachAlt] = calcMaxMach(obj, W, AB_perc)
            M_save = 0.6;

            function objf = helper(h)
                maxMach = obj.calcMaxMachFixedAlt(h, W, AB_perc, M_save);
                M_save = maxMach;
                objf = 1/maxMach;
            end

            opts = optimset('Display','off','TolX',1e-3,'MaxFunEvals',200);
            maxMachAlt = fminsearch(@helper, 1000, opts); % Bit sensitive to the initial guess here but 1000 seems to work
        end

        %% Functions for mission calculations (Range/Endurance)

        function [h, M, V, L2D] = findMaxRangeState(obj, W) 
            % Maximize L ^ (1/2) / D

            function objf = objective(x)
                % max statement at the end penalize going below 0
                objf = - obj.calcL2D(x(1), x(2), W) - max([0 -x(1)])  ; % x = [h, M]
                % fprintf("h=%.1f  M=%.3f  f=%.6f\n", x(1), x(2), objf);
            end

            h0 = ft2m(30000);
            M0 = 0.7;
            x0 = [h0, M0];

            % fminsearch will not print anything when inside a class ):
            % Making the tolerance this low does woners for speed
            opts = optimset('Display', 'off', 'TolX', 1e-2, 'TolFun', 1e-2, ...
                    'MaxFunEvals', 50, 'MaxIter', 200);

            % ---- 2D unconstrained optimization ----
            [x_opt, fval, exitflag] = fminsearch(@objective, x0, opts);
        
            % ---- Extract results ----
            h = x_opt(1);
            M = x_opt(2);
        
            % Compute final performance values
            % CL = obj.calcTrimCL(h, M, W);
            % [CD, ~, ~, ~] = obj.calcCD(CL, M);
            % L2D = (CL^0.5) / CD;
            L2D = -fval;
        
            % Convert Mach to true airspeed
            [~, a, ~, ~, ~] = queryAtmosphere(h, [0 1 0 0 0]);
            V = a * M;

        end

        function L2D = calcL2D(obj, h, M, W) % This is L ^ (1/2) / D -> When maximized it is max range condition
            % Weight, W in N
            CL = obj.calcTrimCL(h, M, W);
            [CD, ~, ~, ~] = obj.calcCD(CL, M);
            L2D = CL ^ (0.5) / CD;
        end
        
        function [h, M, V, LD] = findMaxEnduranceState(obj, W) 
            % Maximize L ^ (1/2) / D

            function objf = objective(x)
                objf = -obj.calcLD(x(1), x(2), W); % x = [h, M]
            end

            h0 = ft2m(30000);
            M0 = 0.7;
            x0 = [h0, M0];

            opts = optimset('Display', 'off', 'TolX', 1e-4, 'TolFun', 1e-4, ...
                    'MaxFunEvals', 500, 'MaxIter', 200);

            % ---- 2D unconstrained optimization ----
            [x_opt, fval, exitflag] = fminsearch(@objective, x0, opts);
        
            % ---- Extract results ----
            h = x_opt(1);
            M = x_opt(2);
        
            % Compute final performance values
            % CL = obj.calcTrimCL(h, M, W);
            % [CD, ~, ~, ~] = obj.calcCD(CL, M);
            % LD = (CL^0.5) / CD;
            LD = -fval;
        
            % Convert Mach to true airspeed
            [~, a, ~, ~, ~] = queryAtmosphere(h, [0 1 0 0 0]);
            V = a * M;

        end

        function LD = calcLD(obj, h, M, W) % This is L / D -> When maximized it is max endurance condition
            % Weight, W in N
            CL = obj.calcTrimCL(h, M, W);
            [CD, ~, ~, ~] = obj.calcCD(CL, M);
            LD = CL / CD;
        end
        
        %% Sizing function

        % TODO
        % - Takeoff & Landing Distance https://archive.aoe.vt.edu/lutze/AOE3104/takeoff&landing.pdf

        % Sensitivites
        % Cost if W0 is 10% higher or lower
        % Spot factor if wing folding is 10% higher or lower
        % Max mach if sweep is increased 10% higher or lower

        function buildPlots(obj, W, N)

            % M: Input the weight you want to check for all of these. Likely obj.MTOW
            % N: Master resolution. Likely betwen 10 and 50

            hvec = linspace(obj.alt_range(1), obj.alt_range(2), N);  % Altitude from 100 m to 40,000 ft but still in m here
            Mvec = linspace(obj.mach_range(1), obj.mach_range(2), N);

            [M, h] = meshgrid(Mvec, hvec);

            emptyM = zeros(size(M));
            % Preallocate result matrices - h and M

                % AERODYNAMICS
                trimCL = emptyM;
                CD = emptyM;
                CDi = emptyM;
                D = emptyM;
    
                % PROPULSION
                TA_AB    = zeros(size(M));
                TSFC_AB  = zeros(size(M));
                alpha_AB = zeros(size(M));
                mdotf_AB = zeros(size(M));

                TA_NoAB    = zeros(size(M));
                TSFC_NoAB  = zeros(size(M));
                alpha_NoAB = zeros(size(M));
                mdotf_NoAB = zeros(size(M));

                qinf = zeros(size(M));
    
                % PEFORMANCE
                turn_rate = emptyM;
                n_max = emptyM;
                excessPower_NoAB = emptyM;
                excessPower_AB = emptyM;
                
            % % Preallocate - just M
                CL_max_clean = zeros(size(Mvec));
                CL_max_flapped = zeros(size(Mvec));
                CLa = zeros(size(Mvec));
                CDW = zeros(size(Mvec));
            
            emptyhvec = zeros(size(hvec));
            % % Preallocate - just h
                stallSpeed = emptyhvec;
                takeoffSpeed = emptyhvec;
                landingSpeed = emptyhvec;

                Tvec = emptyhvec;
                avec = emptyhvec;
                Pvec = emptyhvec;
                rhovec = emptyhvec;
                muvec = emptyhvec;

                excessPowerMax_NoAB = emptyhvec;
                mach_maxExcess_NoAB = emptyhvec;
                maxMach_NoAB = emptyhvec;

                excessPowerMax_AB = emptyhvec;
                mach_maxExcess_AB = emptyhvec;
                maxMach_AB = emptyhvec;

                climbRate_AB = emptyhvec;
                climbAngle_AB = emptyhvec;
                climbSpeed_AB = emptyhvec;

                climbRate_NoAB = emptyhvec;
                climbAngle_NoAB = emptyhvec;
                climbSpeed_NoAB = emptyhvec;
            

            % Query functions for each point
            for i = 1:numel(M)
                [q, ~, ~, ~] = metricFreestream(h(i), M(i));
                qinf(i) = q;

                trimCL(i) = obj.calcTrimCL(h(i), M(i), W);
                [CD(i), ~, CDi(i), ~] = obj.calcCD(trimCL(i), M(i));
                D(i) = CD(i) * q * obj.S_ref;

                [TA_AB(i), TSFC_AB(i), alpha_AB(i), mdotf_AB(i)] = obj.calcProp(M(i), h(i), 1);
                [TA_NoAB(i), TSFC_NoAB(i), alpha_NoAB(i), mdotf_NoAB(i)] = obj.calcProp(M(i), h(i), 0);
                

                [turn_rate(i), n_max(i)] = obj.getMaxTurn( h(i), M(i), W);
                excessPower_AB(i) = obj.calcExcessPower(h(i), M(i), W, 1);
                excessPower_NoAB(i) = obj.calcExcessPower(h(i), M(i), W, 0);

                if excessPower_NoAB(i) < 0
                    excessPower_NoAB(i) = NaN;
                end
                if excessPower_AB(i) < 0
                    excessPower_AB(i) = NaN;
                end

            end

            for i = 1:numel(Mvec)
                [CL_max_clean(i), CL_max_flapped(i), CLa(i)] = obj.calcCL(Mvec(i));
                CDW(i) = obj.CDW_interp(Mvec(i));
            end

            for i = 1:numel(hvec)
                [CL_max_clean(i), CL_max_flapped(i), CLa(i)] = obj.calcCL(Mvec(i));

                stallSpeed(i) = obj.calcStallSpeed(hvec(i), W);
                takeoffSpeed(i) = obj.calcTakeoffSpeed(hvec(i), W);
                landingSpeed(i) = obj.calcLandingSpeed(hvec(i), W);

                [Tvec(i), avec(i), Pvec(i), rhovec(i), muvec(i)] = queryAtmosphere(hvec(i), [1 1 1 1 1]);

                if(i == 1)
                    calcMaxExcessPower_NoAB_Mguess = 0.5;
                    calcMaxMachFixedAlt_NoAB_Mguess = 2;

                    calcMaxExcessPower_AB_Mguess = 0.5;
                    calcMaxMachFixedAlt_AB_Mguess = 2;
                else
                    calcMaxExcessPower_NoAB_Mguess = mach_maxExcess_NoAB(i - 1);
                    calcMaxMachFixedAlt_NoAB_Mguess = maxMach_NoAB(i - 1);

                    calcMaxExcessPower_AB_Mguess = mach_maxExcess_AB(i - 1);
                    calcMaxMachFixedAlt_AB_Mguess = maxMach_AB(i - 1);

                end

                [excessPowerMax_NoAB(i), ~, mach_maxExcess_NoAB(i)] = obj.calcMaxExcessPower(hvec(i), W, 0, calcMaxExcessPower_NoAB_Mguess);
                maxMach_NoAB(i) = obj.calcMaxMachFixedAlt( hvec(i), W, 0, calcMaxMachFixedAlt_NoAB_Mguess);

                [excessPowerMax_AB(i), ~, mach_maxExcess_AB(i)] = obj.calcMaxExcessPower(hvec(i), W, 1, calcMaxExcessPower_AB_Mguess);
                maxMach_AB(i) = obj.calcMaxMachFixedAlt( hvec(i), W, 1, calcMaxMachFixedAlt_AB_Mguess);

                [climbRate_AB(i), climbAngle_AB(i), climbSpeed_AB(i)] = obj.calcMaxClimbRate( hvec(i), W, 1);
                [climbRate_NoAB(i), climbAngle_NoAB(i), climbSpeed_NoAB(i)] = obj.calcMaxClimbRate( hvec(i), W, 0);

            end

            %% AERODYNAMICS PLOT

            figure;
            subplot(3, 3, 1);
            surf(M, m2ft(h)/1000, trimCL, 'EdgeColor', 'none')
            xlabel('$M$')
            ylabel('$h$ [kft]')
            zlabel('$C_L$')
            title('Trim Lift Coefficent')

            subplot(3, 3, 2);
            surf(M, m2ft(h)/1000, CD, 'EdgeColor', 'none')
            xlabel('$M$')
            ylabel('$h$ [kft]')
            zlabel('$CD$')
            title('Drag Coefficent')

            subplot(3, 3, 3);
            surf(M, m2ft(h)/1000, CDi, 'EdgeColor', 'none')
            xlabel('$M$')
            ylabel('$h$ [kft]')
            zlabel('$CD_i$')
            title('Induced Drag Coefficent')

            subplot(3, 3, 4);
            scatter(CD, trimCL, 'black', 'filled')
            xlabel('$C_D$')
            title("Drag Polar")
            ylabel('$C_L$')

            subplot(3, 3, 5)
            surf(Mvec, m2ft(h)/1000, D/1000, 'EdgeColor', 'none')
            xlabel('$M$')
            ylabel('$h$ [kft]')
            zlabel('$D$ [kN]')
            title('Total Drag')

            subplot(3, 3, 6)
            plot(Mvec, CDW)
            xlabel('$M$')
            ylabel('$C_{D_W}$')
            title("Wave Drag")

            subplot(3, 3, 7)
            plot(Mvec, CL_max_clean, DisplayName="Clean")
            hold on;
            plot(Mvec, CL_max_flapped, DisplayName="Flapped")
            xlabel('$M$')
            ylabel('$C_{L_{max}}$')
            title("Max Lift Coefficent")
            legend(Location="best");

            subplot(3, 3, 8)
            plot(Mvec, CLa)
            xlabel('$M$')
            ylabel('$C_{L_\alpha}$')
            title("Lift Slope")

            subplot(3, 3, 9)
            surf(M, m2ft(h)/1000, trimCL./CD, 'EdgeColor', 'none')
            xlabel('$M$')
            ylabel('$h$ [kft]')
            zlabel('$\frac{L}{D}$')
            title('Lift over Drag')

            sgtitle("AERODYNAMICS")

            %% ATMOSPHERE PLOT

            figure;
            subplot(2, 2, 1)
            plot(m2ft(hvec)/1000, Tvec);
            ylabel("$T$ [K]")
            yyaxis right;
            plot(m2ft(hvec)/1000, avec);
            ylabel("$a$ [m/s]")

            xlabel("$h$ [kft]")
            title("Temperature \& Speed of Sound")

            subplot(2, 2, 2)
            plot(m2ft(hvec)/1000, Pvec/1000);
            xlabel("$h$ [kft]")
            ylabel("$P$ [kPa]")
            title("Pressure")

            subplot(2, 2, 3)
            plot(m2ft(hvec)/1000, rhovec);
            xlabel("$h$ [kft]")
            ylabel("$\rho$ [kg/m3]")
            title("Density")

            subplot(2, 2, 4)
            plot(m2ft(hvec)/1000, muvec);
            xlabel("$h$ [kft]")
            ylabel("$\mu$ [Pa*s]")
            title("Dynamic Viscosity")

            sgtitle("ATMOSPHERE")

            %% PROPULSION
            figure;
            
            subplot(2, 2, 1);
            surf(M, m2ft(h)/1000, TA_NoAB/1000, 'EdgeColor', 'none', 'FaceAlpha', 1.0);
            hold on
            surf(M, m2ft(h)/1000, TA_AB/1000, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
            hold off
            view(3)
            axis tight
            shading interp
            set(gcf, 'Renderer', 'opengl')
            xlabel('$M$')
            ylabel('$h$ [kft]')
            zlabel('$T_A$ [kN]')
            title('Thrust Available')
            
            subplot(2, 2, 2);
            surf(M, m2ft(h)/1000, TSFC_NoAB, 'EdgeColor', 'none', 'FaceAlpha', 1.0);
            hold on
            surf(M, m2ft(h)/1000, TSFC_AB, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
            hold off
            view(3)
            axis tight
            shading interp
            set(gcf, 'Renderer', 'opengl')
            xlabel('$M$')
            ylabel('$h$ [kft]')
            zlabel('TSFC [kg/Ns]')
            title('Thrust Specific Fuel Consumption')
            
            subplot(2, 2, 3);
            surf(M, m2ft(h)/1000, alpha_NoAB, 'EdgeColor', 'none', 'FaceAlpha', 1.0);
            hold on
            surf(M, m2ft(h)/1000, alpha_AB, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
            hold off
            view(3)
            axis tight
            shading interp
            set(gcf, 'Renderer', 'opengl')
            xlabel('$M$')
            ylabel('$h$ [kft]')
            zlabel('$\alpha$')
            title('Thrust Lapse')
            
            subplot(2, 2, 4);
            surf(M, m2ft(h)/1000, mdotf_NoAB, 'EdgeColor', 'none', 'FaceAlpha', 1.0);
            hold on
            surf(M, m2ft(h)/1000, mdotf_AB, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
            hold off
            view(3)
            axis tight
            shading interp
            set(gcf, 'Renderer', 'opengl')
            xlabel('$M$')
            ylabel('$h$ [kft]')
            zlabel('$\dot{m}_f$ [kg/s]')
            title('Max Fuel Flow')
            
            sgtitle("PROPULSION")

            %% PERFORMANCE
            figure;
            subplot(2, 3, 1);
            surf(M, m2ft(hvec)/1000, turn_rate, 'EdgeColor', 'none')
            xlabel('$M$')
            ylabel('$h$ [kft]')
            zlabel('Turn Rate [deg/s]')
            title('Maximum Turn Rate')

            subplot(2, 3, 2);
            surf(M, m2ft(hvec)/1000, n_max, 'EdgeColor', 'none')
            xlabel('$M$')
            ylabel('$h$ [kft]')
            zlabel('Load Factor')
            title('Maximum Load Factor')

            subplot(2, 3, 3);
            surf(M, m2ft(hvec)/1000, excessPower_NoAB, 'EdgeColor', 'none', 'FaceAlpha', 1.0);
            hold on
            surf(M, m2ft(hvec)/1000, excessPower_AB, 'EdgeColor', 'none', 'FaceAlpha', 0.5);
            hold off
            view(3)
            axis tight
            shading interp
            set(gcf, 'Renderer', 'opengl')
            xlabel('$M$')
            ylabel('$h$ [kft]')
            zlabel('Excess Power [m/s]')
            title('Excess Power')

            subplot(2, 3, 4);
            hold on;
            plot(m2ft(hvec)/1000, excessPowerMax_NoAB, DisplayName="No AB [Excess]", Color='r', LineStyle='-')
            plot(m2ft(hvec)/1000, excessPowerMax_AB, DisplayName="AB [Excess]", Color='b', LineStyle='-')
            ylabel("Excess Power [m/s]")
            yyaxis right;
            plot(m2ft(hvec)/1000, mach_maxExcess_NoAB, DisplayName="No AB [Angle]", Color='r', LineStyle='--')
            plot(m2ft(hvec)/1000, mach_maxExcess_AB, DisplayName="AB [Angle]", Color='b', LineStyle='--')
            ylabel("Mach to Fly")
            xlabel('$h$ [kft]')
            title("Max Excess Power at Altitude")
            legend(Location="best")
            hold off;

            subplot(2, 3, 5);
            plot(m2ft(hvec)/1000, maxMach_NoAB, DisplayName="No AB")
            hold on;
            plot(m2ft(hvec)/1000, maxMach_AB, DisplayName="AB")
            xlabel('$h$ [kft]')
            ylabel("Mach")
            title("Max Mach Number at Altitude")
            legend(Location="best")
            hold off;

            subplot(2, 3, 6);
            hold on;
            plot(m2ft(hvec)/1000, climbRate_NoAB, DisplayName="No AB [Rate]", Color='r', LineStyle='-')
            plot(m2ft(hvec)/1000, climbRate_AB, DisplayName="AB [Rate]", Color='b', LineStyle='-')
            ylabel("Climb Rate [m/s]")
            yyaxis right;
            plot(m2ft(hvec)/1000, climbAngle_NoAB, DisplayName="No AB [Angle]", Color='r', LineStyle='--')
            plot(m2ft(hvec)/1000, climbAngle_AB, DisplayName="AB [Angle]", Color='b', LineStyle='--')
            ylabel("Climb Angle [deg]")
            xlabel('$h$ [kft]')
            title("Max Sustained Climb Rate")
            legend(Location="best")
            hold off;


        end
    end
end