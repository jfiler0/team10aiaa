function out = call_awave(geom, opts)
%CALL_AWAVE  Run AWAVE (area-rule / wave-drag tool) from MATLAB like call_adrag.
%
% out = call_awave(geom, opts)
% Thanks chatgpt
% What this does:
%   1) writes an AWAVE input deck (awave_input.dat) from geom
%   2) calls the AWAVE executable
%   3) parses whatever it can from the output text (stdout + common output files)
%
% You WILL likely need to tweak:
%   - opts.exe        (path to AWAVE exe)
%   - opts.workDir    (where AWAVE runs)
%   - parse section   (depends on your AWAVE's exact outputs)
%
% -------------------- REQUIRED INPUTS (geom) --------------------
% geom should contain (at minimum):
%   geom.REFA            reference area
%   geom.XAF             chordwise x/c array (1xNX)
%   geom.Yspan           span stations array (1xNW)
%   geom.WAFORG          (NW x 4) [xLE y z chord] per station
%   geom.WAFORD_upper    (NW x NX) z/c upper at each station
%   geom.WAFORD_lower    (NW x NX) z/c lower at each station
%   geom.XFUS            fuselage x stations (1xNF)
%   geom.ZFUS            fuselage centerline z (1xNF)
%   geom.FUSARD          fuselage radius/area-radius distribution (1xNF)
%   geom.case            struct with fields:
%       .Mach, .Nazimuth, .Nharm, .CaseOn
%
% Optional:
%   geom.TZORD_upper / geom.TZORD_lower (NW x NX) (defaults zero)
%   geom.CONTROL  (1x24 or 1x25 int) if you already know your exact control line
%
% -------------------- OPTIONS (opts) --------------------
% opts.exe        : string, AWAVE executable path (default: "awave.exe")
% opts.workDir    : run directory (default: temp folder)
% opts.keepFiles  : true/false, keep run folder (default false)
% opts.timeoutSec : currently not enforced (MATLAB system has no hard timeout here)
% opts.inputName  : AWAVE input filename (default "awave_input.dat")
%
% Returns struct out with:
%   out.status, out.cmdout, out.runDir, out.files, out.parsed
%
% ---------------------------------------------------------------

arguments
    geom struct
    opts.exe string = "awave.exe"
    opts.workDir string = string(tempname)
    opts.keepFiles (1,1) logical = false
    opts.timeoutSec (1,1) double = 60 %#ok<NASGU>
    opts.inputName string = "awave_input.dat"
end

% --- Validate minimal fields ---
req = ["REFA","XAF","Yspan","WAFORG","WAFORD_upper","WAFORD_lower","XFUS","ZFUS","FUSARD","case"];
for k = 1:numel(req)
    if ~isfield(geom, req(k))
        error("call_awave:MissingField", "geom.%s is required.", req(k));
    end
end
reqCase = ["Mach","Nazimuth","Nharm","CaseOn"];
for k = 1:numel(reqCase)
    if ~isfield(geom.case, reqCase(k))
        error("call_awave:MissingField", "geom.case.%s is required.", reqCase(k));
    end
end

% Defaults
NW = numel(geom.Yspan);
NX = numel(geom.XAF);

if ~isfield(geom, "TZORD_upper"), geom.TZORD_upper = zeros(NW, NX); end
if ~isfield(geom, "TZORD_lower"), geom.TZORD_lower = zeros(NW, NX); end

% If you don't know your CONTROL line yet, use a safe template.
% IMPORTANT: AWAVE variants differ. Replace this with your known-good CONTROL.
if ~isfield(geom, "CONTROL")
    geom.CONTROL = [ ...
        1  1  0  0  0  0  0  NW  NX  1  0  0  0  0  0  0  0  0  1  0  0  0  0  0 ...
    ];
end

% --- Make run directory ---
runDir = opts.workDir;
if ~isfolder(runDir), mkdir(runDir); end

% --- Write input deck ---
inpPath = fullfile(runDir, opts.inputName);
write_awave_input(inpPath, geom);

% --- Call AWAVE ---
% Most legacy codes read from stdin or a fixed filename. Two common patterns:
%   (A) awave.exe < awave_input.dat
%   (B) awave.exe awave_input.dat
%
% We try A first, then fallback to B if needed.
cmdA = sprintf('cd /d "%s" && "%s" < "%s"', runDir, opts.exe, opts.inputName);
[statusA, cmdoutA] = system(cmdA);

status = statusA;
cmdout = cmdoutA;
cmdUsed = cmdA;

if status ~= 0
    cmdB = sprintf('cd /d "%s" && "%s" "%s"', runDir, opts.exe, opts.inputName);
    [statusB, cmdoutB] = system(cmdB);
    if statusB == 0
        status = statusB;
        cmdout = cmdoutB;
        cmdUsed = cmdB;
    else
        % keep original failure info but append fallback
        cmdout = sprintf("%s\n\n--- fallback attempt ---\n%s", cmdoutA, cmdoutB);
        cmdUsed = sprintf("%s\n%s", cmdA, cmdB);
        status = statusB;
    end
end

% --- Collect produced files ---
d = dir(runDir);
files = string({d(~[d.isdir]).name});

% --- Parse (best-effort) ---
parsed = struct();
parsed.commandUsed = cmdUsed;

% 1) If AWAVE prints something useful to stdout, keep it
parsed.stdout = cmdout;

% 2) Try typical output filenames (you may need to change these)
candidateOutFiles = ["awave.out","AWAVE.OUT","output.out","OUTPUT","RESULTS","results","lotus.out"];
for f = candidateOutFiles
    p = fullfile(runDir, f);
    if isfile(p)
        parsed.(matlab.lang.makeValidName(f)) = readTextFile(p);
    end
end

% 3) Attempt to extract wave drag numbers from any text we have
parsed.waveDrag = tryExtractWaveDrag(parsed);

% --- Cleanup if desired ---
if ~opts.keepFiles
    % Keep only if failure? (I'm defaulting to delete always unless keepFiles=true)
    try
        rmdir(runDir, "s");
        runDirDeleted = true;
    catch
        runDirDeleted = false;
    end
else
    runDirDeleted = false;
end

% --- Return ---
out = struct();
out.status = status;
out.cmdout = cmdout;
out.runDir = runDir;
out.runDirDeleted = runDirDeleted;
out.files = files;
out.parsed = parsed;
end

% ======================================================================
function write_awave_input(filename, geom)
% Minimal AWAVE deck writer to match the "XAF/WAFORG/TZORD/WAFORD/XFUS/ZFUS/FUSARD/CASE" style.

fid = fopen(filename, "w");
if fid < 0, error("Could not open %s", filename); end
c = onCleanup(@() fclose(fid));

NW = numel(geom.Yspan);
NX = numel(geom.XAF);

% Header
fprintf(fid, "AWAVE INPUT DECK (generated by MATLAB)\n");

% CONTROL
writeIntLine(fid, geom.CONTROL, "CONTROL");

% REFA
fprintf(fid, "\n");
writeFloatLine(fid, geom.REFA, "REFA");

% XAF chordwise
fprintf(fid, "\n");
writeFloatLine(fid, geom.XAF(:).', "XAF 1");

% span stations (your AWAVE might label differently; we keep the same pattern we used earlier)
writeFloatLine(fid, geom.Yspan(:).', "XAF 2");

% WAFORG
fprintf(fid, "\n");
for k = 1:NW
    writeFloatLine(fid, geom.WAFORG(k,:), sprintf("WAFORG %d", k));
end

% TZORD (upper/lower)
fprintf(fid, "\n");
for k = 1:NW
    writeFloatLine(fid, geom.TZORD_upper(k,:), sprintf("TZORD %d-1", k));
    writeFloatLine(fid, geom.TZORD_lower(k,:), sprintf("TZORD %d-2", k));
    fprintf(fid, "\n");
end

% WAFORD (upper/lower)
for k = 1:NW
    writeFloatLine(fid, geom.WAFORD_upper(k,:), sprintf("WAFORD %d-1", k));
    writeFloatLine(fid, geom.WAFORD_lower(k,:), sprintf("WAFORD %d-2", k));
    fprintf(fid, "\n");
end

% Fuselage
writeFloatLine(fid, geom.XFUS(:).',   "XFUS 1");
writeFloatLine(fid, geom.ZFUS(:).',   "ZFUS 1");
writeFloatLine(fid, geom.FUSARD(:).', "FUSARD 1");

% CASE line
fprintf(fid, "\n");
fprintf(fid, "M%0.2f   %d   %d     %d                                        CASE 1\n", ...
    geom.case.Mach, geom.case.Nazimuth, geom.case.Nharm, geom.case.CaseOn);
end

function s = readTextFile(p)
s = string(fileread(p));
end

function wd = tryExtractWaveDrag(parsed)
% Best-effort regex-based extraction from any available text.
% You will probably need to adapt this to your AWAVE's actual report format.
texts = strings(0);
fn = fieldnames(parsed);
for i = 1:numel(fn)
    v = parsed.(fn{i});
    if isstring(v) || ischar(v)
        texts(end+1) = string(v); %#ok<AGROW>
    end
end
big = join(texts, newline);

wd = struct();
wd.found = false;

% Common patterns you might see (examples): "CDw = 0.0123", "Wave Drag Coefficient", "Cdw"
patterns = { ...
    "(?i)\bCDW\b\s*=\s*([-+]?\d*\.?\d+(?:[Ee][-+]?\d+)?)", ...
    "(?i)\bCdw\b\s*=\s*([-+]?\d*\.?\d+(?:[Ee][-+]?\d+)?)", ...
    "(?i)Wave\s*Drag\s*Coefficient.*?([-+]?\d*\.?\d+(?:[Ee][-+]?\d+)?)" ...
};

for p = patterns
    tok = regexp(big, p{1}, "tokens", "once");
    if ~isempty(tok)
        wd.found = true;
        wd.CDw = str2double(tok{1});
        wd.matchedPattern = p{1};
        return;
    end
end
end

function writeIntLine(fid, vals, label)
vals = vals(:).';
for i = 1:numel(vals)
    fprintf(fid, "%3d", vals(i));
    if mod(i, 10) == 0
        fprintf(fid, " ");
    end
end
fprintf(fid, "  %s\n", label);
end

function writeFloatLine(fid, vals, label)
vals = vals(:).';
for i = 1:numel(vals)
    fprintf(fid, "%10.5f", vals(i));
end
fprintf(fid, "  %s\n", label);
end
