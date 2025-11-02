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

            obj.mach_range = [0.2 2];
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
        
        %% Some helpful functions to generate debug plots
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
        function buildPerformance(obj)
            % buildPerformance - performance maps using existing class methods
            %
            % Uses:
            %   [CL_max_clean, CL_max_flapped, CLa] = obj.calcCL(M)
            %   [CD_total, CD0, CDi, CD_wave] = obj.calcCD(CL, M)
            %   [q, V, a, rho] = metricFreestream(h, M)
            %   [TA, TSFC, alpha] = engine_query(obj.engine, M, h, AB_perc)
            %
            % Plots:
            %   1) n_max vs Mach for a set of altitude_samples (y-limit 20, yline 6.5G)
            %   2) Drag vs Mach for same altitudes with TA dashed overlay (legend shows "TA ---")
            %   3) Excess (TA - D)/W as filled contour, red contour where excess = 0, colorbar >= 0
            %   4) Max achievable Mach per altitude using fzero solving TA(M,h) - D(M,h) = 0
        
            % --------- User parameters ----------
            altitude_samples = [0, 10000, 20000, 30000, 40000]; % altitudes for lines (ft)
            Nh = 40;                                           % altitude resolution for contour/solve
            Nm = 160;                                          % Mach resolution for sweeps
            hvec_m = linspace(0, ft2m(40000), Nh);            % altitudes (m) for maps
            mvec = linspace(obj.mach_range(1), obj.mach_range(2), Nm); % Mach sweep for maps
            AB_perc = 0;                                       % afterburner fraction
            Sref = obj.S_ref;
            W0 = obj.W0;                                       % assume weight in N
        
            lw = 2; % line width
        
            % --------- Precompute CL_max_clean vs Mach (function of M only) ----------
            CLmax_clean_vec = zeros(1, Nm);
            for im = 1:Nm
                Mval = mvec(im);
                [c1, ~, ~] = obj.calcCL(Mval);
                CLmax_clean_vec(im) = c1;
            end
        
            % --------- Preallocate maps ----------
            [Mgrid, Hgrid] = meshgrid(mvec, hvec_m); % size Nh x Nm
            n_max_map   = nan(size(Mgrid)); % max load factor
            Dmap        = nan(size(Mgrid)); % drag (N)
            TAmap       = nan(size(Mgrid)); % thrust available (N)
            excess_map  = nan(size(Mgrid)); % (TA - D) / W (dimensionless)
        
            % Evaluate grid: dynamic pressure q via metricFreestream, engine_query for TA
            for ih = 1:length(hvec_m)
                h = hvec_m(ih);
                for im = 1:length(mvec)
                    M = mvec(im);
        
                    % Atmosphere / freestream
                    try
                        [q, V, ~, rho] = metricFreestream(h, M); % q in Pa, V in m/s
                    catch
                        % If metricFreestream isn't available, skip this grid point
                        q = NaN; V = NaN; rho = NaN;
                    end
        
                    % CL_max (clean) from calcCL (function of M)
                    CLmax = interp1(mvec, CLmax_clean_vec, M, 'linear', NaN);
        
                    % Lmax and n_max
                    if ~isnan(q) && ~isnan(CLmax) && Sref>0 && W0>0
                        Lmax = q * Sref * CLmax; % N
                        n_max_map(ih,im) = Lmax / W0;
                    else
                        n_max_map(ih,im) = NaN;
                    end
        
                    % Drag for level flight: compute CL_level = W/(q*S)
                    if ~isnan(q) && q>0
                        CL_level = W0 / (q * Sref);
                        % enforce plausible CL_level bounds (prevent crazy values)
                        if CL_level > 10 || CL_level < -10
                            CL_level = NaN;
                        end
                    else
                        CL_level = NaN;
                    end
        
                    % Get CD at CL_level (if valid)
                    if ~isnan(CL_level)
                        try
                            [CD_tot, CD0, CDi, CDw] = obj.calcCD(CL_level, M);
                            % If calcCD returns multiple outputs, CD_tot is total CD
                            % D = q * S * CD
                            D = q * Sref * CD_tot;
                        catch
                            D = NaN;
                        end
                    else
                        D = NaN;
                    end
                    Dmap(ih,im) = D;
        
                    % Thrust available from engine model
                    try
                        [TA, ~, ~] = engine_query(obj.engine, M, h, AB_perc); % returns N
                    catch
                        TA = NaN;
                    end
                    TAmap(ih,im) = TA;
        
                    % Excess normalized by weight (dimensionless)
                    if ~isnan(TA) && ~isnan(D) && W0>0
                        excess_map(ih,im) = (TA - D) / W0;
                    else
                        excess_map(ih,im) = NaN;
                    end
                end
            end
        
            % --------- Plotting: 2x2 layout ----------
            figure('Color','w','Position',[120 80 1400 900]);
            t = tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
        
            % Convert altitudes for plotting (ft) for labels & samples
            altitude_samples_m = altitude_samples * 0.3048; % convert ft->m for matching indices
            % find nearest indices in hvec_m for those requested sample altitudes
            idx_samples = zeros(size(altitude_samples_m));
            for k = 1:length(altitude_samples_m)
                [~, idx_samples(k)] = min(abs(hvec_m - altitude_samples_m(k)));
            end
        
            % ---------- Plot 1: Max load factor vs Mach for altitude_samples ----------
            ax1 = nexttile;
            hold(ax1,'on'); grid(ax1,'on');
            cmap = lines(length(idx_samples));
            for k = 1:length(idx_samples)
                idx = idx_samples(k);
                hft = altitude_samples(k);
                plot(ax1, mvec, n_max_map(idx,:), 'LineWidth', lw, 'Color', cmap(k,:), ...
                    'DisplayName', sprintf('%.0f ft', hft));
            end
            % y-limit and 6.5G line
            ylim(ax1, [0 20]);
            yline(ax1, 6.5, '--r', '6.5G', 'LabelHorizontalAlignment','left', 'LineWidth', 1.5);
            xlabel(ax1, 'Mach'); ylabel(ax1, 'n_{max}');
            title(ax1, 'Max Load Factor vs Mach');
            xlim(ax1, [min(mvec) obj.mach_range(2)]);
            legend(ax1,'Location','best');
            hold(ax1,'off');
        
            % ---------- Plot 2: Drag vs Mach for multiple altitudes; overlay TA dashed ----------
            ax2 = nexttile;
            hold(ax2,'on'); grid(ax2,'on');
            for k = 1:length(idx_samples)
                idx = idx_samples(k);
                hft = altitude_samples(k);
                plot(ax2, mvec, Dmap(idx,:), 'LineWidth', lw, 'Color', cmap(k,:), ...
                    'DisplayName', sprintf('D (%.0f ft)', hft));
            end
            % Plot TA as dashed lines for the same altitudes (but create only one legend entry for TA)
            TA_handles = gobjects(length(idx_samples),1);
            for k = 1:length(idx_samples)
                idx = idx_samples(k);
                TA_handles(k) = plot(ax2, mvec, TAmap(idx,:), '--', 'LineWidth', lw, 'Color', cmap(k,:));
            end
            % Now construct legend: all D entries + one TA entry labelled 'TA ---'
            % Build legend labels: D labels then TA single label
            D_labels = arrayfun(@(k) sprintf('D (%.0f ft)', altitude_samples(k)), 1:length(idx_samples), 'UniformOutput', false);
            % Create an invisible line to use for a single TA legend entry (dashed)
            dummyTA = plot(ax2, NaN, NaN, '--k', 'LineWidth', lw);
            legend(ax2, [findall(ax2,'Type','line','-not','DisplayName','')], 'Location', 'best'); %#ok<UNRCH>
            % Instead create legend explicitly:
            legend(ax2, [findobj(ax2,'DisplayName',D_labels{1}), findobj(ax2,'DisplayName',D_labels{2}), ...
                         findobj(ax2,'DisplayName',D_labels{3}), findobj(ax2,'DisplayName',D_labels{4}), ...
                         findobj(ax2,'DisplayName',D_labels{5}), dummyTA], ...
                         [D_labels, {'TA ---'}], 'Location','best');
            xlabel(ax2, 'Mach'); ylabel(ax2, 'Force [N]');
            title(ax2, 'Drag vs Mach with Thrust Available (dashed)');
            xlim(ax2, [min(mvec) obj.mach_range(2)]);
            hold(ax2,'off');
        
            % ---------- Plot 3: Excess (TA - D)/W filled contour with zero contour in red ----------
            ax3 = nexttile;
            % Plot filled contour; ensure colorbar starts at 0
            surf(ax3, Mgrid, Hgrid/0.3048, max(excess_map,0), 'EdgeColor','none'); % Hgrid converted to ft for display
            view(ax3,2); colormap(ax3, parula);
            cmax = max(excess_map(:),[],'omitnan');
            if isempty(cmax) || cmax<=0
                cmax = 1e-6;
            end
            caxis(ax3, [0 cmax]);
            colorbar(ax3);
            hold(ax3,'on');
            % Red contour for zero excess; if data range spans zero, draw
            try
                contour(ax3, Mgrid, Hgrid/0.3048, excess_map, [0 0], 'r', 'LineWidth', 2);
            catch
                % If contour fails due to NaNs, ignore
            end
            xlabel(ax3, 'Mach'); ylabel(ax3, 'Altitude [ft]');
            title(ax3, '(T_A - D) / W (excess)'); xlim(ax3, [min(mvec) obj.mach_range(2)]);
            hold(ax3,'off');
        
            % ---------- Plot 4: Solve precisely for Mach where TA = D using fzero (smooth boundary) ----------
            ax4 = nexttile;
            hold(ax4,'on'); grid(ax4,'on');
            maxMach_per_h = nan(size(hvec_m));
            for ih = 1:length(hvec_m)
                h = hvec_m(ih);
                % Define residual function: TA(M) - D(M)
                f = @(M) residual_T_minus_D(M, h, obj, Sref, W0, AB_perc, mvec);
                % find sign changes in sample to bracket root
                rvals = arrayfun(@(M) f(M), mvec);
                % find indices where sign changes or rvals >= 0
                idxGood = find(~isnan(rvals));
                rootM = NaN;
                if ~isempty(idxGood)
                    signChangeIdx = find(sign(rvals(1:end-1)) .* sign(rvals(2:end)) < 0);
                    if ~isempty(signChangeIdx)
                        % bracket around the first sign change near max mach (choose last sign change)
                        br = signChangeIdx(end);
                        a = mvec(br); b = mvec(br+1);
                        try
                            rootM = fzero(f, [a b]);
                        catch
                            rootM = NaN;
                        end
                    else
                        % no sign change: maybe TA >= D over some region; choose max M where residual >= 0
                        idxPos = find(rvals >= 0);
                        if ~isempty(idxPos)
                            rootM = mvec(max(idxPos));
                        else
                            rootM = NaN;
                        end
                    end
                end
                maxMach_per_h(ih) = rootM;
            end
            % Plot Mach vs altitude (convert alt to ft for x-axis)
            plot(ax4, maxMach_per_h, hvec_m/0.3048, '-k', 'LineWidth', lw);
            xlabel(ax4, 'Mach'); ylabel(ax4, 'Altitude [ft]');
            title(ax4, 'Max Achievable Mach (T_A = D)');
            xlim(ax4, [min(mvec) obj.mach_range(2)]);
            hold(ax4,'off');
        
            sgtitle(t, sprintf('Performance Maps (%s)', obj.name));
        end
        
        %% Helper function (nested or local file)
        function r = residual_T_minus_D(M, h, obj, Sref, W0, AB_perc, mvec)
            % compute residual TA(M,h) - D(M,h) in N
            % If metricFreestream or calcCD fails, return NaN
            try
                [q, V, ~, rho] = metricFreestream(h, M);
            catch
                r = NaN; return;
            end
            if isnan(q) || q<=0
                r = NaN; return;
            end
        
            % Thrust available
            try
                [TA, ~, ~] = engine_query(obj.engine, M, h, AB_perc);
            catch
                r = NaN; return;
            end
        
            % Level-flight CL
            CL_level = W0 / (q * Sref);
        
            % Get CD at that CL and Mach
            try
                [CD_tot, ~, ~, ~] = obj.calcCD(CL_level, M);
            catch
                r = NaN; return;
            end
        
            D = q * Sref * CD_tot;
            r = TA - D;
        end


    end
end