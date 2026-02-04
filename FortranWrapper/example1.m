p.outfile = "idrag_pretty.txt";      % Fortran's pretty output
p.title   = "Hellstinger Case 01";

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

p.npanels = 1; % Basic VLM
p.nvortices = [40 0 0 0 0];
p.spacing_flag = [0 0 0 0 0];

p.xc = zeros(5,4); p.yc = zeros(5,4); p.zc = zeros(5,4);
% panel 1 corner
p.xc(1,:) = [0 0 1 1];
p.yc(1,:) = [0 5 5 0];
p.zc(1,:) = [0 0 0 0];

p.load_flag = 1;
% p.loads only needed if input_mode==1

cd_i = call_idrag(p);
fprintf("Cd_induced = %.6g\n", cd_i);
