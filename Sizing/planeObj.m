classdef planeObj
    properties
        % Whenever you start a class object like this, you have to tell MATLAB every obj.VARIABLE type variables exist
        name
        % Parameters that should be optimized (inputs)
        W0 % MTOW
        Lambda_LE % deg
        Lambda_TE % deg
        c_avg % m
        tr % taper ratio

        % How can these become inputs...
        L_fuselage
        A_max
        A_0
        E_WD

        % Parameters that remain fixed
        mission_set % array of flightSegment objects
        engine % string identifier for query_engine
        W_F % fixed weight
        W_P % payload
        a0 % deg
        cl_alpha = 0.1; % foil lift sope
        tc = 0.04; % airfoil thickness
        max_alpha % max angle of attack in deg
        mach_range % vector [min mach, max mach] for interpolation range
        transonic_range % spline interpolation range

        % Parameters that are derived
        c_t
        c_r
        span
        AR
        S_wing
        S_ref
        Lambda_qc
        S_wet
        e_notoswald
        e_osw       
        k1_sub
        k2_sub
        CD0
        M_CD0_max % Although is really max wave drag
        D
        Lambda_max_t
        S_exposed
        F
        S_flapped
        Delta_flap_param
        Lambda_HL

        CLa_interp
        CDW_interp
        K1_interp
        K2_interp
    end

    methods
        function obj = planeObj(name, W0, Lambda_LE, Lambda_TE, c_avg, tr, mission_set, engine, W_F, W_P) 
            % When creating a plane object, you call this function. The fact that it is the same name as the class is not important. Note it
            % returns the obj variable to be used

            obj.name = name;

            %% Asign inputs
            obj.W0 = W0; % Newtons
            obj.Lambda_LE = Lambda_LE; % deg
            obj.Lambda_TE = Lambda_TE; % deg
            obj.c_avg = c_avg; % m
            obj.tr = tr; % taper ratio
            
            %% Bunch of fixed parameters (***)

            % Current FA18E parameters from VSP
            obj.L_fuselage = 17.54; %m
            obj.A_max = 1.46; %m (*** These have a huge impact of lift parameter F and can almost double lift)
            obj.A_0 = 0;
            obj.E_WD = 2.2; 
    
            % Parameters that remain fixed
            obj.mission_set = mission_set; % array of flightSegment objects
            obj.engine = engine; % string identifier for query_engine
            obj.W_F = W_F; % fixed weight
            obj.W_P = W_P; % payload
            obj.a0 = -1;
            obj.cl_alpha = 0.1; % foil lift sope
            obj.tc = 0.04; % airfoil thickness
            obj.max_alpha = 15; % deg 

            obj.mach_range = [0.2 3.5];
            obj.transonic_range = [0.95 1.3];

            obj = obj.updateDerivedVariables(); %% Fills in the remaining constructor variables we need
        end
        function updateInputsAsVector(obj, input) % Streamlines changing class variables later when doing optimization
            obj.W0 = input(1);
            obj.Lambda_LE = input(2);
            obj.Lambda_TE = input(3);
            obj.c_avg = input(4);
            obj.tr = input(5);

            obj = obj.updateDerivedVariables();
        end
        function obj = updateDerivedVariables(obj)
           
            %% Standard Wing Geometry Stuff
            obj.c_t = 2*obj.c_avg / (1 + 1 / obj.tr);
            obj.c_r = obj.c_t / obj.tr;
            obj.span = 2*(obj.c_r - obj.c_avg) / ( tand(obj.Lambda_LE) - tand(obj.Lambda_TE) );
            obj.AR = obj.span / obj.c_avg;
            obj.S_wing = obj.span*obj.c_avg;
            obj.S_ref = obj.S_wing; % Typical defenition for reference area
            
            %% Homework 4 - Drag
            obj.Lambda_qc = atand(tand(obj.Lambda_LE) - ( 1 - obj.tr)/(obj.AR*(1+obj.tr))); % Compute the quarter-chord sweep angle (deg) - HW4
            
            c = -0.1289; d = 0.7506;
            obj.S_wet = 0.09290304*(10^c  * N2lb(obj.W0)^d); % Converting S_wet in ft and W0 in lb
            Cf = 0.0035; % For fighters?
            CD_min = Cf * obj.S_wet/obj.S_ref;
            
            % Induced Drag Polar
            obj.e_notoswald = 2/(2 - obj.AR + sqrt(4 + obj.AR^2 * (1 + (tand(obj.Lambda_LE))^2))); % Lambda_LE, not Lmabda_max
            obj.e_osw = (4.61 * (1-0.045*obj.AR^0.68)) * cosd(obj.Lambda_LE)^0.15 - 3.1; %MUST USE RAYMER 12.50
            
            %CL_alpha - for the wing?
            CL_alpha_wing = obj.cl_alpha/(1 + 57.3 * obj.cl_alpha/(pi * obj.e_notoswald * obj.AR));
            CL_min_D = CL_alpha_wing*-obj.a0/2;
            
            % Can reuse these later
            obj.k1_sub = 1 / (pi * obj.e_osw* obj.AR);
            obj.k2_sub = -2 * obj.k1_sub * CL_min_D;
            
            % CD_0
            obj.CD0 = CD_min + obj.k1_sub*CL_min_D^2 + obj.k2_sub*CL_min_D; % Actually has k2 term

            obj.M_CD0_max = 1/(cosd(obj.Lambda_LE))^0.2; % The only supersonic drag variable that is not dependent on Cl or M

            %% Homework 4 - Lift
            obj.Lambda_max_t = ( obj.Lambda_LE - obj.Lambda_TE )/2; % *** Feel like this should be addition instead for some reason
            obj.D = 2*sqrt(obj.A_max/pi); % Assuming roughly circular cross section to get fuselage diameter/width
            obj.S_exposed = obj.S_wing * 1.3; % *** Trying to account for body lift/strakes/tail anything not in here
            obj.F = 1.07 * (1 + obj.D/obj.span)^2; % Lift Factor
            obj.F = 1;

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
        function [CD, CD0, CDi, CDW] = calcCD(obj, CL, M)
            CD0 = obj.CD0;
            CDi = obj.K1_interp(M) * CL^2 + obj.K2_interp(M) * CL;
            CDW = obj.CDW_interp(M);
            CD = CD0 + CDi + CDW;
        end
        function CDW_interp = buildCDWInterpolant(obj, M_vec)
            CD_wave = 4.5 * pi / obj.S_ref * ((obj.A_max - obj.A_0)/obj.L_fuselage)^2 * obj.E_WD * (0.74 + 0.37 * cosd(obj.Lambda_LE)) * (1 - 0.3*sqrt(M_vec - obj.M_CD0_max));
            CDW = obj.generateTransonicSpline(zeros(size(CD_wave)), CD_wave, M_vec);
            CDW_interp = griddedInterpolant(M_vec, CDW, 'spline');
        end
        function K1_interp = buildK1Interpolant(obj, M_vec)
            k1_sup = obj.AR * (M_vec.^2 - 1) ./ (4*obj.AR*sqrt(M_vec.^2 - 1) -2) * cosd(obj.Lambda_LE); % supersonic range
            k1 = obj.generateTransonicSpline(obj.k1_sub * ones(size(k1_sup)), k1_sup, M_vec);
            K1_interp = griddedInterpolant(M_vec, k1, 'spline');
        end
        function K2_interp = buildK2Interpolant(obj, M_vec)
            k2_sup = zeros(size(M_vec));
            k2 = obj.generateTransonicSpline(obj.k2_sub * ones(size(M_vec)), k2_sup, M_vec);
            K2_interp = griddedInterpolant(M_vec, k2, 'spline');
        end
        function CLa_interp = buildCLaInterpolant(obj, M_vec)
            beta = sqrt((1-M_vec.^2)); %MACH - real to try try and fix things above M 1 (*** is this fine)
            eta = rad2deg(obj.cl_alpha) ./ (2*pi./beta); % Airfoil Efficiency - MACH

            % CL_alpha_sub = (2*pi*obj.AR) ./ (2+ sqrt(4 + (obj.AR.^2 * beta.^2)/eta.^2 .* (1 + ( tand(obj.Lambda_max_t).^2 )./beta.^2) ) ) * (obj.S_exposed/obj.S_ref)* obj.F; % Ssurface = Sref
            CL_alpha_sub = deg2rad( 2*pi./sqrt(1-M_vec.^2) ); % The difference between these is pretty big ***
            CL_alpha_supersonic = deg2rad( 4./sqrt(M_vec.^2-1) );

            CLa = obj.generateTransonicSpline(CL_alpha_sub, CL_alpha_supersonic, M_vec);
            CLa_interp = griddedInterpolant(M_vec, CLa, 'spline');
        end
        function out_vec = generateTransonicSpline(obj, subsonic_range, supersonic_range, M_vec)
            subsonic_range(obj.transonic_range(1) < M_vec) = NaN;
            supersonic_range(obj.transonic_range(2) > M_vec) = NaN;
            range = max(subsonic_range, supersonic_range);

            x = find(~isnan(range));
            y = range(x);

            out_vec = interp1(x, y, 1:numel(range), 'spline', 'extrap');
        end
        function [CL_max_clean, CL_max_flapped, CLa] = calcCL(obj, M) % *** These CL values are wayyyyy too high
            CLa = obj.CLa_interp(M);
            CL_max_clean = CLa * (obj.max_alpha - obj.a0);
            CL_max_flapped = CL_max_clean + obj.Delta_flap_param *obj.S_flapped/obj.S_ref * cosd(obj.Lambda_HL);
        end
        function valBlended = getBlend(obj, M, val_lower, val_upper, range)
            % returns a smoothly blended value between two values moving from val_lower to val_upper across obj.blend_range
            % GPTs ideas for smooth blends
            if(M < range(1))
                valBlended = val_lower;
            elseif(M > range(2))
                valBlended = val_upper;
            else
                x = (M - range(1)) / (range(2) - range(1)); % normalized 0–1
                x = max(0, min(1, x)); % clamp
                w = 3*x^2 - 2*x^3;
    
                valBlended = val_lower + w * (val_upper - val_lower);
            end
        end
        function buildPolars(obj)
            % buildPolars - compute aerodynamic polars and plot them in a 3x2 tiled layout
            %
            % Assumes:
            %   [CL_max_clean, CL_max_flapped, CLa] = obj.calcCL(M)
            %   [CD_total, CD0, CDi, CD_wave] = obj.calcCD(CL, M)
        
            % --- User parameters / sampling ---
            CL_values = [0.05, 0.1, 0.4];            % CL samples for CD vs M and CDi vs M
            M_samples  = [0.5, 0.8, 1.0, 1.3, 1.5];  % Mach numbers for drag-polars (plot 6)
            mvec       = linspace(obj.mach_range(1), obj.mach_range(2), 200); % Mach sweep
            CL_for_CD  = 0.2;                         % representative CL for CD-component plot
            lw = 2;                                   % line width for all plots
            m_end = obj.mach_range(2);                % max mach for x-limits
        
            % --- Preallocate / compute CL terms over mvec (call calcCL once per M) ---
            nM = length(mvec);
            CL_max_clean_vec = zeros(1,nM);
            CL_max_flapped_vec = zeros(1,nM);
            CLa_vec = zeros(1,nM);
        
            for im = 1:nM
                Mval = mvec(im);
                [c1, c2, ca] = obj.calcCL(Mval);
                CL_max_clean_vec(im)   = c1;
                CL_max_flapped_vec(im) = c2;
                CLa_vec(im)            = ca;
            end
        
            % --- Compute CD components for a representative CL (no CL dependence for CD_wave) ---
            CD_vec = zeros(1,nM);
            CD0_vec = zeros(1,nM);
            CDi_vec = zeros(1,nM);
            CDwave_vec = zeros(1,nM);
            for im = 1:nM
                Mval = mvec(im);
                [Cd, Cd0, Cdi, Cdw] = obj.calcCD(CL_for_CD, Mval);
                CD_vec(im)     = Cd;
                CD0_vec(im)    = Cd0;
                CDi_vec(im)    = Cdi;
                CDwave_vec(im) = Cdw;
            end
        
            % --- Compute CD vs Mach for each CL sample (Plot 4) and CDi too (Plot 5) ---
            nCL = numel(CL_values);
            CD_vsM   = zeros(nCL, nM);   % rows = CL_values, cols = mvec
            CDi_vsM  = zeros(nCL, nM);
            CDwave_vsM = zeros(nCL, nM); % optional; wave drag often independent of CL but keep if returned
            for ic = 1:nCL
                CLval = CL_values(ic);
                for im = 1:nM
                    Mval = mvec(im);
                    [Cd, Cd0, Cdi, Cdw] = obj.calcCD(CLval, Mval);
                    CD_vsM(ic, im) = Cd;
                    CDi_vsM(ic, im) = Cdi;
                    CDwave_vsM(ic, im) = Cdw;
                end
            end
        
            % --- Compute drag polars (CL vs CD) for selected Mach samples (Plot 6) ---
            CL_range = linspace(min([-0.5, min(CL_values)]), max([1.5, max(CL_values), max(CL_max_clean_vec)]), 300);
            nCLr = length(CL_range);
            CD_polars = zeros(length(M_samples), nCLr); % rows => each Mach, columns => CL_range
            for im = 1:length(M_samples)
                Mval = M_samples(im);
                for j = 1:nCLr
                    CLval = CL_range(j);
                    Cd = obj.calcCD(CLval, Mval); % assume first output is total CD
                    if iscell(Cd) % if calcCD returns as cell (unlikely) handle gracefully
                        Cd = Cd{1};
                    end
                    CD_polars(im, j) = Cd;
                end
            end
        
            % --- PLOTTING ---
            figure('Color','w','Position',[100 100 1200 900]); % white figure background for clean plots
            t = tiledlayout(3,2,'TileSpacing','compact','Padding','compact');
        
            % consistent color map for CL series
            cmap = lines(max(nCL, length(M_samples)));
        
            % Plot 1: CLa vs Mach
            ax1 = nexttile;
            p1 = plot(ax1, mvec, CLa_vec, 'k-', 'LineWidth', lw);
            xlabel(ax1, 'Mach'); ylabel(ax1, 'C_{L_\alpha} [1/rad]');
            title(ax1, '3D Lift-Curve Slope vs Mach');
            xlim(ax1, [min(mvec) m_end]);
            grid(ax1, 'on');
            h1 = legend(ax1, 'C_{L\alpha}', 'Location','best'); set(h1,'Color','w','TextColor','k');
        
            % Plot 2: CL_max clean & flapped vs Mach
            ax2 = nexttile;
            hold(ax2,'on');
            plot(ax2, mvec, CL_max_clean_vec, 'b-', 'LineWidth', lw, 'DisplayName','CL_{max} (clean)');
            plot(ax2, mvec, CL_max_flapped_vec, 'r--', 'LineWidth', lw, 'DisplayName','CL_{max} (flapped)');
            xlabel(ax2, 'Mach'); ylabel(ax2, 'C_{L,max}');
            title(ax2, 'C_{L,max} vs Mach');
            xlim(ax2, [min(mvec) m_end]);
            grid(ax2,'on');
            h2 = legend(ax2, 'Location','best'); set(h2,'Color','w','TextColor','k');
            hold(ax2,'off');
        
            % Plot 3: CD_wave vs Mach (single curve)
            ax3 = nexttile;
            plot(ax3, mvec, CDwave_vec, 'm-', 'LineWidth', lw);
            xlabel(ax3, 'Mach'); ylabel(ax3, 'C_{D, wave}');
            title(ax3, 'Wave Drag (C_{D, wave}) vs Mach');
            xlim(ax3, [min(mvec) m_end]);
            grid(ax3,'on');
            h3 = legend(ax3, 'C_{D, wave}', 'Location','best'); set(h3,'Color','w','TextColor','k');
        
            % Plot 4: Total CD vs Mach for several CLs
            ax4 = nexttile;
            hold(ax4,'on');
            for ic = 1:nCL
                plot(ax4, mvec, CD_vsM(ic,:), 'LineWidth', lw, 'Color', cmap(ic,:), ...
                    'DisplayName', sprintf('C_L = %.2f', CL_values(ic)));
            end
            xlabel(ax4, 'Mach'); ylabel(ax4, 'C_D');
            title(ax4, 'Total C_D vs Mach (various C_L)');
            xlim(ax4, [min(mvec) m_end]);
            grid(ax4,'on');
            h4 = legend(ax4, 'Location','best'); set(h4,'Color','w','TextColor','k');
            hold(ax4,'off');
        
            % Plot 5: Induced drag CDi vs Mach for several CLs
            ax5 = nexttile;
            hold(ax5,'on');
            for ic = 1:nCL
                plot(ax5, mvec, CDi_vsM(ic,:) / (CL_values(ic)^2), 'LineWidth', lw, 'Color', cmap(ic,:), ...
                    'DisplayName', sprintf('C_L = %.2f', CL_values(ic)));
            end
            xlabel(ax5, 'Mach'); ylabel(ax5, 'C_{D,i} / C_L^2');
            title(ax5, 'Induced Drag vs Mach (various C_L)');
            xlim(ax5, [min(mvec) m_end]);
            grid(ax5,'on');
            h5 = legend(ax5, 'Location','best'); set(h5,'Color','w','TextColor','k');
            hold(ax5,'off');
        
            % Plot 6: Drag polars (C_D on x, C_L on y) for selected Mach numbers
            ax6 = nexttile;
            hold(ax6,'on');
            for im = 1:length(M_samples)
                plot(ax6, CD_polars(im,:), CL_range, 'LineWidth', lw, 'Color', cmap(im,:), ...
                    'DisplayName', sprintf('M = %.2f', M_samples(im)));
            end
            xlabel(ax6, 'C_D'); ylabel(ax6, 'C_L');
            title(ax6, 'Drag Polars (C_L vs C_D) at selected Mach numbers');
            grid(ax6,'on');
            h6 = legend(ax6, 'Location','best'); set(h6,'Color','w','TextColor','k');
            ylim([0 2])
            hold(ax6,'off');
        
            % overall title
            sgtitle(t, sprintf('Aerodynamic Polars (%s) — Mach range [%.2f, %.2f]', obj.name, obj.mach_range(1), obj.mach_range(2)));
        end

    end
end