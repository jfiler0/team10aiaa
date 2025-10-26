classdef plane_class
    properties
        name

        mw_right
        mw_left
        vt_right
        vt_left
        ht_right
        ht_left

        CG
        W0
    end

    methods
        function obj = plane_class(name)
            obj.name = name;

            naca2412 = foil_class("NACA2412", 0.75, false);

            mw0(1) = 5.36706; % Root Chord
            mw0(2) = 1.61758; % Tip Chord
            mw0(3) = 6.59843; % Span
            mw0(4) = 27.28571; % Sweep
            mw0(5) = 9.59; % XPOS
            mw0(6) = 0; % YPOS
            mw0(7) = -0.635; % ZPOS
            mw0(8) = 2.705; % XROT
            mw0(9) = 0; % YROT
            
            mw_cntl_surfaces = [0.1 0.5 ; 0.7 0.8];
            
            obj.mw_right = surface_class(mw0, naca2412, mw_cntl_surfaces, false);
            obj.mw_left = obj.mw_right.mirror_me();
            
            vt0(1) = 3.22619; % Root Chord
            vt0(2) = 1.18056; % Tip Chord
            vt0(3) = 2.9592; % Span
            vt0(4) = 38.35714; % Sweep
            vt0(5) = 5.410; % XPOS
            vt0(6) = 1.178; % YPOS
            vt0(7) = -0.205; % ZPOS
            vt0(8) = -73.548; % XROT
            vt0(9) = 0; % YROT
            
            vt_cntl_surfaces = [0.1 0.9];
            
            obj.vt_right = surface_class(vt0, naca2412, vt_cntl_surfaces, false);
            obj.vt_left = obj.vt_right.mirror_me();
            
            ht0(1) = 3.34524; % Root Chord
            ht0(2) = 1.31944; % Tip Chord
            ht0(3) = 3.66942; % Span
            ht0(4) = 45.60714; % Sweep
            ht0(5) = 4.426; % XPOS
            ht0(6) = 0; % YPOS
            ht0(7) = -0.205; % ZPOS
            ht0(8) = 1.557; % XROT
            ht0(9) = 0; % YROT
            
            ht_cntl_surfaces = [0.1 0.9];
            
            obj.ht_right = surface_class(ht0, naca2412, ht_cntl_surfaces, false);
            obj.ht_left = obj.ht_right.mirror_me();

            obj.CG = [7.539 0 -0.44];
            obj.W0 = 120000;% Approx F18E weight in N
        end
        function [F, M] = queryPlane(obj, V, W, h, deflections, debug)

            if(debug)
                figure;
                ax = axes;
            else
                ax = NaN;
            end

            % deflections = [flaps, ailerons, rudder, elevator]
            if(length(deflections) ~= 4)
                error("Inccorect number of deflections.")
            end

            flaps = deflections(1);
            aileron = deflections(2);
            rudder = deflections(3);
            elevator = deflections(4);
            
            [F_mwr, M_mwr] = obj.mw_right.queryWing([flaps -aileron], V, W, h, obj.CG, ax);
            [F_mwl, M_mwl] = obj.mw_left.queryWing([flaps aileron], V, W, h, obj.CG, ax);
            
            [F_vtr, M_vtr] = obj.vt_right.queryWing(rudder, V, W, h, obj.CG, ax);
            [F_vtl, M_vtl] = obj.vt_left.queryWing(-rudder, V, W, h, obj.CG, ax);
            
            [F_htr, M_htr] = obj.ht_right.queryWing(-elevator, V, W, h, obj.CG, ax);
            [F_htl, M_htl] = obj.ht_left.queryWing(-elevator, V, W, h, obj.CG, ax);
            
            F = F_mwr + F_mwl + F_vtr + F_vtl + F_htr + F_htl;
            M = M_mwr + M_mwl + M_vtr + M_vtl + M_htr + M_htl;

        end

        function [deflections, alpha, beta] = trimAircraft(obj, Vmag, W, h, F0, M0, debug)
            % TRIMAIRCRAFT trims the aircraft by solving for control surface
            % deflections, angle of attack (alpha), and sideslip (beta).
            %
            % Inputs:
            %   Vmag  - airspeed magnitude [m/s]
            %   W     - body angular velocity [rad/s] (3x1)
            %   h     - altitude [m]
            %   F0    - target net force in body frame [N] (3x1)
            %   M0    - target net moment in body frame [Nm] (3x1)
            %   debug - (optional) bool: if true, generate sensitivity plots
            %
            % Outputs:
            %   deflections - vector of surface deflections [deg] (1x4)
            %   alpha       - trimmed AoA [deg]
            %   beta        - trimmed sideslip [deg]
            
                if nargin < 7 || isempty(debug)
                    debug = false;
                end
            
                % Initial guess: [flaps, aileron, rudder, elevator, alpha(rad), beta(rad)]
                x0 = [0 0 0 0  0  0];
            
                % Bounds
                max_def = 1.5 * getSetting("SURFACE_DEFLECTION"); % degrees
                lb = [-max_def, -max_def, -max_def, -max_def, deg2rad(-15), deg2rad(-10)];
                ub = [ max_def,  max_def,  max_def,  max_def, deg2rad( 20), deg2rad( 10)];
            
                % Objective function (nested so it has access to obj, Vmag, W, h, F0, M0)
                function res = objective(x)
                    defl = x(1:4);        % degrees
                    alpha = x(5);         % radians
                    beta  = x(6);         % radians
            
                    % Construct velocity vector from Vmag, alpha, beta (body coords)
                    V = [cos(alpha)*cos(beta);
                         sin(beta);
                         sin(alpha)*cos(beta)] * Vmag;
            
                    [F, M] = obj.queryPlane(V, W, h, defl, false);
            
                    % Errors
                    Mdif = norm(M - M0);
                    Fdif = norm(F - F0);
            
                    % Composite cost (simple sum)
                    res = Fdif + Mdif;

                    Y = [0 F(2) 0]; % Side force
                    D = proj(F-Y, -V); % Drag

                    res = res + norm(D)*1e4; % Add a penalty so it tunes for lower drag
                    % res = Mdif;
                end
            
                % Optimization options
                options = optimoptions('fmincon', ...
                                       'Display','iter', ...
                                       'Algorithm','sqp', ...
                                       'OptimalityTolerance',1e-6, ...
                                       'StepTolerance',1e-6, ...
                                       'FiniteDifferenceStepSize',1e-5);
            
                % Run optimization
                xopt = fmincon(@objective, x0, [], [], [], [], lb, ub, [], options);
            
                % Extract & convert results
                deflections = xopt(1:4);          % degrees
                alpha = rad2deg(xopt(5));         % deg
                beta  = rad2deg(xopt(6));         % deg
            
                % Helpful printout
                fprintf('\nTrimmed solution:\n');
                fprintf('  Alpha   = %.4f deg\n', alpha);
                fprintf('  Beta    = %.4f deg\n', beta);
                fprintf('  Flaps   = %.4f deg\n', deflections(1));
                fprintf('  Aileron = %.4f deg\n', deflections(2));
                fprintf('  Rudder  = %.4f deg\n', deflections(3));
                fprintf('  Elevator= %.4f deg\n\n', deflections(4));
            
                % ---------------------
                % Debug sensitivity plot
                % ---------------------
                if debug
                    % Variation range in degrees
                    delta_deg = linspace(-0.05, 0.05, 201); % +/- 0.5 deg in 0.025 deg steps
                    nVar = numel(xopt);
                    res_mat = zeros(nVar, numel(delta_deg));
            
                    % For each variable, vary around xopt and compute objective
                    for iv = 1:nVar
                        for k = 1:numel(delta_deg)
                            dx_deg = delta_deg(k);
            
                            % Build new candidate x
                            xtest = xopt;
            
                            if iv <= 4
                                % deflections (deg): add dx directly
                                xtest(iv) = xopt(iv) + dx_deg;
                            else
                                % alpha/beta are stored in radians in x; convert dx to rad
                                xtest(iv) = xopt(iv) + deg2rad(dx_deg);
                            end
            
                            % Evaluate objective
                            res_mat(iv,k) = objective(xtest);
                        end
                    end
            
                    % Plot results: one curve per variable
                    figure;
                    hold on; grid on;
                    colors = lines(nVar);
                    labels = {'Flaps','Aileron','Rudder','Elevator','Alpha','Beta'};
                    for iv = 1:nVar
                        plot(delta_deg, res_mat(iv,:), '-', 'Color', colors(iv,:), 'LineWidth', 1.5);
                    end
                    xlabel('Perturbation $\Delta$ (deg)');
                    ylabel('Objective ($F_{err}$ + $M_{err}$)');
                    title('Trim sensitivity: vary each design variable about trimmed point');
                    legend(labels, 'Location', 'best');
                    xline(0, '--k');
                    hold off;
            
                    % Also show minima per variable (where res is smallest)
                    for iv = 1:nVar
                        [minval, idx] = min(res_mat(iv,:));
                        fprintf('Variable %s: min objective = %.4e at delta = %.3f deg\n', labels{iv}, minval, delta_deg(idx));
                    end
                end
            end

        function characterizePlane(obj, Vmag, alphas, deltas, hVals, surfaceIdx, outputIdx)
            % CHARACTERIZEPLANE: Sweep plane across alpha, one control surface, and altitude
            %
            % Inputs:
            %   Vmag       - fixed airspeed magnitude [m/s]
            %   alphas     - vector of alphas to look at
            %   nDelta     - vector of deltas to look at
            %   hVals      - vector of altitudes [m] to sweep
            %   surfaceIdx - index of control surface to vary (1=flaps, 2=aileron, 3=rudder, 4=elevator)
            %   F or M output - [F(1) F(2) F(3) M(1) M(2) M(3)]
            %
  
                % --- Allocate storage
                cmap = lines(numel(hVals));
                legends = cell(1,numel(hVals));
            
                % --- Figure
                figure; hold on
            
                for hIdx = 1:numel(hVals)
                    h = hVals(hIdx);
                    OUT = zeros(length(alphas), length(deltas));
            
                    for i = 1:length(alphas)
                        alpha = deg2rad(alphas(i));
            
                        for j = 1:length(deltas)
                            deflections = zeros(1,4);
                            deflections(surfaceIdx) = deltas(j);
            
                            % Build velocity vector for this alpha, fixed beta=0
                            V = [cos(alpha); 0; sin(alpha)] * Vmag;
                            W = [0 0 0]; % no rotation
            
                            [F, M] = obj.queryPlane(V, W, h, deflections, false);
            
                            % Extract Lift: subtract drag (along -V) and side (Y-axis)
                            outVec = [F(1) F(2) F(3) M(1) M(2) M(3)];
                            OUT(i,j) = outVec(outputIdx);
                        end
                    end
            
                    % Mesh for surface plot
                    [Agrid, Dgrid] = meshgrid(alphas, deltas);
                    
                    % Flatten the data for filtering
                    vals = OUT(:);
                    
                    % Compute 2.5th and 97.5th percentiles (keeps 95% of the data)
                    lowCut  = prctile(vals, 5);
                    highCut = prctile(vals, 95);
                    
                    % Clip data outside the range
                    OUT_filt = OUT;
                    OUT_filt(OUT < lowCut)  = lowCut;
                    OUT_filt(OUT > highCut) = highCut;
                    
                    % Plot surface: X=alpha, Y=deflection, Z=Lift (filtered)
                    surf(Agrid, Dgrid, OUT_filt', 'FaceAlpha',0.7, ...
                         'EdgeColor','none', 'FaceColor', cmap(hIdx,:));
                    
                    legends{hIdx} = sprintf('h = %.0f m', h);
                end
            
                % --- Formatting
                xlabel('$\alpha$ [deg]', 'Interpreter','latex')
                ylabel('Deflection [deg]', 'Interpreter','latex')
                zlabel('F or M [N or Nm]', 'Interpreter','latex')
                legend(legends, 'Location','best')
                grid on
                title('Plane Characterization (F or M output vs $\alpha$, Deflection, h)', 'Interpreter','latex')
                view(45,30)
            end
            
            
    end
end

function R = proj(A, B)
    % Projection of A onto B
    R = (dot(A, B) / norm(B)^2) * B;
end

% Any useful functions