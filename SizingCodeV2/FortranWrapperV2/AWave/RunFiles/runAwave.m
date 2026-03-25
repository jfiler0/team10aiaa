function out = runAwave(inputFile, opts)
%RUNAWAVE  Run the D2500 zero-lift wave-drag solver from MATLAB.
%
%   out = runAwave(inputFile)
%   out = runAwave(inputFile, opts)
%
%   inputFile - full or relative path to a D2500 .inp file.
%               Build one from a MATLAB struct using write_awave_input.m,
%               or use the provided case1-4.inp example files directly.
%
%   opts fields (all optional):
%     .exePath   - path to 2500.exe  (default: looks next to this script)
%     .workDir   - directory for wavedrag.out  (default: same as inputFile)
%     .keepOut   - true = keep wavedrag.out after parsing (default: false)
%
%   out fields:
%     .CDW       - wave drag coefficient(s), one value per Mach/cycle  [Nx1]
%     .DoverQ    - D/Q values corresponding to CDW                     [Nx1]
%     .Mach      - Mach numbers corresponding to CDW                   [Nx1]
%     .cycle     - cycle numbers corresponding to CDW                  [Nx1]
%     .raw       - full text of wavedrag.out (string)
%     .status    - system() return code (0 = success)
%     .inputFile - resolved absolute path of the input file used
%
%   Example (using provided test case):
%     out = runAwave('Examples\case1.inp');
%     fprintf('CDw = %.6f\n', out.CDW(end));
%
%   Example (build input from struct):
%     cfg = struct();
%     cfg.title = 'My wing-body';
%     cfg.REFA = 100.0;
%     ... (see write_awave_input.m for full field list)
%     inpFile = write_awave_input(cfg, 'my_case.inp');
%     out = runAwave(inpFile);

arguments
    inputFile  {mustBeTextScalar}
    opts.exePath  {mustBeTextScalar} = ""
    opts.workDir  {mustBeTextScalar} = ""
    opts.keepOut  (1,1) logical = false
end

% -------------------------------------------------------------------------
%  Resolve paths
% -------------------------------------------------------------------------
inputFile = char(inputFile);
if ~java.io.File(inputFile).isAbsolute()
    inputFile = fullfile(pwd, inputFile);
end
assert(isfile(inputFile), 'runAwave: input file not found:\n  %s', inputFile);

% Locate exe: check opts, then relative to this script, then MATLAB path
exePath = char(opts.exePath);
if isempty(exePath)
    scriptDir = fileparts(mfilename('fullpath'));
    candidates = { ...
        fullfile(scriptDir, '2500.exe'), ...
        fullfile(scriptDir, '..', 'src', '2500.exe'), ...
        fullfile(scriptDir, 'src', '2500.exe') };
    for k = 1:numel(candidates)
        if isfile(candidates{k})
            exePath = candidates{k};
            break
        end
    end
end
if isempty(exePath)
    exePath = which('2500.exe');
end
if isempty(exePath)
    error('runAwave:noExe', ...
        ['2500.exe not found. Pass opts.exePath or place 2500.exe in:\n', ...
         '  %s\n  or  %s\\src\\'], scriptDir, scriptDir);
end
assert(isfile(exePath), 'runAwave: exe not found:\n  %s', exePath);

% exe lives in  AWave/src/  =>  exeDir = AWave/src/
exeDir = fileparts(exePath);

% HelperFiles is two levels up from exeDir:
%   AWave/src/  ->  AWave/  ->  repo root  ->  HelperFiles/
helperDir = fullfile(exeDir, '..', '..', 'HelperFiles');
helperDir = char(java.io.File(helperDir).getCanonicalPath());   % resolve ..

% -------------------------------------------------------------------------
%  Working directory
%  wavedrag.out is always written to the exe's CWD.
%  We run the exe from exeDir, then move the output to workDir.
% -------------------------------------------------------------------------
workDir = char(opts.workDir);
if isempty(workDir)
    workDir = fileparts(inputFile);
end
if ~isfolder(workDir), mkdir(workDir); end

exeOutFile  = fullfile(exeDir,  'wavedrag.out');
destOutFile = fullfile(workDir, 'wavedrag.out');

if isfile(exeOutFile),  delete(exeOutFile);  end
if isfile(destOutFile), delete(destOutFile); end

% -------------------------------------------------------------------------
%  Write stdin response file.
%  D2500 declares fileName*80 (80-char limit). Long paths get truncated and
%  the OPEN fails. Fix: copy the .inp file into exeDir and pass just the
%  bare filename — the exe is already cd'd there so it finds it.
% -------------------------------------------------------------------------
[~, inpName, inpExt] = fileparts(inputFile);
localInp = fullfile(exeDir, [inpName, inpExt]);
copyfile(inputFile, localInp);
cleanInp = onCleanup(@() deleteIfExists(localInp));  %#ok<NASGU>

rspFile = [tempname, '.txt'];
fid = fopen(rspFile, 'w');
fprintf(fid, '%s\n', [inpName, inpExt]);   % bare filename only, no path
fclose(fid);
cleanRsp = onCleanup(@() deleteIfExists(rspFile));  %#ok<NASGU>

% -------------------------------------------------------------------------
%  Build and run the command.
%  - cd to exeDir so wavedrag.out lands next to the exe.
%  - Prepend HelperFiles to PATH so Windows finds the runtime DLLs.
%    The set PATH=... only affects this cmd /c subprocess, not permanently.
% -------------------------------------------------------------------------
% Canonicalise exeDir so cd /d gets a clean path (no unresolved ..)
exeDir = char(java.io.File(exeDir).getCanonicalPath());

% Inject HelperFiles into MATLAB's own environment so every subprocess
% inherits it automatically — more reliable than set PATH= inside cmd /c.
oldPath = getenv('PATH');
setenv('PATH', [helperDir, pathsep, oldPath]);
cleanEnv = onCleanup(@() setenv('PATH', oldPath));  % always restore  %#ok<NASGU>

if ispc
    cmd = sprintf('cd /d "%s" && "%s" < "%s"', exeDir, exePath, rspFile);
else
    cmd = sprintf('cd "%s" && "%s" < "%s"', exeDir, exePath, rspFile);
end

[status, sysout] = system(cmd);

% -------------------------------------------------------------------------
%  Find and read wavedrag.out
% -------------------------------------------------------------------------
if ~isfile(exeOutFile)
    error('runAwave:noOutput', ...
        ['D2500 produced no wavedrag.out.\n', ...
         'status = %d  (0xC0000135 = DLL not found; 0xC0000005 = crash)\n', ...
         'HelperFiles resolved to:\n  %s\n', ...
         'stdout:\n%s'], status, helperDir, sysout);
end

% Move output to workDir if it differs from exeDir
if ~strcmp(exeDir, workDir)
    movefile(exeOutFile, destOutFile, 'f');
    outFile = destOutFile;
else
    outFile = exeOutFile;
end

rawText = fileread(outFile);
if ~opts.keepOut, delete(outFile); end

% -------------------------------------------------------------------------
%  Parse key results from wavedrag.out
% -------------------------------------------------------------------------
[CDW, DoverQ, Mach, cycle] = parseResults(rawText);

% -------------------------------------------------------------------------
%  Package output
% -------------------------------------------------------------------------
out.CDW       = CDW;
out.DoverQ    = DoverQ;
out.Mach      = Mach;
out.cycle     = cycle;
out.raw       = string(rawText);
out.status    = status;
out.inputFile = inputFile;
end


% =========================================================================
function [CDW, DoverQ, Mach, cycle] = parseResults(txt)
%PARSERESULTS  Extract CDW, D/Q, Mach, and cycle from wavedrag.out text.
%
% Actual output lines look like:
%   "CYCLE= 1    CASE NO. M1.2    CYCLE   3"  <- cycle number
%   "          MACH =  1.2000      NX = ..."  <- Mach (may be absent in some builds)
%   "     D/Q= 239.997742 "                   <- summary D/Q (NOT the per-segment ones)
%   "     CDW= 14.9998589 "                   <- CDW result

CDW    = [];
DoverQ = [];
Mach   = [];
cycle  = [];

lines        = splitlines(string(txt));
currentMach  = NaN;
currentCycle = NaN;

for k = 1:numel(lines)
    line = strtrim(char(lines(k)));   % strip leading/trailing whitespace + \r

    % --- Mach: "MACH =  1.2000" or "MACH= 1.2" ---
    tok = regexp(line, 'MACH\s*=\s*([\d.]+)', 'tokens', 'once');
    if ~isempty(tok)
        currentMach = str2double(tok{1});
        continue
    end

    % --- Cycle from CASE line: "CASE NO. M1.2    CYCLE   3" ---
    tok = regexp(line, 'CYCLE\s+(\d+)', 'tokens', 'once');
    if ~isempty(tok)
        currentCycle = str2double(tok{1});
        continue
    end

    % --- Summary D/Q: line starts with "D/Q=" (NOT inside a CYCLE= line) ---
    % Exclude per-segment lines like "CYCLE= 1  FUSELAGE ... (D/Q = 57.6)"
    if ~contains(line, 'CYCLE') && ~contains(line, 'THETA') && ~contains(line, 'N ')
        tok = regexp(line, '^D/Q=\s*([\d.]+)', 'tokens', 'once');
        if ~isempty(tok)
            DoverQ(end+1) = str2double(tok{1}); %#ok<AGROW>
            continue
        end
    end

    % --- CDW: line starts with "CDW=" ---
    % Exclude "Opt.Eq. Body CDW=", "Opt. CDW*=", etc.
    tok = regexp(line, '^CDW=\s*([\d.]+)', 'tokens', 'once');
    if ~isempty(tok)
        val = str2double(tok{1});
        if ~isnan(val)
            CDW(end+1)   = val;           %#ok<AGROW>
            Mach(end+1)  = currentMach;   %#ok<AGROW>
            cycle(end+1) = currentCycle;  %#ok<AGROW>
        end
    end
end

CDW    = CDW(:);
DoverQ = DoverQ(:);
Mach   = Mach(:);
cycle  = cycle(:);

if numel(DoverQ) > numel(CDW)
    DoverQ = DoverQ(end-numel(CDW)+1:end);
end
end


% =========================================================================
function deleteIfExists(f)
if isfile(f), delete(f); end
end