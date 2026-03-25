function out = runDatcom(inputFile, opts)
%RUNDATCOM  Run USAF Digital DATCOM from MATLAB.
%
%   out = runDatcom(inputFile)
%   out = runDatcom(inputFile, opts)
%
%   inputFile  - full or relative path to a DATCOM .inp file.
%                Use one of the provided EX1-EX4.INP files, or build your
%                own following the DATCOM namelist format.
%
%   Prerequisites:
%     Add the folder containing datcom.exe to the MATLAB path.
%     The function finds it automatically via which('datcom.exe').
%
%   opts fields (all optional):
%     .exePath  - override exe location if not on MATLAB path
%     .workDir  - directory for datcom.out  (default: inputFile folder)
%     .keepOut  - true = keep datcom.out after parsing (default: false)
%
%   out fields:
%     .tables   struct array, one element per (case × Mach) block:
%                 .caseTitle  string
%                 .Mach       scalar
%                 .Reynolds   scalar (per ft)
%                 .Sref       scalar reference area
%                 .data       table with columns:
%                               Alpha, CD, CL, CM, CN, CA, XCP,
%                               CLA, CMA, CYB, CNB, CLB
%     .raw      full text of datcom.out (string)
%     .status   system() return code (0 = success)
%     .inputFile resolved absolute path used
%
%   Example:
%     out = runDatcom(fullfile('Examples','EX1.INP'));
%     disp(out.tables(1).data)

arguments
    inputFile  {mustBeTextScalar}
    opts.exePath  {mustBeTextScalar} = ""
    opts.workDir  {mustBeTextScalar} = ""
    opts.keepOut  (1,1) logical = false
end

% -------------------------------------------------------------------------
%  Resolve input file to absolute path
% -------------------------------------------------------------------------
inputFile = char(inputFile);
if ~java.io.File(inputFile).isAbsolute()
    inputFile = fullfile(pwd, inputFile);
end
assert(isfile(inputFile), 'runDatcom: input file not found:\n  %s', inputFile);

% -------------------------------------------------------------------------
%  Locate datcom.exe via MATLAB path
% -------------------------------------------------------------------------
exePath = char(opts.exePath);
if isempty(exePath)
    exePath = which('datcom.exe');
end
if isempty(exePath)
    error('runDatcom:noExe', ...
        ['datcom.exe not found on the MATLAB path.\n', ...
         'Add the folder containing datcom.exe to the path:\n', ...
         '  addpath(''C:\\path\\to\\bin'')\n', ...
         'or pass it directly:\n', ...
         '  out = runDatcom(inputFile, exePath=''C:\\path\\to\\datcom.exe'')']);
end
exeDir = fileparts(exePath);

% HelperFiles is two levels up from exeDir (Datcom/src/ -> Datcom/ -> repo/ -> HelperFiles/)
helperDir = fullfile(exeDir, '..', '..', 'HelperFiles');
helperDir = char(java.io.File(helperDir).getCanonicalPath());

% -------------------------------------------------------------------------
%  Working directory
%  datcom.out, for013.dat, for014.dat are written to the exe's CWD.
%  Run the exe from exeDir so DLLs next to it are found.
% -------------------------------------------------------------------------
workDir = char(opts.workDir);
if isempty(workDir)
    workDir = fileparts(inputFile);
end
if ~isfolder(workDir), mkdir(workDir); end

exeDir = char(java.io.File(exeDir).getCanonicalPath());   % resolve any ..

exeOutFile  = fullfile(exeDir,  'datcom.out');
destOutFile = fullfile(workDir, 'datcom.out');

if isfile(exeOutFile),  delete(exeOutFile);  end
if isfile(destOutFile), delete(destOutFile); end

% Also clean up other output files datcom writes
for f = {'for013.dat', 'for014.dat'}
    fp = fullfile(exeDir, f{1});
    if isfile(fp), delete(fp); end
end

% -------------------------------------------------------------------------
%  Write stdin response file
%  datcom reads one filename from stdin (CHARACTER(LEN=132)) then processes.
%  Path limit is 132 chars — use absolute path directly.
% -------------------------------------------------------------------------
assert(numel(inputFile) <= 132, ...
    ['runDatcom: input file path is %d chars, exceeds 132-char Fortran limit.\n', ...
     'Move your file closer to the filesystem root or shorten folder names.\n', ...
     'Path: %s'], numel(inputFile), inputFile);

rspFile = [tempname, '.txt'];
fid = fopen(rspFile, 'w');
fprintf(fid, '%s\n', inputFile);
fclose(fid);
cleanRsp = onCleanup(@() deleteIfExists(rspFile));  %#ok<NASGU>

% -------------------------------------------------------------------------
%  Inject HelperFiles into PATH and run
% -------------------------------------------------------------------------
oldPath = getenv('PATH');
setenv('PATH', [helperDir, pathsep, oldPath]);
cleanEnv = onCleanup(@() setenv('PATH', oldPath));  %#ok<NASGU>

if ispc
    cmd = sprintf('cd /d "%s" && "%s" < "%s"', exeDir, exePath, rspFile);
else
    cmd = sprintf('cd "%s" && "%s" < "%s"', exeDir, exePath, rspFile);
end

[status, sysout] = system(cmd);

% -------------------------------------------------------------------------
%  Find datcom.out
% -------------------------------------------------------------------------
if ~isfile(exeOutFile)
    error('runDatcom:noOutput', ...
        ['datcom produced no datcom.out.\n', ...
         'status = %d  (0xC0000135 = DLL not found; 0xC0000005 = crash)\n', ...
         'HelperFiles resolved to:\n  %s\n', ...
         'stdout:\n%s'], status, helperDir, sysout);
end

% Move output to workDir if different from exeDir
if ~strcmp(exeDir, workDir)
    movefile(exeOutFile, destOutFile, 'f');
    % Move for013/for014 too if they exist
    for f = {'for013.dat', 'for014.dat'}
        fp = fullfile(exeDir, f{1});
        if isfile(fp), movefile(fp, fullfile(workDir, f{1}), 'f'); end
    end
    outFile = destOutFile;
else
    outFile = exeOutFile;
end

% -------------------------------------------------------------------------
%  Read and parse
% -------------------------------------------------------------------------
rawText = fileread(outFile);
if ~opts.keepOut, delete(outFile); end

tables = parseDatcomOutput(rawText);

% -------------------------------------------------------------------------
%  Package output
% -------------------------------------------------------------------------
out.tables    = tables;
out.raw       = string(rawText);
out.status    = status;
out.inputFile = inputFile;
end


% =========================================================================
function deleteIfExists(f)
if isfile(f), delete(f); end
end