function CDi = fortran_cdi(geom, CL)

p.outfile = "idrag_pretty.txt";      % Fortran's pretty output
p.title   = "Fortran CDI";

p.input_mode = 0;  % 0=design mode 1=analysis mode - IDK WTF THIS FLAG ACTUALLY DOES
p.write_flag = 1;  % write pretty file
p.sym_flag   = 1;

% parameters we will need to write from the sizing code
p.cl_design  = CL;
p.cm_flag    = 0;
p.cm_design  = 0.0;

% TODO : Need actual method for xcg
p.xcg        = geom.fuselage.length.v / 2; % why do they need xcg
p.cp         = 0.25; % center of pressure for local chord (25%)
p.sref       = geom.ref_area.v;
p.cavg       = geom.wing.chord_avg.v;

p.panels(1) = panelObj(geom.outline.coords.wing(1,:), geom.outline.coords.wing(2,:), geom.outline.coords.wing(5,:), geom.outline.coords.wing(6,:));
p.panels(2) = panelObj(geom.outline.coords.wing(2,:), geom.outline.coords.wing(3,:), geom.outline.coords.wing(4,:), geom.outline.coords.wing(5,:));
p.panels(3) = panelObj(geom.outline.coords.elevator(1,:), geom.outline.coords.elevator(2,:), geom.outline.coords.elevator(3,:), geom.outline.coords.elevator(4,:));
p.panels(4) = panelObj(geom.outline.coords.vtail(1,:), geom.outline.coords.vtail(2,:), geom.outline.coords.vtail(3,:), geom.outline.coords.vtail(4,:));

p.npanels = length(p.panels); % Basic VLM

p.load_flag = 1;
% p.loads only needed if input_mode==1

CDi = call_idrag(p);

end

function obj = panelObj(P1, P2, P3, P4)
    obj = struct();
    
    obj.nvortices = 40;
    obj.spacing_flag = 0;

    % spacing flag (0 = equal, 1 = outboard-compressed, 2 = inboard, compressed, 3 = end-compressed)
    
    obj.xc = [ P1(1) P2(1) P3(1) P4(1) ];
    obj.yc = [ P1(2) P2(2) P3(2) P4(2) ];
    obj.zc = [ P1(3) P2(3) P3(3) P4(3) ];
end