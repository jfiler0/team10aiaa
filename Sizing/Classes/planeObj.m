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
        Gamma % dihedral angle of wing
        c_avg % m
        tr % taper ratio
        x_cg % location of CG of aircraft

            % Tail Parameters
            VH % Horizontal Tail Volume Ratio
            VV % Vertical Tail Volume Ratio
            Kc % fudge factor for tail arm = fuselage half length assumption

        L_fuselage % m
        A_max % m2
        A_0 % m2
        E_WD % no idea what this is
        x_rootchord % distance of beginning of leading edge of wing from tip of nose 
        g_limit
        engine

        weights % constructor from Raymer containing a bunch of component weights

        fixed_input
        tail_input

        % Parameters when missions and loadouts are applied
        CD0_Payload
        loadout
        W_P % payload weight (weapon type stores)
        W_Tanks % external fuel tank EMPTY weight
        max_fuel_weight % cause I keep recaluclating this
        mid_mission_weight % useful for mission calculations instead of using WE or MTOW
        internal_fuel_weight

        % Parameters that remain fixed (need to edit the input function if you want them moved into the deisgn space)
        type % Name of the regrssion to use in Raymer for We/W0
        raymer % Stores raymer coefficents
        KLOC % kilo lines of code
        num_engine
        engineData % [T0_NoAB, T0_AB]
        W_F % fixed weight
        a0 % deg
        cl_alpha = 0.1; % foil lift slope
        cl_alpha_horstab % tail foil lift slope
        tc = 0.04; % airfoil thickness
        max_alpha % max angle of attack in deg
        mach_range % vector [min mach, max mach] for interpolation range
        transonic_range % spline interpolation range
        alt_range % vector [min alt, max alt] in meters

        % engine data (from lookup)
            engine_dry_weight % N
            engine_diameter % m
            engine_T0 % max sealevel N
            engine_T0AB % max sealevel AB N

        % Parameters that are derived
        c_t % m
        c_r % m
        span % m
        semi_span % m
        AR
        S_wing % m2
        S_ref % m2
        fold_span % m
        wing_height % m -> for max height check cacl and landing gear height
        fold_height % m -> how high up the wings go when folded (will it fit in hanger)
        x_rootLE_wing % x distance of leading edge of root chord from tip of nose
        MAC_wing % mean aerodynamic chord
        y_MAC_wing % Y location of airfoil with same chord as MAC; distance of airfoil section out the right wing from the centerline 
        x_MAC_wing % X location of LE of airfoil section with same chord as MAC; distance of LE from tip of nose 
        
        b_strake % span of strake
        x_strake % location of LE at the root of strake from tip of nose
        lam_strake % taper ratio of strake
        c_root_strake % root chord of strake 
        Lambda_LE_strake % Leading edge sweep angle of strake
        MAC_strake % mean aerodynamic chord of strake 
        y_MAC_strake % Y location of airfoil with same chord as MAC; distance of airfoil section out the right wing from the centerline 
        x_MAC_strake % X location of LE of airfoil section with same chord as MAC; distance of LE from tip of nose 
        S_strakes % planform area of strakes

        depsdalph % downwash slope
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

                V_hor % calculated horizontal tail ratio

                c_r_horstab % root chord
                MAC_horstab % mean aerodynamic chord
                y_MAC_horstab % Y location of airfoil with same chord as MAC; distance of airfoil section out the right wing from the centerline 
                x_MAC_horstab % X location of LE of airfoil section with same chord as MAC; distance of LE from tip of nose 
                x_horstab % X location of LE of root airfoil of horstab from tip of nose
                e_notoswald_horstab % whatever this is
                b_h % span
                LAM_LE_horstab % sweep angle
                LAM_h % dihedral angle
                inc_h % angle of incidence
                AR_horstab % aspect ratio of horizontal stabilizer
                % Vertical
                x_verstab % X location of LE of root airfoil of verstab from tip of nose
                S_v % Planform Area
                l_vt % Tail arm
                v_tc % Airfoil Thickness
                AR_v % Aspect Ratio
                lam_v % Taper ratio
                c_t_v % tip chord

                V_ver % calculated vertical tail ratio

                c_r_v % root chord
                MAC_verstab % mean aerodynamic chord
                b_v % span
                LAM_v % sweep angle
                GAM_v % dihedral angle
                inc_v % angle of incidence
                z_MAC_verstab % Z location of airfoil with same chord as verstab MAC; distance of airfoil section up the tail from the centerline 
                x_MAC_verstab % X location of LE of airfoil section with same chord as MAC; distance of LE of verstab from tip of nose 


                % Aerodynamic Centers
                x_ac_wings % distance of aerodynamic centers from tip of nose
                x_ac_horstabs
                x_ac_strakes
                x_ac_verstabs
                x_ac_wings_strakes
                x_ac_wings_strakes_fuselage
                x_bar_ac_wings_strakes_fuselage % normalized ac w/o tail w/r/t MAC of wing

           % STABILITY PARAMETERS: STATIC MARGIN
           x_np 
           x_bar_n
           X_bar_np
           X_bar_cg
           l_opt % optimal tail arm 
           SM % static margin, distance from cg to neutral point 
        % filling out these interpolation function helps considerably with speed
        CLa_interp
        CDW_interp
        K1_interp
        K2_interp
    end

    methods
        
        %% Primary class defenition functions (used on creation and updates)
        function obj = planeObj(fixed_input, tail_input, name, MTOW, Lambda_LE, c_r, c_t, span, num_engine, engine, W_F) 
            % Note it returns the obj variable to be used. Use as plane = planeObj(...)
            obj.name = name;

            %% Assign inputs
            obj.MTOW = MTOW; % Newtons (this used to be WE but to use the raymer eqns we need to go backwards. WE also required most of the variables so we need to assign everything an calc in derived)
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
            obj.tail_input = tail_input;
            obj.Kc = 1.1; % assuming semi-conical rear fuselage 
            obj.VH = fixed_input.VH;
            obj.VV = fixed_input.VV;
            % Storing the raymer coefficents is much faster than reading the table every loop
            obj.type = fixed_input.type; % For regression lookup
            obj.raymer = struct(); % Raymer coefficents
            [obj.raymer.A, obj.raymer.C] = getRaymerCoefficents(obj.type);
            obj.KLOC = fixed_input.KLOC;

            % Parameters depending on loadout
            obj.W_P = 0; % payload - set when loadout is applied
            obj.CD0_Payload = 0;

            % Parameters that remain fixed

            obj.engine = engine;
            engine_geom = engine_getData(engine, 1); % this flag makes the function return weight/diam instead
            obj.engine_dry_weight = engine_geom(1);
            obj.engine_diameter = engine_geom(2);

            obj.engineData = engine_getData(engine); % Saves key engine data as an array [T0_NoAB, T0_AB]
            obj.engine_T0 = obj.engineData(1);
            obj.engine_T0AB = obj.engineData(2);

            obj.W_F = W_F; % fixed weight

            obj.a0 = -1; % deg (zero lift aoa)
            obj.cl_alpha = 0.1; % wing foil lift slope
            obj.cl_alpha_horstab = 2*pi*pi/180; % tail foil lift slope
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
        
        % IMPORTANT -> WHEN USING THIS YOU HAVE TO DO plane = plane.updateDerivedVariables
        function obj = updateDerivedVariables(obj)
           
            % empty_weight_fraction = obj.WE / obj.MTOW = 2.34*N2lb(obj.MTOW)^(-0.13) ; % Use historical data
            % obj.WE = obj.MTOW * 2.34 * N2lb(obj.MTOW)^(-0.13)
            % obj.MTOW = lb2N( ( N2lb(obj.WE) / 2.34)^(1/0.87) );
            % obj.MTOW = obj.fixed_input.MTOW_Scalar * lb2N( ( N2lb(obj.WE) / obj.raymer.A )^(1 / (1 + obj.raymer.C) ) );

            %% Standard Wing Geometry Stuff
            obj.c_avg = 0.5*(obj.c_t + obj.c_r); % Average chord
            obj.tr = obj.c_t / obj.c_r; % Taper Ratio
            obj.semi_span = obj.span / 2;
            obj.Lambda_TE =  atand( tand(obj.Lambda_LE) - 2*(obj.c_r - obj.c_avg) / obj.semi_span );
            obj.AR = obj.span / obj.c_avg;
            obj.S_wing = obj.span*obj.c_avg;
            obj.S_ref = obj.S_wing; % Typical defenition for reference area
            %obj.S_strakes = 0.5*obj.b_strake*obj.c_root_strake; % planform area of strakes calculation

            %% Random but important
            obj.fold_span = obj.span * (1 - obj.fixed_input.fold_ratio);
            obj.wing_height = 0.1333 * obj.L_fuselage; % height of the leading edge from the ground (estimations)
            obj.fold_height = obj.wing_height + (obj.span * 0.5) * obj.fixed_input.fold_ratio; % How hight the wings would reach straight up

            obj = obj.updateWeights();
           

            %% Tail Geometry

            MAC = obj.c_avg;
            
            obj.l_opt = obj.Kc*sqrt(4*MAC*obj.S_wing*obj.tail_input.VH/(pi*obj.A_max));
            obj.S_h = obj.tail_input.VH*MAC*obj.S_wing/obj.l_opt;
            obj.AR_h =(2/3)*obj.AR;
            obj.lam_h = 0.35; % textbook estimate
            obj.LAM_LE_horstab = obj.Lambda_LE; % stealth requirement

            %% Homework 4 - Drag
            obj.Lambda_qc = atand(tand(obj.Lambda_LE) - ( 1 - obj.tr)/(obj.AR*(1+obj.tr))); % Compute the quarter-chord sweep angle (deg) - HW4
            
            c = -0.1289; d = 0.7506; % Regression from somewhere lol
            obj.S_wet = obj.fixed_input.SWET_Scalar * 0.09290304*(10^c  * N2lb(obj.WE)^d); % Converting S_wet in ft and W0 in lb
            Cf = 0.004; % Raymer gives this value for navy fighters
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
            % obj.k2_sub = -2 * obj.k1_sub * CL_min_D;
            obj.k2_sub = 0; % set to 0 for a sec ***
            
            % CD_0
            % obj.CD0_Body = CD_min + obj.k1_sub*CL_min_D^2 + obj.k2_sub*CL_min_D; % Actually has k2 term
            obj.CD0_Body = CD_min;
            obj.CD0 = obj.CD0_Body + obj.CD0_Payload;
            obj.M_CD0_max = 1/(cosd(obj.Lambda_LE))^0.2; % The only supersonic drag variable that is not dependent on Cl or M

            %% Homework 4 - Lift
            obj.Lambda_max_t = ( obj.Lambda_LE - obj.Lambda_TE )/2; % *** Feel like this should be addition instead for some reason
            obj.D = 2*sqrt(obj.A_max/pi); % Assuming roughly circular cross section to get fuselage diameter/width
            obj.S_exposed = obj.S_wing * 1.3; % *** Trying to account for body lift/strakes/tail anything not in here
            obj.F = obj.fixed_input.F_Scaler * 1.07 * (1 + obj.D/obj.span)^2; % Lift Factor
            % obj.F = 1; % *** Needs to be fixed

            obj.S_flapped = obj.S_wing * 0.6; % *** Obviously has a big impact on landing CL
            obj.Delta_flap_param = 0.9; % Factor depending on the type of flap
            obj.Lambda_HL = obj.Lambda_TE; % *** What is the actual way to calculate the hinge line

            %% Static Margin / Neutral Point Calculations
            % 
            % % Downwash slope calculation
            % obj.depsdalph = 2*CL_alpha_wing /(pi*obj.AR);
            % 
            % obj.MAC_wing = (2/3)*obj.c_r*(1 + obj.tr + obj.tr.^2)/(1+obj.tr);
            % obj.y_MAC_wing = (obj.span/6)*((1 + 2*obj.tr)/(1+obj.tr));
            % obj.x_MAC_wing = obj.x_rootLE_wing + obj.y_MAC_wing*tand(obj.Lambda_LE);
            % 
            % % Some fixes so the tail code works -> Liam correct how you want
            % obj.lam_h = obj.tr; % set taper ratio to be the same as the wing for stealth reasons
            % 
            % obj.MAC_horstab = (2/3)*obj.c_r_horstab*(1 + obj.lam_h + obj.lam_h.^2)/(1+obj.lam_h);
            % obj.y_MAC_horstab = (obj.b_h/6)*((1 + 2*obj.lam_h)/(1+obj.lam_h));
            % obj.x_MAC_horstab = obj.x_horstab + obj.y_MAC_horstab*tand(obj.LAM_LE_horstab);
            % obj.AR_horstab = obj.b_h / obj.MAC_horstab;
            % % swapped lam for obj.tr
            % obj.MAC_strake = (2/3)*obj.c_root_strake*(1 + obj.lam_strake + obj.lam_strake.^2)/(1+obj.lam_strake);
            % obj.y_MAC_strake = (obj.b_strake/6)*((1 + 2*obj.lam_strake)/(1+obj.lam_strake));
            % obj.x_MAC_strake = obj.x_strake + obj.y_MAC_strake*tand(obj.Lambda_LE_strake);
            % 
            % obj.MAC_verstab = (2/3)*obj.c_r_v*(1 + obj.lam_v + obj.lam_v.^2)/(1+ obj.lam_v);
            % obj.z_MAC_verstab = (obj.b_v/6)*((1 + 2*obj.lam_v)/(1 + obj.lam_v));
            % obj.x_MAC_verstab = obj.x_verstab + obj.z_MAC_verstab*tan(deg2rad(obj.LAM_v));
            % 
            % % Calculating Aerodynamic Centers of Each Portion 
            % obj.x_ac_wings = obj.x_MAC_wing + 0.25*obj.MAC_wing;
            % obj.x_ac_horstabs = obj.x_MAC_horstab + 0.25*obj.MAC_horstab;
            % obj.x_ac_strakes = obj.x_MAC_strake + 0.25*obj.MAC_strake;
            % obj.x_ac_verstabs = obj.x_MAC_verstab +0.25*obj.MAC_verstab;
            % 
            % obj.x_ac_wings_strakes = obj.x_ac_wings + (obj.x_ac_strakes - obj.x_ac_wings)*obj.S_strakes/((2*obj.S_wing)+obj.S_strakes);
            % obj.x_ac_wings_strakes_fuselage = obj.x_ac_wings_strakes - ((obj.L_fuselage*obj.A_max^2)*(0.005 + 0.111*(obj.x_ac_wings_strakes/obj.L_fuselage)^2)/((2*obj.S_wing)*CL_alpha_wing*57.29)); 
            % obj.x_bar_ac_wings_strakes_fuselage = (obj.x_ac_wings_strakes_fuselage - obj.x_MAC_wing)/obj.MAC_wing;
            % 
            % % % tail arm
            % % obj.l_ht = obj.x_ac_horstabs - obj.x_ac_wings_strakes_fuselage; % tail arm from aerodynamic centers
            % % obj.V_hor = obj.S_h*obj.l_ht/(obj.S_wing*obj.MAC_wing);
            % 
            %  % Tail lift slope calculation
            % % obj.e_notoswald_horstab = 2/(2 - obj.AR_horstab + sqrt(4 + obj.AR_horstab^2 * (1 + (tand(obj.LAM_LE_horstab))^2)));
            % % CL_alpha_tail = obj.cl_alpha_horstab/(1 + 57.3 * obj.cl_alpha_horstab/(pi * obj.e_notoswald_horstab * obj.AR_horstab));
            % % CLalph_CLalpht = CL_alpha_tail/CL_alpha_wing;
            % % 
            % % obj.x_bar_n = obj.x_bar_ac_wings_strakes_fuselage + obj.V_hor*(CLalph_CLalpht*(1-obj.depsdalph));
            % 
            % % Final Static Margin Calculations
            % % obj.x_np = obj.x_MAC_wing + (obj.x_bar_n*obj.MAC_wing);
            % % obj.X_bar_cg = obj.x_cg/obj.x_MAC_wing;
            % % obj.X_bar_np = obj.x_np/obj.x_MAC_wing;
            % % obj.SM = obj.X_bar_np - obj.X_bar_cg

            %% Interpolants
            M_vec = linspace(obj.mach_range(1), obj.mach_range(2), 100); % Can change last number to increase/decrease resolution
            obj.CLa_interp = obj.buildCLaInterpolant(M_vec);
            obj.CDW_interp = obj.buildCDWInterpolant(M_vec);
            obj.K1_interp = obj.buildK1Interpolant(M_vec);
            obj.K2_interp = obj.buildK2Interpolant(M_vec);

        end

        function obj = applyLoadout(obj, loadout) % verify strike loadout does give big impact on drag
            % loadout variable must compre from buildLoadout function
            obj.W_P = loadout.weight_weapons;
            obj.W_Tanks = loadout.weight_tanks_empty;
            obj.CD0_Payload = loadout.CD0;
            obj.CD0 = obj.CD0_Body + obj.CD0_Payload;
            obj.loadout = loadout;

            obj = obj.updateWeights();
        end

        function obj = updateWeights(obj)

            obj.weights = calcRaymerWeights(getPlaneRaymerWeightInput(obj));
            fn = fieldnames(obj.weights);  % get all field names
            total = 0;
            for i = 1:numel(fn)
                total = total + obj.weights.(fn{i});
            end
            obj.WE = total;

            obj.max_fuel_weight = obj.MTOW - obj.WE - obj.W_P - obj.W_Tanks - obj.W_F;
            obj.internal_fuel_weight = 0.7 * obj.max_fuel_weight; % Accounts for tanks in an actual mission
            obj.mid_mission_weight = obj.MTOW - obj.max_fuel_weight / 2; % Assume half of fuel is burned

            % obj.landing_weight = getLandingWeight(obj);
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
            CD_wave = 4.5 * pi / obj.S_ref * ((obj.A_max - obj.A_0)/obj.L_fuselage)^2 * obj.E_WD * (0.74 + 0.37 * cosd(obj.Lambda_LE)) * (1 - 0.3*sqrt(M_vec - obj.M_CD0_max));
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
            CLa = obj.F * obj.CLa_interp(M);
            CL_max_clean = CLa * (obj.max_alpha - obj.a0);
            CL_max_flapped = CL_max_clean + obj.Delta_flap_param *obj.S_flapped/obj.S_ref * cosd(obj.Lambda_HL);
        end
        
        function [CD, CD0, CDi, CDW, eosw] = calcCD(obj, CL, M)
            % Add any scaler corrections (though SWET is embedded in the update and is essentially a CD0 scaler)
            CD0 = obj.CD0;
            CDi = obj.fixed_input.K1_Scalar * obj.K1_interp(M) * CL^2 + obj.K2_interp(M) * CL;
            CDW = obj.fixed_input.CDW_Scalar * obj.CDW_interp(M);
            CD = CD0 + CDi + CDW;

            eosw = CL.^2 / (pi * (CDi + CDW) * obj.AR);

            % CD = CL^2 / pi*e*AR
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

            q = @(V) 0.5 * rho * V^2;

            f = @(V) real( W - get_output_at_index(@() obj.calcCL(V / a), 2) * obj.S_ref * q(V) ); % I don't know why @() is required but it does work
            x0 = 0.5 * a;
            stallSpeed = fzero(f , x0);
            % [~, CL_max_flapped, ~] = obj.calcCL(stallSpeed/a)
        end
        
        function takeoffSpeed = calcTakeoffSpeed(obj, h, W)
            % Can vary h to see change with alt. W is likely obj.MTOW
            takeoffSpeed = 1.2 * obj.calcStallSpeed(h, W);
        end
        
        function landingSpeed = calcLandingSpeed(obj, h, W)
            % Can vary h to see change with alt.
            landingSpeed = 1.3 * obj.calcStallSpeed(h, W); % RFP says 10% instead of 1.3 that is traditional
        end
        
        % Note the absolute max turn rate seems to always be at sea level
        % If you pull as hard as you can without stalling or as hard as the airframe can go - how many deg/s
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

        function [turn_rate, mach] = getMaxTurnAtAlt(obj, h, W, M_guess)
            % If the guess was not provided use fall back (should be standard)

            [~, a, ~, ~, ~] = queryAtmosphere(h, [0 1 0 0 0]);

            if(nargin < 5)
                M_guess = 0.5;
            end

            fun = @(M) -obj.getMaxTurn(h, M, W); % negative for maximization
            opts = optimset('Display','off','TolX',1e-3,'MaxFunEvals',200);
        
            % Solve for max excess power speed
            [mach, turn_rate] = fminsearch(fun, M_guess, opts);
            turn_rate = - turn_rate; % since it was minimization

        end
        
        % Maintain a turn rate without slowing down or exceeding structural limits
        function [turn_rate, n] = getSustainedTurn(obj, h, M, W, AB_perc)
            [TA, ~, ~, ~] = obj.calcProp(M, h, AB_perc);
            [q, V, ~, ~] = metricFreestream(h, M);

            fun = @(CL) TA - q * obj.S_ref * obj.calcCD(CL, M); % max prevents a negative CL

            if(fun(0) <= 0) % wave drag is so large you can't have any lift
                turn_rate = NaN;
                n = NaN;
            else
                try
                    CL_sustain = fzero(fun, [0 10]); % Max sustainable Cl
                
                    if(CL_sustain < 0)
                        warning("wtf why does this become negative")
                    end
                    if( isnan(CL_sustain) )
        
                        clvec = linspace(-5, 5, 30);
                        funvec = arrayfun(@(CL) fun(CL), clvec);
                        plot(clvec, funvec)
        
                        warning("wtf why does this become negative")
                    end
        
                    [CL_max_clean, ~, ~] = calcCL(obj, M);
        
                    Cl = min([CL_sustain CL_max_clean]);
        
                    L_max = q * Cl * obj.S_ref;
                    n = min( L_max / W, obj.g_limit);
                    turn_rate = rad2deg( n * 9.8051 / V);

                catch
                    turn_rate = NaN;
                    n = NaN;
                end

            end
        end
        
        % Note that absolute max seems to always be at 0 altitude
        function [turn_rate, mach] = getMaxSustainedTurnAtAlt(obj, h, W, AB_perc, M_guess)
            % If the guess was not provided use fall back (should be standard)

            [~, a, ~, ~, ~] = queryAtmosphere(h, [0 1 0 0 0]);

            if(nargin < 5)
                M_guess = 0.5;
            end

            fun = @(M) -obj.getSustainedTurn(h, M, W, AB_perc); % negative for maximization
            opts = optimset('Display','off','TolX',1e-3,'MaxFunEvals',200);
        
            % Solve for max excess power speed
            [mach, turn_rate] = fminsearch(fun, M_guess, opts);
            turn_rate = - turn_rate; % since it was minimization

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

        function area = calcFoldedWingProjection(obj)
            % fold_ratio = 0.1 -> 10% of the wing is folded

            % The FA18E has a wingspan of 40.4 ft and when folded goes to 27.5. Thus for it, fold_ratio = 1 - 27.5 / 40.4 = 0.3193
            % We then get a area of 49.1823 when projected which is now the spot facto = 1 reference

            fold_span = obj.span * ( 1 - obj.fixed_input.fold_ratio);
            fold_tipChord = obj.c_r + (obj.c_r - obj.c_t) * ( 1 - obj.fixed_input.fold_ratio);
            area = fold_span * ( fold_tipChord + obj.c_r) / 2;
        end
        
        function spotFactor = calcSpotFactor(obj)
            % fold_ratio = 0.1 -> 10% of the wing is folded, 0.3193 for hornet
            area = obj.calcFoldedWingProjection();
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
        function [range_m, fuel_burned_N] = findTotalMaxRange(obj, W, N_divide)
            % Assuming the aircraft goes from some starting W to its empty weight + any payload + avionics
            % What range can it get?
            % N_divide - How many division to apply to the weight for accuracy in changing max range state

            Wvec = linspace(W, obj.WE + obj.W_F + obj.W_P + obj.W_Tanks, N_divide);

            range_m = 0;

            for i = 2:length(Wvec)
                Wi = (Wvec(i - 1) + Wvec(i))/2; % Use midpoint weight to find optimum
                [h, M, V, L2D] = obj.findMaxRangeState(Wi);
                LD = obj.calcLD(h, M, Wi);
                [~, TSFC, ~, ~] = obj.calcProp(M, h, 0);

                range_m = range_m + LD * V * log(Wvec(i - 1)/Wvec(i)) / (TSFC*9.805);
            end

            fuel_burned_N = Wvec(1) - Wvec(end);

        end

        function [time_s, fuel_burned_N] = findTotalMaxEndurance(obj, W, N_divide)
            % Assuming the aircraft goes from some starting W to its empty weight + any payload + avionics
            % What range can it get?
            % N_divide - How many division to apply to the weight for accuracy in changing max range state

            Wvec = linspace(W, obj.WE + obj.W_F + obj.W_P + obj.W_Tanks, N_divide);

            time_s = 0;

            for i = 2:length(Wvec)
                Wi = (Wvec(i - 1) + Wvec(i))/2; % Use midpoint weight to find optimum
                [h, M, V, LD] = obj.findMaxEnduranceState(Wi);
                % LD = obj.calcLD(h, M, Wi);
                [~, TSFC, ~, ~] = obj.calcProp(M, h, 0);

                time_s = time_s + LD * log(Wvec(i - 1)/Wvec(i)) / (TSFC*9.805);
            end

            fuel_burned_N = Wvec(1) - Wvec(end);

        end

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
        
    end
end