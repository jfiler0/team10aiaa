function CDi = fortran_cdi(geom, CL)
%FORTRAN_CDI  Compute induced drag coefficient via the idrag MEX solver.

w = makePanelsFromSurface(geom.wing);
e = makePanelsFromSurface(geom.elevator);
r = makePanelsFromSurface(geom.rudder);

panels = [w, e, r];

% w = geom.outline.coords.wing;
% % row 1  = root  LE  (6.00,  1.0)
% % row 2  = break LE  (7.93,  2.0)
% % row 7  = tip   LE  (11.31, 7.0)
% % row 8  = tip   TE  (13.00, 7.0)
% % row 9  = break TE  (13.00, 2.0)
% % row 14 = root  TE  (13.00, 1.0)
% panels(1) = makePanel(w(1,:), w(2,:),  w(9,:),  w(14,:)); % wing root->break
% panels(2) = makePanel(w(2,:), w(7,:),  w(8,:),  w(9,:));  % wing break->tip
% 
% e = geom.outline.coords.elevator;
% % row 1 = root LE, row 3 = tip LE, row 4 = tip TE, row 5 = root TE
% panels(3) = makePanel(e(1,:), e(3,:), e(4,:), e(5,:));
% 
% r = geom.outline.coords.rudder;
% % row 1 = root LE, row 4 = tip LE, row 5 = tip TE, row 6 = root TE
% panels(4) = makePanel(r(1,:), r(4,:), r(5,:), r(6,:));

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

cfg              = struct();
cfg.input_mode   = 0;
cfg.sym_flag     = 1;
cfg.cl_design    = CL;
cfg.cm_flag      = 0;
cfg.cm_design    = 0.0;
cfg.xcg          = geom.fuselage.length.v / 2;
cfg.cp           = 0.25;
cfg.sref         = geom.ref_area.v;
cfg.cavg         = geom.wing.average_chord.v;
cfg.npanels      = npanels;
cfg.xc           = xc;
cfg.yc           = yc;
cfg.zc           = zc;
cfg.nvortices    = nvortices;
cfg.spacing_flag = spacing_flag;
cfg.load_flag    = 1;
cfg.loads        = [];

% % ---- debug ----
% fprintf('cfg.sref = %.4f\n', cfg.sref);
% fprintf('cfg.cavg = %.4f\n', cfg.cavg);
% fprintf('cfg.cl_design = %.4f\n', cfg.cl_design);
% fprintf('xc:\n'); disp(cfg.xc)
% fprintf('yc:\n'); disp(cfg.yc)
% fprintf('zc:\n'); disp(cfg.zc)
% fprintf('elevator coords:\n'); disp(geom.outline.coords.elevator)
% fprintf('rudder coords:\n');   disp(geom.outline.coords.rudder)
% % ---------------

out = runIdrag(cfg);
CDi = out.cd_induced;
end

function panels = makePanelsFromSurface(surface)
    % Look through each section in the surface to build a panel
    for i = 1:(length(surface.sections)-1)
        panels(i) = makePanel(surface.sections(i).le_coords, surface.sections(i+1).le_coords, surface.sections(i+1).te_coords, surface.sections(i).te_coords);
    end
end

function obj = makePanel(P1, P2, P3, P4)
%MAKEPANEL  [root-LE, tip-LE, tip-TE, root-TE]
    obj.nvortices    = 40;
    obj.spacing_flag = 3;
    obj.xc = [P1(1), P2(1), P3(1), P4(1)];
    obj.yc = [P1(2), P2(2), P3(2), P4(2)];
    obj.zc = [P1(3), P2(3), P3(3), P4(3)];
end

