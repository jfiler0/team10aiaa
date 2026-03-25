function outPath = write_awave_input(cfg, outPath)
%WRITE_AWAVE_INPUT  Write a D2500 fixed-format input deck from a MATLAB struct.
%
%   outPath = write_awave_input(cfg, outPath)
%
%   This covers the most common configuration:
%     - Wing (with or without camber/twist via TZORD)
%     - Circular fuselage (FUSARD = cross-sectional area at each station)
%     - Optional non-circular fuselage (provide ZFUS)
%     - Multiple Mach cases
%     - No pods, fins, or canards
%
%   For configurations with pods/fins/canards refer to the case2-4.inp
%   example files directly — they are the authoritative reference for
%   those CONTROL flag combinations.
%
% -------------------------------------------------------------------------
%  REQUIRED cfg fields
% -------------------------------------------------------------------------
%   .title    string      Case title (max 80 chars)
%   .REFA     scalar      Reference area
%
%   Wing fields (omit or set .wing = false to suppress wing):
%   .XAF      1 x NXAF   Chordwise stations as percent chord  (0..100)
%   .WAFORG   NWAF x 4   [xLE, y, z, chord] per spanwise station
%   .WAFORD   NWAF x NXAF  Wing ordinates as percent chord (percent-chord z/c * 100)
%               If separate upper/lower, pass NWAF x NXAF for each, see below.
%
%   Fuselage fields (omit or set .fuselage = false to suppress fuselage):
%   .XFUS     cell array {1 x NFUS}, each cell is a vector of x stations
%   .FUSARD   cell array {1 x NFUS}, each cell is a vector of cross-sectional areas
%   .ZFUS     (optional) cell array {1 x NFUS}, z-centerline per segment.
%               Provide this for non-circular / offset fuselages.
%
%   Case fields:
%   .cases    struct array, one element per Mach condition:
%               .Mach        Mach number  (e.g. 1.2)
%               .NX          Number of axial stations for integration (e.g. 50)
%               .NTHETA      Number of azimuthal cutting planes (e.g. 16; use 1 for M=1.0)
%               .ICYC        Fuselage reshaping cycles, 0 = analysis only (default 0)
%               .NREST       Number of fuselage restraint points (default 0)
%               .XREST       Vector of restraint x-locations (length NREST)
%               .continueNext  true = stack another case after this one (default false)
%
% -------------------------------------------------------------------------
%  OPTIONAL cfg fields
% -------------------------------------------------------------------------
%   .TZORD    NWAF x NXAF  Camber/twist ordinate offsets. If omitted, zeros assumed.
%               Providing this enables camber/twist correction (J1=1 not -1).
%   .WAFORD_upper  NWAF x NXAF  Upper surface ordinates (use with WAFORD_lower)
%   .WAFORD_lower  NWAF x NXAF  Lower surface ordinates
%               If both are provided, upper/lower are written separately (L=2 mode).
%               If only .WAFORD is provided, it is used for both surfaces.

% -------------------------------------------------------------------------
%  Validate required fields
% -------------------------------------------------------------------------
assert(isfield(cfg, 'title'),  'write_awave_input: cfg.title is required');
assert(isfield(cfg, 'REFA'),   'write_awave_input: cfg.REFA is required');
assert(isfield(cfg, 'cases'),  'write_awave_input: cfg.cases is required');

% Wing present?
hasWing = isfield(cfg, 'XAF') && isfield(cfg, 'WAFORG') && ...
          (isfield(cfg, 'WAFORD') || isfield(cfg, 'WAFORD_upper'));

% Fuselage present?
hasFuse = isfield(cfg, 'XFUS') && isfield(cfg, 'FUSARD');

% TZORD?
hasTZORD = hasWing && isfield(cfg, 'TZORD') && any(cfg.TZORD(:) ~= 0);

% Separate upper/lower WAFORD?
hasSplitWAFORD = isfield(cfg, 'WAFORD_upper') && isfield(cfg, 'WAFORD_lower');

% ZFUS?
hasZFUS = hasFuse && isfield(cfg, 'ZFUS');

% -------------------------------------------------------------------------
%  Determine CONTROL line flags
%
%  CONTROL: J0 J1 J2 J3 J4 J5 J6 NWAF NWAFOR NFUS
%           NRADX(1) NFORX(1) NRADX(2) NFORX(2) NRADX(3) NFORX(3) NRADX(4) NFORX(4)
%           NP NPODOR NF NFINOR NCAN NCANOR
%
%  J0 = 1  : REFA record present
%  J1 = 0  : no wing
%  J1 = -1 : wing, no TZORD, single WAFORD per station  (most common)
%  J1 = 1  : wing, TZORD present, single WAFORD per station
%  J1 = -1 with NWAFOR<0: wing, no TZORD, separate upper/lower WAFORD
%  J1 = 1  with NWAFOR<0: wing, TZORD present, separate upper/lower WAFORD
%  J2 = 0  : no fuselage
%  J2 = -1 : fuselage present (circular if J6=-1, non-circular with ZFUS if J6=0)
%  J6 = -1 : circular fuselage (no ZFUS read)
%  J6 =  0 : non-circular fuselage (reads ZFUS)
% -------------------------------------------------------------------------
J0 = 1;

if hasWing
    NWAF   = size(cfg.WAFORG, 1);
    NXAF   = numel(cfg.XAF);
    NWAFOR = NXAF;

    if hasSplitWAFORD
        NWAFOR_sign = -NWAFOR;       % negative = separate upper/lower
    else
        NWAFOR_sign = NWAFOR;
    end

    if hasTZORD
        J1 = 1;                      % TZORD will be written
    else
        J1 = -1;                     % no TZORD
    end
else
    NWAF   = 0;
    NWAFOR_sign = 0;
    J1 = 0;
end

if hasFuse
    NFUS = numel(cfg.XFUS);
    % NRADX and NFORX: for simple cases both equal the number of x-stations
    NRADX = zeros(1,4);
    NFORX = zeros(1,4);
    for k = 1:min(NFUS,4)
        NRADX(k) = numel(cfg.XFUS{k});
        NFORX(k) = numel(cfg.XFUS{k});
    end
    J2 = -1;
    if hasZFUS
        J6 = 0;     % non-circular: reads ZFUS
    else
        J6 = -1;    % circular: no ZFUS
    end
else
    NFUS  = 0;
    NRADX = zeros(1,4);
    NFORX = zeros(1,4);
    J2 = 0;
    J6 = 0;
end

J3=0; J4=0; J5=0;
NP=0; NPODOR=0; NF=0; NFINOR=0; NCAN=0; NCANOR=0;

CONTROL = [J0, J1, J2, J3, J4, J5, J6, ...
           NWAF, NWAFOR_sign, NFUS, ...
           NRADX(1), NFORX(1), NRADX(2), NFORX(2), ...
           NRADX(3), NFORX(3), NRADX(4), NFORX(4), ...
           NP, NPODOR, NF, NFINOR, NCAN, NCANOR];

% -------------------------------------------------------------------------
%  Open output file
% -------------------------------------------------------------------------
fid = fopen(outPath, 'w');
if fid < 0
    error('write_awave_input: cannot open "%s" for writing', outPath);
end
cleanup = onCleanup(@() fclose(fid));

% -------------------------------------------------------------------------
%  Line 1: Title (free text, max 80 chars)
% -------------------------------------------------------------------------
fprintf(fid, '%-80s\n', cfg.title(1:min(end,80)));

% -------------------------------------------------------------------------
%  Line 2: CONTROL  (24 integers, FORMAT 24I3)
% -------------------------------------------------------------------------
fprintf(fid, '%3d', CONTROL);
fprintf(fid, '  CONTROL\n');

% -------------------------------------------------------------------------
%  REFA  (J0=1)
% -------------------------------------------------------------------------
writeF7(fid, cfg.REFA, 'REFA');

% -------------------------------------------------------------------------
%  Wing data  (J1 != 0)
% -------------------------------------------------------------------------
if hasWing
    NXAF   = numel(cfg.XAF);
    NWAFOR = NXAF;

    % XAF: chordwise stations in 10F7.0 records
    writeF7(fid, cfg.XAF(:)', 'XAF');

    % WAFORG: one line per spanwise station [xLE y z chord]
    for k = 1:NWAF
        writeF7(fid, cfg.WAFORG(k,:), sprintf('WAFORG %d', k));
    end

    % TZORD: one set of records per station (only if J1>0)
    if hasTZORD
        for k = 1:NWAF
            writeF7(fid, cfg.TZORD(k,:), sprintf('TZORD %d', k));
        end
    end

    % WAFORD: one or two sets of records per station
    if hasSplitWAFORD
        for k = 1:NWAF
            writeF7(fid, cfg.WAFORD_upper(k,:), sprintf('WAFORD %d-1', k));
            writeF7(fid, cfg.WAFORD_lower(k,:), sprintf('WAFORD %d-2', k));
        end
    else
        for k = 1:NWAF
            writeF7(fid, cfg.WAFORD(k,:), sprintf('WAFORD %d', k));
        end
    end
end

% -------------------------------------------------------------------------
%  Fuselage data  (J2 != 0), one segment at a time
%  Order per segment: XFUS, [ZFUS if hasZFUS], FUSARD
% -------------------------------------------------------------------------
if hasFuse
    for seg = 1:NFUS
        writeF7(fid, cfg.XFUS{seg}(:)', sprintf('XFUS seg%d', seg));
        if hasZFUS
            writeF7(fid, cfg.ZFUS{seg}(:)', sprintf('ZFUS seg%d', seg));
        end
        writeF7(fid, cfg.FUSARD{seg}(:)', sprintf('FUSARD seg%d', seg));
    end
end

% -------------------------------------------------------------------------
%  CASE records  (FORMAT A4,9I4)
%
%  A4  field: NCASE label  e.g. "M1.2" for Mach 1.2
%  I4  fields: MACH  NX  NTHETA  NREST  NCON  ICYC  KKODE  JRST  IPLOT
%
%  NCON: 0 = read next CASE line (same geometry, multi-Mach sweep)
%         1 = read new configuration (title + CONTROL + geometry)
% -------------------------------------------------------------------------
ncases = numel(cfg.cases);
for k = 1:ncases
    c = cfg.cases(k);

    Mach   = double(c.Mach);
    Mach_i = round(Mach * 1000);      % integer Mach * 1000

    % 4-char NCASE label: "Mxx.x" truncated/padded to 4 chars
    machStr = sprintf('%.1f', Mach);
    caseLabel = sprintf('M%s', machStr);
    caseLabel = caseLabel(1:min(4, end));
    caseLabel = sprintf('%-4s', caseLabel);   % left-pad to exactly 4 chars

    NX     = int32(c.NX);
    NTHETA = int32(c.NTHETA);
    NREST  = int32(getfield_default(c, 'NREST', 0));
    ICYC   = int32(getfield_default(c, 'ICYC',  0));

    % NCON: 0 = another CASE follows (same config), 1 = done / new config
    if k < ncases
        NCON = int32(0);           % more CASE lines follow
    else
        continueNext = getfield_default(c, 'continueNext', false);
        NCON = int32(continueNext);
    end

    KKODE = int32(0);
    JRST  = int32(0);   % 0 = normal; 1 = skip body reshaping
    if ICYC == 0, JRST = int32(1); end   % no reshaping → skip OVL20
    IPLOT = int32(0);

    fprintf(fid, '%4s%4d%4d%4d%4d%4d%4d%4d%4d%4d  CASE %d\n', ...
        caseLabel, Mach_i, NX, NTHETA, NREST, NCON, ICYC, KKODE, JRST, IPLOT, k);

    % XREST: restraint points (only on first cycle, only once)
    if NREST > 0 && k == 1
        assert(isfield(c, 'XREST') && numel(c.XREST) >= NREST, ...
            'write_awave_input: case %d has NREST=%d but XREST is missing or too short', k, NREST);
        writeF7(fid, c.XREST(1:NREST)', 'XREST');
    end
end

fprintf('write_awave_input: wrote %s\n', outPath);
end


% =========================================================================
%  Helpers
% =========================================================================

function writeF7(fid, vals, label)
%WRITEF7  Write values in FORMAT(10F7.0) records, label as right comment.
%  D2500 reads data with FORMAT(10F7.0): 10 values per record, 7 chars each.
%  Labels on the right are human-readable comments only (not parsed by Fortran).
vals = vals(:)';
n    = numel(vals);
nrec = ceil(n / 10);
for r = 1:nrec
    i1 = (r-1)*10 + 1;
    i2 = min(r*10, n);
    chunk = vals(i1:i2);
    for v = chunk
        fprintf(fid, '%7g', v);
    end
    if r == 1
        fprintf(fid, '  %s\n', label);
    else
        fprintf(fid, '\n');
    end
end
end

function v = getfield_default(s, field, default)
if isfield(s, field)
    v = s.(field);
else
    v = default;
end
end