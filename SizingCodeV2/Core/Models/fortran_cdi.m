function CDi = fortran_cdi(geom, CL)
%FORTRAN_CDI  Compute induced drag coefficient via the idrag MEX solver.
%
%  Wing panels are built from geom.wing.sections.
%  The LERX (innermost) panel is excluded — it destabilises the multi-panel
%  influence matrix due to extreme chord/span ratio mismatch.
%  Only the outer wing panel(s) are passed to idrag.

persistent conv_done   % convergence sweep runs once per MATLAB session

%% --- Build panels from geom -------------------------------------------
w      = makePanelsFromSurface(geom.wing);
r = makePanelsFromSurface(geom.rudder);
 e = makePanelsFromSurface(geom.elevator);
panels = [w, r, e];

% Drop innermost panel (LERX) if more than one panel exists
if numel(panels) > 1
    panels = panels(2:end);
end

npanels      = numel(panels);
xc           = zeros(npanels, 4);
yc           = zeros(npanels, 4);
zc           = zeros(npanels, 4);
nvortices    = zeros(npanels, 1);
spacing_flag = zeros(npanels, 1);

for i = 1:npanels
    xc(i,:)         = panels(i).xc;
    yc(i,:)         = panels(i).yc;
    zc(i,:)         = panels(i).zc;
    nvortices(i)    = panels(i).nvortices;
    spacing_flag(i) = panels(i).spacing_flag;
end

% Shift y so root is at 0, force cavg consistent with panel geometry
y_root          = min(yc(:));
yc              = yc - y_root;
b_semi          = max(yc(:));
cavg_consistent = geom.ref_area.v / (2 * b_semi);
AR              = (2 * b_semi)^2 / geom.ref_area.v;

%% --- Geometry diagnostic (runs every call) ----------------------------
fprintf('\n--- fortran_cdi geometry ---\n');
fprintf('  geom.ref_area   = %.4f m^2\n', geom.ref_area.v);
fprintf('  geom.wing.AR    = %.4f\n',      geom.wing.AR.v);
fprintf('  geom.cavg       = %.4f m\n',    geom.wing.average_chord.v);
fprintf('  npanels used    = %d  (LERX dropped if >1 existed)\n', npanels);
fprintf('  b_semi (panels) = %.4f m\n',    b_semi);
fprintf('  cavg_consistent = %.4f m  (= sref / 2*b_semi)\n', cavg_consistent);
fprintf('  AR (panels)     = %.4f\n',      AR);
fprintf('  bref check      = %.4f  (= sref/cavg, should = 2*b_semi=%.4f)\n', ...
    geom.ref_area.v / cavg_consistent, 2*b_semi);
fprintf('  Wing sections from geom:\n');
for i = 1:length(geom.wing.sections)
    s = geom.wing.sections(i);
    chord = s.te_coords(1) - s.le_coords(1);
    fprintf('    [%d] y=%.3f  LE=%.3f  TE=%.3f  chord=%.3f m\n', ...
        i, s.le_coords(2), s.le_coords(1), s.te_coords(1), chord);
end
fprintf('  Panel xc after shift:\n'); disp(xc)
fprintf('  Panel yc after shift:\n'); disp(yc)

%% --- Build cfg --------------------------------------------------------
cfg              = struct();
cfg.input_mode   = 0;
cfg.sym_flag     = 1;
cfg.cl_design    = CL;
cfg.cm_flag      = 0;
cfg.cm_design    = 0.0;
cfg.xcg          = geom.fuselage.length.v / 2;
cfg.cp           = 0.25;
cfg.sref         = geom.ref_area.v;
cfg.cavg         = cavg_consistent;
cfg.npanels      = npanels;
cfg.xc           = xc;
cfg.yc           = yc;
cfg.zc           = zc;
cfg.nvortices    = nvortices;
cfg.spacing_flag = spacing_flag;
cfg.load_flag    = 1;
cfg.loads        = [];

% %% --- nv convergence sweep (runs once per session) ---------------------
% if isempty(conv_done)
%     nv_vals = 10:10:400;
%     fprintf('\n  nv convergence (%d panel(s), CL=%.1f fixed, AR=%.3f):\n', ...
%         npanels, CL, AR);
%     fprintf('  %-6s  %-14s  %-10s  %-10s\n', 'nv', 'CDi', 'e_oswald', 'delta_e');
%     e_prev = NaN;
%     cfg.cl_design = CL;
%     for nv = nv_vals
%         cfg.nvortices = nv * ones(npanels, 1);
%         o      = runIdrag(cfg);
%         CDi_nv = abs(o.cd_induced);
%         e_nv   = CL^2 / (pi * AR * CDi_nv);
%         delta  = abs(e_nv - e_prev);
%         if isnan(e_prev)
%             fprintf('  %-6d  %-14.6f  %-10.4f  %-10s\n', nv, CDi_nv, e_nv, '—');
%         else
%             fprintf('  %-6d  %-14.6f  %-10.4f  %-10.5f\n', nv, CDi_nv, e_nv, delta);
%         end
%         e_prev = e_nv;
%     end
%     fprintf('\n');
%     % Restore
%     cfg.cl_design = CL;
%     cfg.nvortices = nvortices;
%     conv_done = true;
% end

%% --- Production run ---------------------------------------------------
out = runIdrag(cfg);
CDi = abs(out.cd_induced);
end


function panels = makePanelsFromSurface(surface)
%MAKEPANELSFROMSURFACE  Build valid panels from consecutive wing sections.
%  Clips panels where the TE becomes forward-swept (chord <= 0 at tip).

ns       = length(surface.sections);
panelIdx = 0;

for i = 1:(ns-1)
    s1 = surface.sections(i);
    s2 = surface.sections(i+1);

    % Always make s1 the inboard section
    if s1.le_coords(2) > s2.le_coords(2)
        [s1, s2] = deal(s2, s1);
    end

    root_chord = s1.te_coords(1) - s1.le_coords(1);
    tip_chord  = s2.te_coords(1) - s2.le_coords(1);

    if root_chord <= 0
        continue
    end

    if tip_chord <= 0
        % Clip to where chord = 0
        t_zero   = root_chord / (root_chord - tip_chord);
        y_zero   = s1.le_coords(2) + t_zero*(s2.le_coords(2) - s1.le_coords(2));
        xle_zero = s1.le_coords(1) + t_zero*(s2.le_coords(1) - s1.le_coords(1));
        z_zero   = s1.le_coords(3) + t_zero*(s2.le_coords(3) - s1.le_coords(3));
        P2 = [xle_zero, y_zero, z_zero];
        P3 = P2;
        panelIdx = panelIdx + 1;
        panels(panelIdx) = makePanel(s1.le_coords, P2, P3, s1.te_coords);
    else
        panelIdx = panelIdx + 1;
        panels(panelIdx) = makePanel(s1.le_coords, s2.le_coords, ...
                                     s2.te_coords,  s1.te_coords);
    end
end
end


function obj = makePanel(P1, P2, P3, P4)
%MAKEPANEL  [root-LE, tip-LE, tip-TE, root-TE]
    obj.nvortices    = 160;   % production value — see convergence sweep output
    obj.spacing_flag = 3;     % end-compressed (cosine spacing)
    obj.xc = [P1(1), P2(1), P3(1), P4(1)];
    obj.yc = [P1(2), P2(2), P3(2), P4(2)];
    obj.zc = [P1(3), P2(3), P3(3), P4(3)];
end