function out = call_idrag(cfg, opts)
%CALL_IDRAG Run induced-drag solver (MEX-first, EXE fallback).
%
% out = call_idrag(cfg)
% out = call_idrag(cfg, opts)   % opts is a struct
%
% Returns struct out with:
%   out.cd_induced
%   out.method   ("mex" or "exe")
%   out.status
%   out.stdout
%   out.runDir
%   out.files

arguments
    cfg (1,1) struct
    opts (1,1) struct = struct()
end

% ----------------- Defaults -----------------
def.preferMex  = true;
def.mexName    = "idrag_mex";

% Legacy EXE paths (fallback)
def.exePath    = "..\Applications\run_idrag.exe";
def.workDir    = "";  % default set below
def.inFile     = "..\InputFiles\idrag_input.txt";
def.stdinFile  = "..\InputFiles\idrag_stdin.txt";
def.outLog     = "..\LogFiles\run_stdout.txt";
def.errLog     = "..\LogFiles\run_stderr.txt";
def.outFile    = "idrag_output.txt";
def.resultFile = "idrag_result.txt";

% Merge user opts over defaults
opts = merge_opts(def, opts);

folder = fileparts(mfilename('fullpath'));
startingPath = pwd;

if opts.workDir == ""
    opts.workDir = string(fullfile(folder, "OutputFiles"));
end
workDir = char(opts.workDir);

% ----------------- MEX first -----------------
if opts.preferMex && exist(opts.mexName, "file") == 3
    try
        p = normalize_idrag_cfg_for_mex_strict(cfg);

        cd_induced = feval(opts.mexName, ...
            p.input_mode, p.sym_flag, p.cl_design, p.cm_flag, p.cm_design, ...
            p.xcg, p.cp, p.sref, p.cavg, p.npanels, ...
            p.xc, p.yc, p.zc, p.nvortices, p.spacing_flag, ...
            p.load_flag, p.loads);

        out = struct();
        out.cd_induced = cd_induced;
        out.method = "mex";
        out.status = 0;
        out.stdout = "";
        out.runDir = "";
        out.files = strings(0);
        return;

    catch ME
        warning("call_idrag:MexFailed", ...
            "MEX call failed; falling back to EXE.\n\n%s", ...
            getReport(ME, "basic", "hyperlinks", "off"));
        % fall through to EXE
    end
end

% ----------------- EXE fallback -----------------
try
    cd(workDir);

    exePath     = char(opts.exePath);
    inFile      = char(opts.inFile);
    stdinFile   = char(opts.stdinFile);
    outFile     = char(opts.outFile);
    resultFile  = char(opts.resultFile);
    outLog      = char(opts.outLog);
    errLog      = char(opts.errLog);

    assert(isfile(exePath), "Missing run_idrag.exe: %s", exePath);

    % Ensure cfg has fields your legacy writer expects
    cfg2 = ensure_legacy_writer_fields(cfg, outFile);

    % Write input deck
    write_idrag_input(cfg2, inFile, outFile);
    assert(isfile(inFile), "Input file was not created: %s", inFile);

    % Build stdin file (if your exe uses it)
    fid = fopen(stdinFile, 'w');
    fprintf(fid, "'%s'\n'%s'\n", inFile, outFile);
    fclose(fid);

    if isfile(outLog), delete(outLog); end
    if isfile(errLog), delete(errLog); end

    % Your argv pattern
    cmd = sprintf('"%s" "%s" > "%s" 2> "%s"', exePath, inFile, outLog, errLog);
    [status, txt] = system(cmd);

    if ~isempty(strtrim(txt))
        disp("=== system() text ==="); disp(txt);
    end

    if status ~= 0
        if isfile(outLog), disp("=== run_stdout.txt ==="); disp(fileread(outLog)); end
        if isfile(errLog), disp("=== run_stderr.txt ==="); disp(fileread(errLog)); end
        error("call_idrag:ExeFailed", "Fortran execution failed (status=%d).", status);
    end

    cd_induced = read_idrag_output(folder, resultFile);

    d = dir(workDir);
    files = string({d(~[d.isdir]).name});

    out = struct();
    out.cd_induced = cd_induced;
    out.method = "exe";
    out.status = status;
    out.stdout = txt;
    out.runDir = string(workDir);
    out.files = files;

    cd(startingPath);

catch ME
    cd(startingPath);
    error("call_idrag:Fail", ...
        "call_idrag failed.\n\nOriginal error:\n%s", ...
        getReport(ME, "basic", "hyperlinks", "off"));
end

end

% ======================================================================
function opts = merge_opts(def, user)
opts = def;
f = fieldnames(user);
for k = 1:numel(f)
    opts.(f{k}) = user.(f{k});
end
% normalize strings
opts.mexName    = string(opts.mexName);
opts.exePath    = string(opts.exePath);
opts.workDir    = string(opts.workDir);
opts.inFile     = string(opts.inFile);
opts.stdinFile  = string(opts.stdinFile);
opts.outLog     = string(opts.outLog);
opts.errLog     = string(opts.errLog);
opts.outFile    = string(opts.outFile);
opts.resultFile = string(opts.resultFile);
end

function p = normalize_idrag_cfg_for_mex_strict(cfg)
req = ["input_mode","sym_flag","cl_design","cm_flag","cm_design","xcg","cp","sref","cavg","npanels", ...
       "xc","yc","zc","nvortices","spacing_flag","load_flag","loads"];
for k = 1:numel(req)
    if ~isfield(cfg, req(k))
        error("call_idrag:MissingField", "cfg.%s is required for MEX.", req(k));
    end
end

np = double(cfg.npanels);
if np < 1 || np ~= floor(np)
    error("call_idrag:BadNPanels", "cfg.npanels must be a positive integer.");
end

p = struct();
p.input_mode   = int64(cfg.input_mode);
p.sym_flag     = int64(cfg.sym_flag);
p.cl_design    = double(cfg.cl_design);
p.cm_flag      = int64(cfg.cm_flag);
p.cm_design    = double(cfg.cm_design);
p.xcg          = double(cfg.xcg);
p.cp           = double(cfg.cp);
p.sref         = double(cfg.sref);
p.cavg         = double(cfg.cavg);
p.npanels      = int64(np);

p.xc = double(cfg.xc);
p.yc = double(cfg.yc);
p.zc = double(cfg.zc);

assert(isequal(size(p.xc), [np,4]), "idrag_mex: xc must be size npanels x 4.");
assert(isequal(size(p.yc), [np,4]), "idrag_mex: yc must be size npanels x 4.");
assert(isequal(size(p.zc), [np,4]), "idrag_mex: zc must be size npanels x 4.");

p.nvortices = int64(cfg.nvortices(:));
p.spacing_flag = int64(cfg.spacing_flag(:));

assert(numel(p.nvortices) == np, "idrag_mex: nvortices must be length npanels.");
assert(numel(p.spacing_flag) == np, "idrag_mex: spacing_flag must be length npanels.");

p.load_flag = int64(cfg.load_flag);

L = double(cfg.loads(:));
if isempty(L)
    L = 0; % safe scalar placeholder
end
p.loads = L;
end

function cfg2 = ensure_legacy_writer_fields(cfg, outFile)
cfg2 = cfg;

if ~isfield(cfg2, "title")
    cfg2.title = "IDRAG run (auto title)";
end
if ~isfield(cfg2, "outfile")
    cfg2.outfile = outFile;
end
if ~isfield(cfg2, "write_flag")
    cfg2.write_flag = 1;
end
end