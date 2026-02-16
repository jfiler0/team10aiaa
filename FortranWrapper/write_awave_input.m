%% AWAVE input writer (clean, minimal, editable)
% This script generates an AWAVE-style input deck similar to the example
% we discussed (XAF, WAFORG, TZORD, WAFORD, XFUS, ZFUS, FUSARD, CASE).
%
% How to use:
%   1) Edit the "USER GEOMETRY" section below.
%   2) Run this script.
%   3) It writes "awave_input.dat" in the current folder.

clear; clc;

%% ---------------- USER GEOMETRY ----------------
outFile = "awave_input.dat";

% Reference area
REFA = 100.0;

% Chordwise points (x/c locations)
XAF = [0.00 0.25 0.50 0.75 1.00];     % length NXAF

% Span stations for the wing (y locations) - length NWAF
Yspan = [0.0 5.0];

% Wing section placement: WAFORG rows = [xLE, y, z, chord]
% Must have NWAF rows
WAFORG = [
    0.0  0.0  0.0  5.0   % root: xLE, y, z, chord
    0.0  5.0  0.0  5.0   % tip
];

% Airfoil ordinates at each span station:
% For each station k, you provide:
%   WAFORD_upper(k,:) = z/c at XAF
%   WAFORD_lower(k,:) = z/c at XAF
%
% Example: a simple cambered-ish shape
WAFORD_upper = [
    0.00  0.04  0.06  0.04  0.00
    0.00  0.04  0.06  0.04  0.00
];
WAFORD_lower = [
    0.00 -0.02 -0.04 -0.02  0.00
    0.00 -0.02 -0.04 -0.02  0.00
];

% TZORD (twist/offset correction) — AWAVE decks often store two lines per station:
% "TZORD k-1" and "TZORD k-2". If you don't use it, keep zeros.
% Here: two matrices (upper/lower) sized NWAF x NXAF
TZORD_upper = zeros(numel(Yspan), numel(XAF));
TZORD_lower = zeros(numel(Yspan), numel(XAF));

% Fuselage stations (axial) and centerline + radius distribution
XFUS   = [0 5 10 15 20];
ZFUS   = [0 0  0  0  0 ];
FUSARD = [1 1  1  1  1 ];    % radius-like quantity (depends on AWAVE build)

% One Mach case (edit as needed)
Mach     = 0.80;
Nazimuth = 40;
Nharm    = 5;
CaseOn   = 1;

% CONTROL line:
% Different AWAVE versions use different switch meanings.
% Keep this as "template" and adjust only the counts you know matter.
%
% For the simple example: NWAF=2, NXAF=5, NFUS=1 case, etc.
% I'm writing it exactly as a 25-integer line to resemble legacy decks.
% ---- If your AWAVE expects different controls, paste your known-good line here. ----
CONTROL = [ ...
    1  1  0  0  0  0  0  numel(Yspan)  numel(XAF)  1  0  0  0  0  0  0  0  0  1  0  0  0  0  0  ...
];

%% ---------------- VALIDATION ----------------
NWAF = numel(Yspan);
NXAF = numel(XAF);

mustBeSize(WAFORG, [NWAF, 4], "WAFORG");
mustBeSize(WAFORD_upper, [NWAF, NXAF], "WAFORD_upper");
mustBeSize(WAFORD_lower, [NWAF, NXAF], "WAFORD_lower");
mustBeSize(TZORD_upper,  [NWAF, NXAF], "TZORD_upper");
mustBeSize(TZORD_lower,  [NWAF, NXAF], "TZORD_lower");

if ~isequal(size(CONTROL), [1, 24]) && ~isequal(size(CONTROL), [1, 25])
    error("CONTROL must be 24 or 25 integers in this template. You gave %d.", numel(CONTROL));
end

%% ---------------- WRITE FILE ----------------
fid = fopen(outFile, "w");
if fid < 0
    error("Could not open '%s' for writing.", outFile);
end

cleanupObj = onCleanup(@() fclose(fid));

% Header line (free text)
fprintf(fid, "SIMPLE TEST AIRCRAFT – AWAVE INPUT\n");

% CONTROL line
writeIntLine(fid, CONTROL, "CONTROL");

% Reference area
fprintf(fid, "\n");
writeFloatLine(fid, REFA, "REFA");

% XAF chordwise grid
fprintf(fid, "\n");
writeFloatLine(fid, XAF, "XAF 1");

% Span stations (the example labeled this as XAF 2; some decks use a different label)
writeFloatLine(fid, Yspan, "XAF 2");

% WAFORG for each span station
fprintf(fid, "\n");
for k = 1:NWAF
    writeFloatLine(fid, WAFORG(k,:), sprintf("WAFORG %d", k));
end

% TZORD (upper/lower) for each span station
fprintf(fid, "\n");
for k = 1:NWAF
    writeFloatLine(fid, TZORD_upper(k,:), sprintf("TZORD %d-1", k));
    writeFloatLine(fid, TZORD_lower(k,:), sprintf("TZORD %d-2", k));
    fprintf(fid, "\n");
end

% WAFORD (upper/lower) for each span station
for k = 1:NWAF
    writeFloatLine(fid, WAFORD_upper(k,:), sprintf("WAFORD %d-1", k));
    writeFloatLine(fid, WAFORD_lower(k,:), sprintf("WAFORD %d-2", k));
    fprintf(fid, "\n");
end

% Fuselage: XFUS, ZFUS, FUSARD
writeFloatLine(fid, XFUS,   "XFUS 1");
writeFloatLine(fid, ZFUS,   "ZFUS 1");
writeFloatLine(fid, FUSARD, "FUSARD 1");

% Mach case line
fprintf(fid, "\n");
fprintf(fid, "M%0.2f   %d   %d     %d                                        CASE 1\n", ...
    Mach, Nazimuth, Nharm, CaseOn);

fprintf("Wrote: %s\n", outFile);

%% ---------------- LOCAL HELPERS ----------------
function mustBeSize(A, sz, name)
    if ~isequal(size(A), sz)
        error("%s must be size [%d x %d]. You gave [%d x %d].", ...
            name, sz(1), sz(2), size(A,1), size(A,2));
    end
end

function writeIntLine(fid, vals, label)
    % Writes integers in fixed-ish fields, then a right-hand label.
    for i = 1:numel(vals)
        fprintf(fid, "%3d", vals(i));
        if mod(i, 10) == 0
            fprintf(fid, " ");
        end
    end
    fprintf(fid, "  %s\n", label);
end

function writeFloatLine(fid, vals, label)
    % Writes floats in a clean aligned way, then label at end of line.
    % Uses 10.5 style feel but not strict FORTRAN column enforcement.
    for i = 1:numel(vals)
        fprintf(fid, "%10.5f", vals(i));
    end
    fprintf(fid, "  %s\n", label);
end
