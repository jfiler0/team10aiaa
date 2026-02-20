function CDi = fortran_cdi(geom, cond)

p.outfile = "idrag_pretty.txt";      % Fortran's pretty output
p.title   = "Fortran CDI";

p.input_mode = 0;  % 0=design mode 1=analysis mode - IDK WTF THIS FLAG ACTUALLY DOES
p.write_flag = 1;  % write pretty file
p.sym_flag   = 1;

% parameters we will need to write from the sizing code
p.cl_design  = 0.60;
p.cm_flag    = 0;
p.cm_design  = 0.0;
p.xcg        = 1.2;
p.cp         = 0.25;
p.sref       = 12.5;
p.cavg       = 1.1;

p.xc = zeros(5,4); p.yc = zeros(5,4); p.zc = zeros(5,4);
% panel 1 corner
p.xc(1,:) = [0 0 1 1];
p.yc(1,:) = [0 5 5 0];
p.zc(1,:) = [0 0 0 0];

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