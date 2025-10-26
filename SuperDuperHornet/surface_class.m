classdef surface_class
    properties
        root_chord % m
        tip_chord % m
        span % m
        sweep % deg

        xpos % Define where the leading edge of the root section of the wing is
        ypos
        zpos

        xrot % about central x axis which sets dihedral
        yrot % about rotated system y axis which sets incidence

        foil

        control_surfaces % 2D array. Rows define surfaces in [start_span / span, end_span/span]

        mirrored

        num_control_surfaces
        N
        section_spanwise_positions
        section_widths
        section_def_type
    end

    methods
        function obj = surface_class(x0, foil, control_surfaces, mirrored)
            obj.root_chord = x0(1);
            obj.tip_chord = x0(2);
            obj.span = x0(3);
            obj.sweep = x0(4);
            obj.xpos = x0(5);
            obj.ypos = x0(6);
            obj.zpos = x0(7);
            obj.xrot = x0(8);
            obj.yrot = x0(9);

            obj.control_surfaces = [control_surfaces];
            obj.foil = foil;

            obj.num_control_surfaces = size(control_surfaces, 1);

            obj.mirrored = mirrored;

            N_sec = 3; % Number of foils in each section
            obj.N = N_sec * obj.num_control_surfaces * 2 + N_sec;

            % Just a bunch of zeros
            obj.section_spanwise_positions = zeros([obj.N, 1]); % Note that 0 will be the first value anyways
            obj.section_widths = obj.section_spanwise_positions;
            obj.section_def_type = obj.section_spanwise_positions; % Note that 0 will be the first value anyways

            % Walk through each section and set its properties (do the last section at the end)
            for i = 1:obj.N
                % "section" will be the # of the control surface for the control surface AND the preceeding section
                section = ( (i-1) - mod((i-1), 2*N_sec) ) / (2*N_sec) + 1;
                num_in_section = mod((i-1), N_sec) + 1; % Is this the first, second, third, etc
                
                if(mod((i-1)/N_sec, 2) < 1)
                    obj.section_def_type(i) = 0; % Not a control surface
                else
                    % Set to 1 if it is the first control surface, 2 if the second, and so on
                    obj.section_def_type(i) = section;
                end

                if(i + N_sec > obj.N) % We are in the last section
                    span_end = 1;
                else % Still have to get to the next section
                    if( obj.section_def_type(i) > 0 ) % This is a control surface
                        span_end = control_surfaces(section, 2);
                    else % Not a control surface
                        span_end = control_surfaces(section, 1);
                    end
                end
                if(i > 1) % Only works if you can refernce the previous position
                    span_before = obj.section_spanwise_positions(i-1);
                    width = ( span_end - span_before - obj.section_widths(i-1)/2 ) / (N_sec - num_in_section + 1);
                    obj.section_spanwise_positions(i) = span_before + width/2 + obj.section_widths(i-1)/2;
                else % If this is the first one we have to take a different approach
                    width = span_end / N_sec;
                    obj.section_spanwise_positions(i) = width/2;
                end
                obj.section_widths(i) = width;
            end

        end
        function plotGeometry(obj, deflections, ax)
            hold(ax, 'on');
            axis(ax, 'equal'); grid(ax, 'on');
            xlabel(ax, 'X'); ylabel(ax, 'Y'); zlabel(ax, 'Z');
            title(ax, 'Wing Geometry Debug Plot');
        
            % Quick helpers
            root = obj.root_chord;
            tip = obj.tip_chord;
        
            % Chord taper function
            chordAt = @(eta) root + (tip-root)*eta;
        
            % Sweep: leading edge x offset
            LE_x = @(eta) -sind(obj.sweep) * eta * obj.span;
        
            % Build wing outline
            outline = [...
                0, 0, 0;...
                LE_x(1), obj.span, 0;...
                LE_x(1)-tip, obj.span, 0;...
                -root, 0, 0;...
                0, 0, 0];
        
            % Apply rotations + translations
            outline = obj.applyTransform(outline);
        
            % Plot wing outline
            plot3(ax, outline(:,1), outline(:,2), outline(:,3), 'k-', 'LineWidth', 2);
        
            % Section loop
            for i = 1:obj.N
                eta = obj.section_spanwise_positions(i);
                y = eta * obj.span;
        
                c = chordAt(eta);
                x_le = LE_x(eta);
                x_te = x_le - c;
        
                % Build section chord line (LE → TE)
                sec = [x_le, y, 0; x_te, y, 0];
        
                % Transform
                sec = obj.applyTransform(sec);
        
                % Color by type
                if obj.section_def_type(i) == 0
                    col = 'b'; % normal
                else
                    col = 'r'; % control surface hinge line
                end
        
                plot3(ax, sec(:,1), sec(:,2), sec(:,3), '-', 'Color', col, 'LineWidth', 1.5);
        
                % --- Control surface deflections
                if obj.section_def_type(i) ~= 0
                    delta = deflections(obj.section_def_type(i)); % deflection angle [deg]
                    if(~obj.mirrored)
                        delta = -delta;
                    end
                
                    % Hinge fraction along chord (0=LE, 1=TE)
                    hinge_frac = obj.foil.hinge_loc;
                
                    % Local chord endpoints
                    LE = [x_le, y, 0];
                    TE = [x_te, y, 0];
                
                    % Hinge line point (spanwise axis through section)
                    hinge_point = LE + hinge_frac * (TE - LE);
                
                    % Define hinge line in local coords: spanwise direction only
                    hinge_line = [hinge_point;
                                  hinge_point + [0, 1, 0]];   % +Y in local coords
                
                    % Transform hinge line + TE into body frame
                    hinge_line = obj.applyTransform(hinge_line);
                    TE_point   = obj.applyTransform(TE);
                
                    % Rotation axis = hinge line direction (spanwise axis)
                    axis_dir = hinge_line(2,:) - hinge_line(1,:);
                    axis_dir = -axis_dir / norm(axis_dir);
                
                    % Vector hinge → TE
                    v_TE = TE_point - hinge_line(1,:);
                
                    % Rotate v_TE about hinge axis by delta
                    theta = deg2rad(delta);
                    k = axis_dir(:);
                    v_rot = v_TE(:)*cos(theta) + cross(k,v_TE(:))*sin(theta) + k*(dot(k,v_TE(:)))*(1-cos(theta));
                
                    % New TE after deflection
                    TE_def = hinge_line(1,:) + v_rot';
                
                    % Plot the deflected surface
                    plot3(ax, [hinge_line(1,1) TE_def(1)], ...
                          [hinge_line(1,2) TE_def(2)], ...
                          [hinge_line(1,3) TE_def(3)], 'g-', 'LineWidth', 1.5);
                end

            end
        
            legend(ax, {'Wing outline','Chord lines (blue=normal, red=ctrl)','Deflected surfaces (green)'});
        end

        function [F_total, M_total] = queryWing(obj, deflections, V, W, h, ref_point, ax)
            % deflections: vector for each control surface
            % V, W: body velocity and angular velocity
            % h atmosphere to consider for an altitude in meters
            % ref_point -> for moments to be evaluated about
            % debug -> plots the wing and puts force vetors on every section

            if nargin >= 7 && ~isempty(ax) && isgraphics(ax, 'axes')
                obj.plotGeometry(deflections, ax)
            end
        
            [~, a, ~, rho, mu] = queryAtmosphere(h, [0 1 0 1 1]);

            F_total = zeros(1,3);
            M_total = zeros(1,3);
        
            for i = 1:obj.N
                %--- Section properties
                eta = obj.section_spanwise_positions(i);
                chord = obj.root_chord + (obj.tip_chord - obj.root_chord)*eta;
                span_sec = obj.section_widths(i) * obj.span;
                area = chord * span_sec;
        
                %--- Section position in body coords
                y_sec = eta * obj.span;
                x_sec = -sind(obj.sweep) * y_sec; % Is the leading edge the best reference point?
                z_sec = 0;
                P_sec = obj.applyTransform([x_sec, y_sec, z_sec]);
        
                %--- Local alpha
                [alpha_deg, ~, vrx, vry, vrz] = obj.findSectionAOA(P_sec, V, W);
                Vrel = [vrx, vry, vrz];
                vel = norm(Vrel);
                Vhat = Vrel / vel;

                ex_body = rotateVectorByWingTransforms(obj, [1;0;0]); % chord direction (body)
                ey_body = rotateVectorByWingTransforms(obj, [0;1;0]); % span direction (body)
                % Normalize (safety)
                ex_body = ex_body / norm(ex_body);
                ey_body = ey_body / norm(ey_body);
        
                % --- Ensure ey points to right (positive Y) — optional check
                % If dot(ey_body, [0;1;0]) < 0, flip ey_body (keeps handedness consistent)
                if dot(ey_body, [0;1;0]) < 0
                    ey_body = -ey_body;
                end
        
                % --- Drag direction: opposite local flow
                Ddir = -Vhat;  % unit
        
                % --- Lift direction: perpendicular to flow and approx in wing section plane
                % Compute candidate lift using cross product to ensure orthogonality:
                % lift_dir = cross(Vhat, ey_body) -> vector roughly along "surface normal", then
                % L_dir = cross(lift_dir, Vhat) to get vector perpendicular to Vhat and in plane spanned by Vhat and ey.
                n_vec = cross(Vhat, ey_body);
                if norm(n_vec) < 1e-8
                    % degenerate (flow parallel to span), fall back to using ex x ey
                    warning("This has not been validated")
                    Ldir = cross(ey_body, ex_body);
                else
                    Ldir = -n_vec;
                end
                Ldir = Ldir / norm(Ldir);
        
               
                %--- Local deflection
                if obj.section_def_type(i) == 0
                    delta = 0; % no control
                else
                    delta = deflections(obj.section_def_type(i));
                end

                %--- Local Re & Mach
                Re = rho * vel * chord / mu;
                M   = vel / a;
        
                %--- Query foil
                [Cl, Cd, ~, Xcp] = obj.foil.queryFoil(alpha_deg, Re, delta, M);

       
                %--- Dynamic pressure
                q = 0.5 * rho * vel^2;
        
                %--- Lift, Drag, Moment (section frame)
                L = Cl * q * area;
                D = Cd * q * area;
                % Mc = Cm * q * area * chord;  % pitching moment about quarter-chord
        
                %--- Express forces in section coordinates
                F_sec = D*Ddir + L*Ldir;
        
                % --- Aerodynamic center position: leading edge + Xcp*chord along ex_body
                AC_body = P_sec - (Xcp * chord) * ex_body'; % 3x1

                if nargin >= 7 && ~isempty(ax) && isgraphics(ax, 'axes')
                    scale = 0.00015/span_sec; % tune this for visibility
                    quiver3(ax, ...
                        AC_body(1), AC_body(2), AC_body(3), ...
                        F_sec(1)*scale, F_sec(2)*scale, F_sec(3)*scale, ...
                        0, 'Color', [0.5 0 0.5], 'LineWidth', 1, 'MaxHeadSize', 0.5, HandleVisibility='off');
                end

                % --- Accumulate moments about ref_point: r x F + local pitching moment
                r = AC_body - ref_point;  % vector from reference to AC
        
                %--- Force and moment accumulation

                F_total = F_total + F_sec(:)';
                M_toadd = cross(r, F_sec(:));
                M_total = M_total + M_toadd;
            end


        end
        function [alpha_deg, beta_deg, vrx, vry, vrz] = findSectionAOA(obj, P, V, W)
            % findSectionAOA  Compute sectional angle-of-attack and sideslip.
            %   [alpha_deg, beta_deg] = obj.findSectionAOA(P, V, W)
            %
            % Inputs (all in body coordinates):
            %   P - [3x1] position vector (m) of the section leading edge relative to body origin
            %   V - [3x1] translational velocity of body in body coords (m/s)
            %   W - [3x1] angular velocity of body in body coords (rad/s)
            %
            % Outputs:
            %   alpha_deg - angle of attack (deg), computed by projecting Vrel into the
            %               section XZ plane after undoing dihedral (xrot), then subtracting
            %               incidence (yrot) as a zero-alpha offset.
            %   beta_deg  - sideslip (deg) defined as atan2(v_span, u_chord) in the dihedral-rotated frame.
            %
            % Notes / assumptions:
            %  - Uses small-angle-safe atan2. Returns degrees.
            %  - P, V, W may be column vectors. The function is written for single-point evaluation.
            %  - Dihedral (xrot) is applied as a rotation of the section plane; we remove it
            %    (apply inverse) to measure velocity relative to that plane.
            %  - Incidence (yrot) is treated as an additive zero-AOA offset: alpha_effective = alpha_raw - yrot.
            %  - Beta is returned without any additional correction, computed in the dihedral-rotated frame.
            
            % Input validation
            if numel(P) ~= 3 || numel(V) ~= 3 || numel(W) ~= 3
                error('P, V, and W must be 3-element vectors (body coordinates).');
            end
        
            % Ensure column vectors
            P = P(:);
            V = V(:);
            W = W(:);
        
            % 1) Relative velocity at the section (body frame)
            Vrel = V + cross(W, P);   % 3x1
            vrx = Vrel(1);
            vry = Vrel(2);
            vrz = Vrel(3);
        
            % 2) Build rotation for dihedral (rotation about body x-axis)
            %    We *undo* dihedral to express velocity in the section-local frame
            %    where the section X axis is the chord direction and the section plane
            %    is the XZ plane.
            Rx = [1,          0,           0;
                  0,  cosd(obj.xrot), -sind(obj.xrot);
                  0,  sind(obj.xrot),  cosd(obj.xrot)];
            % Because applyTransform used Rx then Ry on points, to undo the dihedral
            % we apply the transpose (inverse) of Rx. For pure rotation, Rx' == Rx^-1.
            Rinv = Rx.';  % same as Rx' for rotation matrices
        
            % 3) Rotate Vrel into dihedral-removed (section) frame
            Vsec = Rinv * Vrel;   % Vsec = [u; v; w] in section-aligned frame (m/s)
        
            u = Vsec(1);
            v = Vsec(2);
            w = Vsec(3);
        
            % 4) Project velocity into XZ plane for alpha calculation (basically ignore v)
            %    and compute raw alpha: positive when w (vertical) is positive relative to u.
            %    Use atan2(w, u) to get signed angle in radians, then convert to degrees.
            alpha_raw = atan2(w, u);   % radians
        
            % 5) Apply incidence (yrot) as zero-AOA offset.
            %    Treat obj.yrot as degrees of geometric incidence (positive rotates chord nose-up).
            alpha_effective = alpha_raw - deg2rad(obj.yrot);
        
            % 6) Compute sideslip beta in the dihedral-removed frame:
            %    beta = atan2(v, u)  (signed, radians)
            beta_raw = atan2(v, u);
        
            % Convert to degrees for outputs
            alpha_deg = rad2deg(alpha_effective);
            beta_deg  = rad2deg(beta_raw);
        
            % Safety: if u is extremely small, warn or clamp (avoid NaN)
            if abs(u) < eps*100
                % Very small chordwise velocity; AOA is essentially +/-90 deg.
                % Keep computed values but warn the user.
                warning('Section chordwise velocity (u) is very small (|u| < %.3g). AOA may be large/invalid.', eps*100);
            end
        end
        %% Helper: returns rotation matrix R (3x3) for the wing transform
        function R = getWingRotationMatrix(obj)
            % Choose angles; flip X if mirrored, leave Y as-is
            xrot = obj.xrot;
            yrot = obj.yrot;
        
            if obj.mirrored
                xrot = -xrot;  % flip X rotation (dihedral)
                % yrot unchanged
            end
        
            % Build elementary rotations (degrees -> use cosd/sind)
            Rx = [1,        0,         0;
                  0,  cosd(xrot), -sind(xrot);
                  0,  sind(xrot),  cosd(xrot)];
        
            Ry = [ cosd(yrot), 0, sind(yrot);
                            0, 1,         0;
                  -sind(yrot), 0, cosd(yrot)];
        
            % Full rotation: apply in order R = Ry * Rx (same as before)
            R = Ry * Rx;
        end
        
        %% rotateVectorByWingTransforms: rotate a *direction* (no translation)
        function v_body = rotateVectorByWingTransforms(obj, v_local)
            % Accept row or column vector; return column vector
            v = v_local(:);
            R = getWingRotationMatrix(obj);
            v_body = R * v;
        end
        
        %% applyTransform: rotate+translate *points* (Nx3 input -> Nx3 output)
        function pts_body = applyTransform(obj, pts)
            % pts: [N x 3] matrix (or 1x3)
            if size(pts,2) ~= 3
                error('applyTransform expects pts as [N x 3]');
            end

            % Reflect the y points over the XZ plane
            if obj.mirrored
                pts(:,2) = -pts(:,2);
            end
        
            % Build rotation
            R = getWingRotationMatrix(obj);
        
            % Rotate points (rotation only)
            pts_rot = (R * pts')';  % still Nx3
        
            % Apply translation: x and z same, y mirrored when obj.mirrored == true
            tx = obj.xpos;
            if obj.mirrored
                ty = -obj.ypos;
            else
                ty = obj.ypos;
            end
            tz = obj.zpos;
        
            pts_rot(:,1) = pts_rot(:,1) + tx;
            pts_rot(:,2) = pts_rot(:,2) + ty;
            pts_rot(:,3) = pts_rot(:,3) + tz;
        
            pts_body = pts_rot;
        end

        function objr = mirror_me(obj)
            % Returns the current object with the mirror flag reversed
            objr = obj;
            objr.mirrored = ~objr.mirrored;
        end
    end
end

% Any useful functions