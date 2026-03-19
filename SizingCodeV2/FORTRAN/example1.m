%% example1.m  (fixed)
% Demonstrates calling IDRAG through call_idrag.m
% - Uses idrag_mex if available (fast)
% - Falls back to run_idrag.exe if MEX fails or is missing

clear; clc;

%% --- Paths (make this script self-contained) ---
thisDir = fileparts(mfilename("fullpath"));

% Add this folder (call_idrag.m) + helpers
addpath(thisDir);
addpath(fullfile(thisDir,"Helpers"));

% Optional: if you keep the MEX inside Applications, add it
addpath(fullfile(thisDir,"Applications"));

% EXE fallback location (matches your tree: FORTRAN/Applications/run_idrag.exe)
exePath = fullfile(thisDir, "Applications", "run_idrag.exe");

% Runtime IO folders (fallback path uses these)
inDir  = fullfile(thisDir, "InputFiles");
outDir = fullfile(thisDir, "OutputFiles");
logDir = fullfile(thisDir, "LogFiles");
if ~isfolder(inDir),  mkdir(inDir);  end
if ~isfolder(outDir), mkdir(outDir); end
if ~isfolder(logDir), mkdir(logDir); end

%% --- Define a simple configuration (matches idrag inputs) ---
cfg = struct();
cfg.title   = "IDRAG example1";
cfg.outfile = "idrag_output.txt";

% mode flags
cfg.input_mode  = 0;   % 0 = design (unknown loads), 1 = analyze (given loads)
cfg.write_flag  = 0;   % legacy EXE flag; ignored by MEX
cfg.sym_flag    = 1;   % 1 = symmetric, 0 = asymmetric
cfg.cm_flag     = 0;   % 0 = no Cm constraint, 1 = use Cm constraint
cfg.load_flag   = 1;   % 0 = cn input, 1 = load input (used only if input_mode = 1)

% targets / refs
cfg.cl_design   = 0.50;
cfg.cm_design   = 0.00;
cfg.xcg         = 0.25;
cfg.cp          = 0.25;
cfg.sref        = 1.0;
cfg.cavg        = 1.0;

% geometry: one real panel only (required shape = npanels x 4)
cfg.npanels = 1;

% Panel corner ordering:
%   1 = root LE
%   2 = tip  LE
%   3 = tip  TE
%   4 = root TE
b_half = 1.0;
c_root = 1.0;
c_tip  = 1.0;
sweep  = 0.0;
dihed  = 0.0;   % radians

xc = zeros(1,4);
yc = zeros(1,4);
zc = zeros(1,4);

xc(1,:) = [0.0, sweep,         sweep + c_tip, c_root];
yc(1,:) = [0.0, b_half,        b_half,        0.0   ];
zc(1,:) = [0.0, tan(dihed)*b_half, tan(dihed)*b_half, 0.0];

cfg.xc = double(xc);
cfg.yc = double(yc);
cfg.zc = double(zc);

% panel discretization: must match npanels
cfg.nvortices    = [30;30;30];    % scalar is OK for one panel
cfg.spacing_flag = 3;     % 0=equal, 1=outboard, 2=inboard, 3=end-compressed

% loads vector must be at least sum(nvortices) long for the MEX path
cfg.loads = zeros(30,1);
%% --- Options for wrapper (must match call_idrag arguments block) ---
opts = struct();
opts.preferMex = true;
opts.mexName   = "idrag_mex";

% EXE fallback (your actual tree)
opts.exePath   = string(exePath);
opts.workDir   = string(outDir);

% These are relative to workDir once call_idrag cd's there,
% so we pass full paths to avoid confusion.
opts.inFile     = string(fullfile(inDir,  "idrag_input.txt"));
opts.stdinFile  = string(fullfile(inDir,  "idrag_stdin.txt"));
opts.outLog     = string(fullfile(logDir, "run_stdout.txt"));
opts.errLog     = string(fullfile(logDir, "run_stderr.txt"));

opts.outFile    = "idrag_output.txt";
opts.resultFile = "idrag_result.txt";

%% --- Run ---
out = call_idrag(cfg, opts);
%% --- Display results ---
disp("----- IDRAG Results -----")
disp(out)

if isfield(out,"cd_induced")
    fprintf("CDi = %.10f\n", out.cd_induced);
end
if isfield(out,"e")
    fprintf("e   = %.6f\n", out.e);
end
if isfield(out,"cl_actual")
    fprintf("CL  = %.6f\n", out.cl_actual);
end