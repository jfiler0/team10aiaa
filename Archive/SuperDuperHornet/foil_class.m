classdef foil_class
    properties
        name       % Name, e.g. 'NACA2412'
        data_file  % Full file path to .dat file
        % It is important this dat file is of high quality and resolution
        coords     % [N x 2] array of [x y] coordinates
        hinge_loc

        Cl_interp
        Cd_interp
        Cm_interp
    end
    
    methods
        % Constructor
        function obj = foil_class(name, hinge_loc, reload)
            % name is main argument that is selection of the .dat and .mat files
            % if reload is true, it will ALWAYS refresh the .mat file (expensive)
            % if reload is false, is will only reload the .mat file if it does not exist. Otherwise new inputs/settings will not be included
            % until it is run with reload as true

            if nargin < 1
                error('Must provide airfoil name, e.g. foil("NACA2412").');
            end

            if(reload==false) % Attempt to get the file
                projDir = fileparts(mfilename('fullpath')); % class folder
                foilFile = fullfile(projDir, name + ".mat");
                if isfile(foilFile)
                    loaded = load(foilFile);
                    obj = loaded.foilData;
                    fprintf('Loaded foil data from %s\n', foilFile);
                else
                    % There is no file so it needs to reload
                    reload = true;
                end
            end
            if(reload)
                obj.name = name;
                obj.hinge_loc = hinge_loc;

                process_airfoil(name, true, 1, 0);
    
                % Find the folder where this class is stored
                classDir = fileparts(mfilename('fullpath'));
                obj.data_file = fullfile(classDir, name + ".dat");
                
                if ~isfile(obj.data_file)
                    error('Airfoil file "%s" not found in folder: %s', ...
                          name + ".dat", classDir);
                end
                
                coords = readmatrix(obj.data_file);
                if size(coords,2) ~= 2
                    error('Airfoil file "%s" must have two numeric columns.', obj.data_file);
                end
                obj.coords = coords;
    
                obj = obj.fillFoilTable();
                
                obj.save();
            end
        end
        
        % Plot geometry
        function plotFoil(obj, varargin)
            plot(obj.coords(:,1), obj.coords(:,2), '-o', 'MarkerSize', 3, varargin{:});
            axis equal; grid on;
            xlabel('x'); ylabel('y');
            title(obj.name, 'Interpreter', 'none');
        end

        % Run XFOIL analysis and plot Cl-Cd-Cm-L/D
        function plotData(obj, M, alt, c, alpha_range, N)
            % M mach number to consider (just for setting reynolds number) -> no compresible corrections
            % alt in m
            % alpha_range -> length 2 vector of alpha_min and alpha_max
            % N is the alpha resolution

            %--- Atmosphere model
            [~, a, ~, rho] = queryAtmosphere(alt, [0 1 0 1]); % Mach calculation only
            U_inf = M * a;
            Re = rho * U_inf * c / (1.789e-5); % crude mu
        
            %--- Call XFOIL
            [alpha, Cl, Cd, Cm] = callXFOIL(obj, alpha_range, N, Re, 0.8, 20);
        
            %--- Compute L/D
            L_over_D = Cl ./ Cd;
        
            %--- Plot 1: Cl and Cd vs alpha
            figure('Name', sprintf('%s Aerodynamic Performance', obj.name), 'NumberTitle', 'off');
        
            subplot(1,3,1);
            yyaxis left
            plot(alpha, Cl, '-', 'LineWidth', 1.5); 
            ylabel('$C_L$', 'Interpreter', 'latex'); grid on;
            yyaxis right
            plot(alpha, Cd, '-', 'LineWidth', 1.5); 
            ylabel('$C_D$', 'Interpreter', 'latex');
            xlabel('$\alpha$ (deg)', 'Interpreter', 'latex'); 
            title('Lift and Drag vs Angle of Attack', 'Interpreter', 'latex');
        
            %--- Plot 2: Drag polar (Cd vs Cl)
            subplot(1,3,2);
            plot(Cd, Cl, '-', 'LineWidth', 1.5);
            xlabel('$C_D$', 'Interpreter', 'latex'); 
            ylabel('$C_L$', 'Interpreter', 'latex'); 
            grid on; title('Drag Polar', 'Interpreter', 'latex');
        
            %--- Plot 3: L/D and Cm vs alpha
            subplot(1,3,3);
            yyaxis left
            plot(alpha, L_over_D, '-', 'LineWidth', 1.5); 
            ylabel('$L/D$', 'Interpreter', 'latex'); grid on;
            yyaxis right
            plot(alpha, Cm, '-', 'LineWidth', 1.5); 
            ylabel('$C_m$', 'Interpreter', 'latex');
            xlabel('$\alpha$ (deg)', 'Interpreter', 'latex'); 
            title('Lift-to-Drag Ratio and Moment vs Angle of Attack', 'Interpreter', 'latex');
        
            sgtitle(sprintf('%s at M=%.2f, Alt=%.0f m', obj.name, M, alt), 'Interpreter', 'latex');
        end

        function [alpha, Cl, Cd, Cm] = callXFOIL(obj, alpha_range, N, ReL, flap_xloc, flap_def)
            run_silent = true;
            %--- Directories
            projDir = fileparts(mfilename('fullpath')); % class folder
            xfoilDir = fullfile(projDir, 'XFOIL');
            if ~isfolder(xfoilDir)
                error('XFOIL folder not found: %s', xfoilDir);
            end
            xfoilExe = fullfile(xfoilDir, 'xfoil.exe');
            if ~isfile(xfoilExe)
                error('xfoil.exe not found in %s', xfoilDir);
            end

            %--- Filenames
            if(flap_xloc < 1) % Make a temporary foil with the flap in temp.dat
                process_airfoil(obj.name, false, obj.hinge_loc, flap_def);
                foilFile  = "temp.dat";
            else
                foilFile  = obj.name + ".dat";
            end
        
            polarFile = fullfile("XFOIL","polar.txt");
            inputFile = fullfile("XFOIL", "xfoil_input.txt");
        
            %--- Check foil file exists
            if ~isfile(fullfile(projDir, foilFile))
                error('Could not find foil data %s', foilFile);
            end
        
            %--- Remove existing polar file if it exists
            polarPath = fullfile(projDir, polarFile);
            if isfile(polarPath)
                delete(polarPath);
            end

            num_decimals = 4;
            alpha_start = round(alpha_range(1), num_decimals);
            alpha_int = round((alpha_range(2) - alpha_start)/(N-1), num_decimals);
            alpha_end = alpha_start + (N-1)*alpha_int;
        
            %--- Build XFOIL input deck
            fid = fopen(fullfile(projDir, inputFile), 'w');
            if fid < 0, error('Could not create input file.'); end
            fprintf(fid, 'LOAD %s\n\n', foilFile);
            fprintf(fid, 'PANE\n');
            fprintf(fid, 'PSPLINE\n');
            % fprintf(fid, 'NACA\n2412\n');
            % if(do_flap)
            %     fprintf(fid, 'GDES\n');
            %     fprintf(fid, 'FLAP\n%.6f\n%.0f\n%.4f\n%0.3f\n', flap_xloc, 999, 0.5, flap_def);
            %     fprintf(fid, 'EXEC\n\n');
            % end
            fprintf(fid, 'OPER\n');
            fprintf(fid, 'ITER %.0f\n', getSetting("XFOIL_ITER_LIMIT"));           % set max iterations
            % fprintf(fid, 'INIT\n');
            fprintf(fid, 'VISC %.0f\n', ReL);
            fprintf(fid, 'MACH %.3f\n', 0);
            fprintf(fid, 'PACC\n');
            fprintf(fid, '%s\n\n', polarFile);   % blank line required
            fprintf(fid, 'ASEQ %.4f %.4f %.4f\n', ...
                alpha_start, alpha_end, alpha_int);
            fprintf(fid, 'PACC\n\n');
            fprintf(fid, 'QUIT\n');
            fclose(fid);
        
            %--- Run XFOIL in project folder
            oldDir = pwd;
            cd(projDir);

            if(run_silent)
                system(sprintf('"%s" < "%s" > nul 2>&1', xfoilExe, inputFile));
            else
                system(sprintf('"%s" < "%s"', xfoilExe, inputFile));
            end

            cd(oldDir);
        
            %--- Check polar file
            if ~isfile(polarPath)
                error('Polar file not generated. Check XFOIL run.');
            end
        
            %--- Read polar
            data = readmatrix(polarPath, 'FileType', 'text');
            if isempty(data) || size(data,2) < 3
                error('Polar file empty or bad format.');
            end
            alpha = data(:,1); Cl = data(:,2); Cd = data(:,3); Cm = data(:,5);
        
        end

        function obj = fillFoilTable(obj)
            % Load user settings
            alpha_res = getSetting('ALPHA_RESOLUTION');
            alpha_min = getSetting('ALPHA_MIN');
            alpha_max = getSetting('ALPHA_MAX');
            Re_min    = getSetting('RE_MIN');
            Re_max    = getSetting('RE_MAX');
            Re_res    = getSetting('RE_RES');
            d_max     = getSetting('SURFACE_DEFLECTION');
            d_res     = getSetting('SURF_DEF_RES');  % symmetric resolution
        
            % Generate vectors
            alpha_vec = linspace(alpha_min, alpha_max, alpha_res);
            Re_vec    = logspace(log10(Re_min), log10(Re_max), Re_res); % log-spaced Re
            def_vec   = linspace(-d_max, d_max, 2*d_res+1);             % symmetric deflections
        
            % Sizes
            N_alpha = length(alpha_vec);
            N_Re    = length(Re_vec);
            N_def   = length(def_vec);
        
            % Preallocate grids
            Cl_grid = zeros(N_alpha, N_Re, N_def);
            Cd_grid = zeros(N_alpha, N_Re, N_def);
            Cm_grid = zeros(N_alpha, N_Re, N_def);
        
            % Loop over Re and deflection
            for j = 1:N_Re
                Re_val = Re_vec(j);
        
                for k = 1:N_def
                    def_val = def_vec(k);
        
                    % Call XFOIL for this Re and deflection
                    [alpha_out, Cl_out, Cd_out, Cm_out] = callXFOIL(obj, ...
                        [alpha_min alpha_max], alpha_res, Re_val, obj.hinge_loc, def_val);
        
                    if length(alpha_out) ~= alpha_res
                        warning("\nAlpha Vec incomplete. %.0f / %.0f points returned (%.3f to %.3f deg) at Re=%.2e, δ=%.1f°", ...
                            length(alpha_out), alpha_res, min(alpha_out), max(alpha_out), Re_val, def_val);
                    end
        
                    % Interpolate onto alpha_vec for consistency
                    Cl_grid(:,j,k) = interp1(alpha_out, Cl_out, alpha_vec, 'linear', 'extrap');
                    Cd_grid(:,j,k) = interp1(alpha_out, Cd_out, alpha_vec, 'linear', 'extrap');
                    Cm_grid(:,j,k) = interp1(alpha_out, Cm_out, alpha_vec, 'linear', 'extrap');
                end
            end

            Cl_grid = smoothdata(Cl_grid,1,'movmean', 7); % smooth in alpha dim
            Cl_grid = smoothdata(Cl_grid,2,'movmean', 5); % smooth in Re dim
            Cl_grid = smoothdata(Cl_grid,3,'movmean', 2); % smooth in delta dim

        
            % Build 3D interpolants
            obj.Cl_interp = griddedInterpolant({alpha_vec, Re_vec, def_vec}, Cl_grid, 'pchip', 'linear');
            obj.Cd_interp = griddedInterpolant({alpha_vec, Re_vec, def_vec}, Cd_grid, 'pchip', 'linear');
            obj.Cm_interp = griddedInterpolant({alpha_vec, Re_vec, def_vec}, Cm_grid, 'pchip', 'linear');
        
            fprintf('\nAirfoil lookup table built: %d α × %d Re × %d δ points.\n', ...
                N_alpha, N_Re, N_def);
        end

        function [Cl, Cd, Cm, Xcp] = queryFoil(obj, alpha, Re, delta, M)

            % Interpolate from the stored table

            Cl0 = obj.Cl_interp(alpha, Re, delta);
            Cd0 = obj.Cd_interp(alpha, Re, delta);
            Cm0 = obj.Cm_interp(alpha, Re, delta);
        
            %--- Prandtl-Glauert compressibility correction (subsonic)
            beta = sqrt(1 - M^2);       % beta = sqrt(1 - M^2)
            Cl = Cl0 / beta;
            Cd = Cd0 / beta;
            Cm = Cm0 / beta;
            Xcp = Cm/Cl + 0.25; % Center of pressure
            Xcp = min( [max([0 Xcp]), 1] ); % Helps when Cl is near 0. Phyiscally, Xcp must be on the airfoil.
        end

        function characterizeFoil(obj, nAlpha, nRe, nDelta)
            % characterizeFoil: Sweep foil across alpha, Re, and deflection
            % Inputs:
            %   nAlpha = number of alpha samples
            %   nRe    = number of Reynolds number samples
            %   nDelta = number of control surface deflection samples
            
            % --- Settings
            alpha_min = getSetting('ALPHA_MIN');
            alpha_max = getSetting('ALPHA_MAX');
            Re_min    = getSetting('RE_MIN');
            Re_max    = getSetting('RE_MAX');
            d_max     = getSetting('SURFACE_DEFLECTION');
            
            % --- Grids
            alphas = linspace(alpha_min, alpha_max, nAlpha);
            Res    = linspace(Re_min, Re_max, nRe);
            deltas = linspace(-d_max, d_max, nDelta);   % symmetric sweep
            
            Mach = 0;   % fixed
            
            % --- Loop over deltas
            figure; hold on
            cmap = lines(nDelta);  % distinct colors per delta
            
            for k = 1:nDelta
                delta = deltas(k);
                CL = zeros(nAlpha, nRe);
                
                for i = 1:nAlpha
                    for j = 1:nRe
                        alpha = alphas(i);
                        Re    = Res(j);
                        [Cl, ~, ~, ~] = obj.queryFoil(alpha, Re, delta, Mach);
                        CL(i,j) = Cl;
                    end
                end
                
                % Mesh for surface plot
                [Agrid, Rgrid] = meshgrid(alphas, Res);
                
                % Plot surface (X=alpha, Y=Re, Z=Cl)
                surf(Agrid, Rgrid, CL', 'FaceAlpha',0.7, ...
                    'EdgeColor','none', 'FaceColor', cmap(k,:));
                
                % Add legend entry
                legends{k} = sprintf('$\\delta$ = %.1f deg', delta);
            end
            
            % --- Formatting
            xlabel('$\alpha$ [deg]')
            ylabel('Re')
            zlabel('$C_L$')
            grid on
            legend(legends, 'Location','best')
            title('Foil Characterization ($C_L$ vs $\alpha$, Re, $\delta$)')
            view(45,30)
        end

        function save(obj)
            % Save the foil object to a .mat file in the current directory
            projDir = fileparts(mfilename('fullpath')); % class folder
            saveFile = fullfile(projDir, obj.name + ".mat"); % e.g., "NACA2412.mat"
            foilData = obj;  %Keep all properties
            save(saveFile, 'foilData');
            fprintf('Foil data saved to %s\n', saveFile);
        end
    end
end