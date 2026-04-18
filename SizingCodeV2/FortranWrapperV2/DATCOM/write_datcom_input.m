function outPath = write_datcom_input(cfg, outPath)
%WRITE_DATCOM_INPUT  Write a USAF Digital DATCOM namelist input deck from a struct.
%
%   outPath = write_datcom_input(cfg, outPath)
%
%   The function writes one or more DATCOM cases to a text file.
%   Each case is a struct inside cfg.cases.  Fields that are empty or
%   missing are simply omitted from the file — DATCOM will use its
%   internal defaults for those quantities.
%
% =========================================================================
%  TOP-LEVEL cfg FIELDS
% =========================================================================
%   .dim      string   'FT' (default) or 'M' — length units for all geometry
%   .build    logical  true => write BUILD card (configuration buildup output)
%   .cases    struct array — one element per DATCOM case (see below)
%
% =========================================================================
%  CASE FIELDS  (cfg.cases(k))
% =========================================================================
%
%  --- Control cards ---
%   .caseid   string   CASEID label (max ~72 chars, one line)
%   .save     logical  true => write SAVE card  (default true)
%
%  --- $FLTCON — Flight conditions ---
%   .fltcon.nmach    scalar    number of Mach numbers
%   .fltcon.mach     1xN       Mach number(s)
%   .fltcon.nalpha   scalar    number of alpha angles
%   .fltcon.alschd   1xN       angle of attack schedule (deg)
%   .fltcon.rnnub    1xN       unit Reynolds number(s) (per ft or per m)
%   .fltcon.nalt     scalar    number of altitudes (if using ALT instead of RNNUB)
%   .fltcon.alt      1xN       altitude(s) (ft or m)
%   .fltcon.loop     scalar    loop control: 1=mach+alt together, 2=all mach/alt combos
%   .fltcon.hypers   logical   true => use hypersonic methods
%
%  --- $OPTINS — Reference geometry ---
%   .optins.sref     scalar    reference area (ft^2 or m^2)
%   .optins.cbarr    scalar    longitudinal reference length / mean aero chord (ft or m)
%   .optins.blref    scalar    lateral reference length / wing span (ft or m)
%
%  --- $SYNTHS — Component positions (can set multiple times within a case) ---
%   .synths.xcg      scalar    CG x-position
%   .synths.zcg      scalar    CG z-position
%   .synths.xw       scalar    wing apex x-position
%   .synths.zw       scalar    wing apex z-position
%   .synths.aliw     scalar    wing incidence angle (deg)
%   .synths.xh       scalar    horiz tail apex x-position
%   .synths.zh       scalar    horiz tail apex z-position
%   .synths.alih     scalar    horiz tail incidence angle (deg)
%   .synths.xv       scalar    vert tail apex x-position
%   .synths.zv       scalar    vert tail apex z-position
%   .synths.vertup   logical   true => vertical tail above the body centreline
%   .synths.scale    scalar    model scale factor (full-size = 1.0)
%
%  --- $BODY — Fuselage geometry ---
%   .body.nx       scalar    number of fuselage cross-sections
%   .body.bnose    scalar    nose type: 1=ogive, 2=cone, 3=blunt
%   .body.btail    scalar    tail type: 1=ogive, 2=cone, 3=blunt, 0=none
%   .body.bln      scalar    nose length (ft or m)
%   .body.bla      scalar    afterbody length (ft or m, 0=no afterbody)
%   .body.x        1xNX      x-stations along the body
%   .body.r        1xNX      radius at each station (circular body)
%   .body.s        1xNX      cross-sectional area at each station
%   .body.p        1xNX      perimeter at each station
%   .body.zn       1xNX      z of upper surface (non-circular body)
%   .body.zl       1xNX      z of lower surface (non-circular body)
%   .body.ds       scalar    boat-tail half-angle (deg) — 0 for pointed tail
%
%  --- $WGPLNF — Wing planform ---
%   .wgplnf.chrdr    scalar    root chord
%   .wgplnf.chrdtp   scalar    tip chord
%   .wgplnf.sspn     scalar    total semi-span (root to tip, including fuselage portion)
%   .wgplnf.sspne    scalar    exposed semi-span (fuselage-side edge to tip)
%   .wgplnf.savsi    scalar    inboard LE sweep angle (deg)
%   .wgplnf.savso    scalar    outboard LE sweep angle (deg, cranked/double-delta only)
%   .wgplnf.sspnop   scalar    spanwise break point for cranked wing (ft or m)
%   .wgplnf.chrdbp   scalar    chord at span break point
%   .wgplnf.chstat   scalar    chordwise location of pivot for sweep (fraction of chord, 0=LE)
%   .wgplnf.swafp    scalar    flap-affected span fraction
%   .wgplnf.twista   scalar    aerodynamic twist angle (deg, negative=washout)
%   .wgplnf.sspndd   scalar    dihedral break span (ft or m)
%   .wgplnf.dhdadi   scalar    dihedral angle inboard of break (deg)
%   .wgplnf.dhdado   scalar    dihedral angle outboard of break (deg)
%   .wgplnf.type     scalar    planform type: 1=straight taper, 2=double delta, 3=cranked
%
%  --- $WGSCHR — Wing section aerodynamic characteristics ---
%   .wgschr.tovc     scalar    thickness-to-chord ratio at root
%   .wgschr.tovco    scalar    thickness-to-chord ratio at tip
%   .wgschr.deltay   scalar    spanwise distance for 2D section data (ft or m)
%   .wgschr.xovc     scalar    chordwise location of max thickness (fraction)
%   .wgschr.cli      scalar    ideal lift coefficient
%   .wgschr.alphai   scalar    ideal angle of attack (deg)
%   .wgschr.clalpa   1xN       lift curve slope (per deg) at each Mach (or scalar)
%   .wgschr.clmax    1xN       maximum lift coefficient at each Mach (or scalar)
%   .wgschr.cmo      scalar    zero-lift pitching moment coefficient
%   .wgschr.leri     scalar    leading-edge radius (fraction of chord, inboard)
%   .wgschr.lero     scalar    leading-edge radius (fraction of chord, outboard)
%   .wgschr.camber   logical   true => airfoil has camber
%   .wgschr.clamo    scalar    low-speed lift curve slope for CL_max method
%   .wgschr.tceff    scalar    effective thickness ratio for wave drag
%   .wgschr.xovco    scalar    chordwise max-thickness location at tip
%   .wgschr.cmot     scalar    zero-lift pitching moment at tip section
%   .wgschr.clmaxl   scalar    CLMAX correction at low speeds
%
%  --- $HTPLNF / $HTSCHR — Horizontal tail (same fields as wing) ---
%   .htplnf.*  same field names as .wgplnf
%   .htschr.*  same field names as .wgschr
%
%  --- $VTPLNF / $VTSCHR — Vertical tail (same fields as wing) ---
%   .vtplnf.*  same field names as .wgplnf
%   .vtschr.*  same field names as .wgschr
%
%  --- NACA airfoil designation cards ---
%   .naca_wing   string  e.g. 'NACA-W-6-65A004'
%   .naca_htail  string  e.g. 'NACA-H-6-65A004'
%   .naca_vtail  string  e.g. 'NACA-V-6-0009'
%
% =========================================================================
%  EXAMPLE
% =========================================================================
%   cfg.dim = 'FT';
%   cfg.cases(1).caseid = 'MY AIRCRAFT CASE 1';
%   cfg.cases(1).fltcon.nmach  = 3;
%   cfg.cases(1).fltcon.mach   = [0.6, 0.9, 1.4];
%   cfg.cases(1).fltcon.nalpha = 9;
%   cfg.cases(1).fltcon.alschd = -4:4:28;
%   cfg.cases(1).fltcon.rnnub  = [2.28e6, 3.04e6, 4.26e6];
%   cfg.cases(1).optins.sref   = 8.85;
%   cfg.cases(1).optins.cbarr  = 2.48;
%   cfg.cases(1).optins.blref  = 4.28;
%   cfg.cases(1).synths.xcg    = 4.14;
%   cfg.cases(1).synths.zcg    = -0.20;
%   cfg.cases(1).synths.xw     = 2.5;
%   cfg.cases(1).synths.zw     = 0.0;
%   cfg.cases(1).synths.aliw   = 0.0;
%   cfg.cases(1).wgplnf.chrdr  = 2.90;
%   ... etc
%   write_datcom_input(cfg, 'myaircraft.inp');
%   out = runDatcom('myaircraft.inp');

% -------------------------------------------------------------------------
%  Open file
% -------------------------------------------------------------------------
fid = fopen(outPath, 'w');
if fid < 0
    error('write_datcom_input: cannot open "%s" for writing', outPath);
end
cleanup = onCleanup(@() fclose(fid));

% -------------------------------------------------------------------------
%  Global header cards
% -------------------------------------------------------------------------
dim = 'FT';
if isfield(cfg, 'dim') && ~isempty(cfg.dim)
    dim = upper(char(cfg.dim));
end
if strcmp(dim, 'M')
    fprintf(fid, 'DIM M\n');
end

if isfield(cfg, 'build') && cfg.build
    fprintf(fid, 'BUILD\n');
end

% -------------------------------------------------------------------------
%  Write cases
% -------------------------------------------------------------------------
ncases = numel(cfg.cases);
for k = 1:ncases
    c = cfg.cases(k);

    % $FLTCON
    if isfield(c, 'fltcon') && ~isempty(c.fltcon)
        writeNamelist(fid, 'FLTCON', buildFltcon(c.fltcon));
    end

    % $OPTINS
    if isfield(c, 'optins') && ~isempty(c.optins)
        writeNamelist(fid, 'OPTINS', buildOptins(c.optins));
    end

    % $SYNTHS
    if isfield(c, 'synths') && ~isempty(c.synths)
        writeNamelist(fid, 'SYNTHS', buildSynths(c.synths));
    end

    % $BODY
    if isfield(c, 'body') && ~isempty(c.body)
        writebody(fid, c.body);
    end

    % NACA airfoil designation cards (must come BEFORE planform namelists)
    if isfield(c, 'naca_wing')  && ~isempty(c.naca_wing)
        fprintf(fid, '%s\n', strtrim(c.naca_wing));
    end
    if isfield(c, 'naca_htail') && ~isempty(c.naca_htail)
        fprintf(fid, '%s\n', strtrim(c.naca_htail));
    end
    if isfield(c, 'naca_vtail') && ~isempty(c.naca_vtail)
        fprintf(fid, '%s\n', strtrim(c.naca_vtail));
    end

    % $WGPLNF / $WGSCHR  — Wing
    if isfield(c, 'wgplnf') && ~isempty(c.wgplnf)
        writeNamelist(fid, 'WGPLNF', buildPlanform(c.wgplnf));
    end
    if isfield(c, 'wgschr') && ~isempty(c.wgschr)
        writeNamelist(fid, 'WGSCHR', buildSection(c.wgschr));
    end

    % $HTPLNF / $HTSCHR  — Horizontal tail
    if isfield(c, 'htplnf') && ~isempty(c.htplnf)
        writeNamelist(fid, 'HTPLNF', buildPlanform(c.htplnf));
    end
    if isfield(c, 'htschr') && ~isempty(c.htschr)
        writeNamelist(fid, 'HTSCHR', buildSection(c.htschr));
    end

    % $VTPLNF / $VTSCHR  — Vertical tail
    if isfield(c, 'vtplnf') && ~isempty(c.vtplnf)
        writeNamelist(fid, 'VTPLNF', buildPlanform(c.vtplnf));
    end
    if isfield(c, 'vtschr') && ~isempty(c.vtschr)
        writeNamelist(fid, 'VTSCHR', buildSection(c.vtschr));
    end

    % CASEID
    if isfield(c, 'caseid') && ~isempty(c.caseid)
        fprintf(fid, 'CASEID %s\n', strtrim(c.caseid));
    end

    % SAVE
    doSave = true;
    if isfield(c, 'save')
        doSave = logical(c.save);
    end
    if doSave
        fprintf(fid, 'SAVE\n');
    end

    % NEXT CASE (always, even after last case — DATCOM expects it)
    fprintf(fid, 'NEXT CASE\n');
end

fprintf('write_datcom_input: wrote %s\n', outPath);
end % write_datcom_input


%==========================================================================
% NAMELISTS BUILDERS — return cell arrays of 'KEY=VALUE' assignment strings
%==========================================================================

function pairs = buildFltcon(f)
pairs = {};
pairs = addScalar(pairs, f, 'nmach',  'NMACH');
pairs = addVector(pairs, f, 'mach',   'MACH');
pairs = addScalar(pairs, f, 'nalpha', 'NALPHA');
pairs = addVector(pairs, f, 'alschd', 'ALSCHD');
pairs = addVector(pairs, f, 'rnnub',  'RNNUB');
pairs = addScalar(pairs, f, 'nalt',   'NALT');
pairs = addVector(pairs, f, 'alt',    'ALT');
pairs = addScalar(pairs, f, 'loop',   'LOOP');
pairs = addLogical(pairs, f, 'hypers', 'HYPERS');
end

function pairs = buildOptins(f)
pairs = {};
pairs = addScalar(pairs, f, 'sref',  'SREF');
pairs = addScalar(pairs, f, 'cbarr', 'CBARR');
pairs = addScalar(pairs, f, 'blref', 'BLREF');
end

function pairs = buildSynths(f)
pairs = {};
pairs = addScalar(pairs, f, 'xcg',   'XCG');
pairs = addScalar(pairs, f, 'zcg',   'ZCG');
pairs = addScalar(pairs, f, 'xw',    'XW');
pairs = addScalar(pairs, f, 'zw',    'ZW');
pairs = addScalar(pairs, f, 'aliw',  'ALIW');
pairs = addScalar(pairs, f, 'xh',    'XH');
pairs = addScalar(pairs, f, 'zh',    'ZH');
pairs = addScalar(pairs, f, 'alih',  'ALIH');
pairs = addScalar(pairs, f, 'xv',    'XV');
pairs = addScalar(pairs, f, 'zv',    'ZV');
pairs = addLogical(pairs, f, 'vertup', 'VERTUP');
pairs = addScalar(pairs, f, 'scale', 'SCALE');
end

function pairs = buildPlanform(f)
pairs = {};
pairs = addScalar(pairs, f, 'chrdr',  'CHRDR');
pairs = addScalar(pairs, f, 'chrdtp', 'CHRDTP');
pairs = addScalar(pairs, f, 'sspn',   'SSPN');
pairs = addScalar(pairs, f, 'sspne',  'SSPNE');
pairs = addScalar(pairs, f, 'savsi',  'SAVSI');
pairs = addScalar(pairs, f, 'savso',  'SAVSO');
pairs = addScalar(pairs, f, 'sspnop', 'SSPNOP');
pairs = addScalar(pairs, f, 'chrdbp', 'CHRDBP');
pairs = addScalar(pairs, f, 'chstat', 'CHSTAT');
pairs = addScalar(pairs, f, 'swafp',  'SWAFP');
pairs = addScalar(pairs, f, 'twista', 'TWISTA');
pairs = addScalar(pairs, f, 'sspndd', 'SSPNDD');
pairs = addScalar(pairs, f, 'dhdadi', 'DHDADI');
pairs = addScalar(pairs, f, 'dhdado', 'DHDADO');
pairs = addScalar(pairs, f, 'type',   'TYPE');

% Horizontal tail extras
pairs = addVector(pairs, f, 'shb',   'SHB');
pairs = addVector(pairs, f, 'sext',  'SEXT');
pairs = addVector(pairs, f, 'rlph',  'RLPH');
end

function pairs = buildSection(f)
pairs = {};
pairs = addScalar(pairs, f, 'tovc',   'TOVC');
pairs = addScalar(pairs, f, 'tovco',  'TOVCO');
pairs = addScalar(pairs, f, 'xovc',   'XOVC');
pairs = addScalar(pairs, f, 'xovco',  'XOVCO');
pairs = addScalar(pairs, f, 'deltay', 'DELTAY');
pairs = addScalar(pairs, f, 'cli',    'CLI');
pairs = addScalar(pairs, f, 'alphai', 'ALPHAI');
pairs = addVector(pairs, f, 'clalpa', 'CLALPA');
pairs = addVector(pairs, f, 'clmax',  'CLMAX');
pairs = addScalar(pairs, f, 'cmo',    'CMO');
pairs = addScalar(pairs, f, 'cmot',   'CMOT');
pairs = addScalar(pairs, f, 'leri',   'LERI');
pairs = addScalar(pairs, f, 'lero',   'LERO');
pairs = addLogical(pairs, f, 'camber', 'CAMBER');
pairs = addScalar(pairs, f, 'clamo',  'CLAMO');
pairs = addScalar(pairs, f, 'tceff',  'TCEFF');
pairs = addScalar(pairs, f, 'clmaxl', 'CLMAXL');
end


%==========================================================================
% BODY WRITER — separate because body uses array subscript notation
%==========================================================================
function writebody(fid, b)
% First namelist: structural parameters
pairs = {};
pairs = addScalar(pairs, b, 'nx',    'NX');
pairs = addScalar(pairs, b, 'bnose', 'BNOSE');
pairs = addScalar(pairs, b, 'btail', 'BTAIL');
pairs = addScalar(pairs, b, 'bln',   'BLN');
pairs = addScalar(pairs, b, 'bla',   'BLA');
pairs = addScalar(pairs, b, 'ds',    'DS');

% Body coordinate arrays use X(1)=..., S(1)=..., etc.
if isfield(b, 'x')  && ~isempty(b.x),  pairs{end+1} = formatArr('X',  b.x);  end
if isfield(b, 'r')  && ~isempty(b.r),  pairs{end+1} = formatArr('R',  b.r);  end
if isfield(b, 's')  && ~isempty(b.s),  pairs{end+1} = formatArr('S',  b.s);  end
if isfield(b, 'p')  && ~isempty(b.p),  pairs{end+1} = formatArr('P',  b.p);  end

writeNamelist(fid, 'BODY', pairs);

% Non-circular body (ZU/ZL arrays) get a separate namelist
if (isfield(b, 'zn') && ~isempty(b.zn)) || ...
   (isfield(b, 'zl') && ~isempty(b.zl))
    pairs2 = {};
    if isfield(b, 'zn') && ~isempty(b.zn)
        pairs2{end+1} = formatArr('ZU', b.zn);
    end
    if isfield(b, 'zl') && ~isempty(b.zl)
        pairs2{end+1} = formatArr('ZL', b.zl);
    end
    writeNamelist(fid, 'BODY', pairs2);
end
end


%==========================================================================
% NAMELIST FORMATTER
% Writes a $NAME ... $ block, wrapping at 72 columns.
%==========================================================================
function writeNamelist(fid, name, pairs)
if isempty(pairs), return; end

% Join all assignments with ', '
allPairs = strjoin(pairs, ', ');

% Word-wrap at column 72 (DATCOM is fixed-format Fortran card image)
% We build up lines manually.
PREFIX    = ' $';
CONT      = '   ';              % continuation indent
MAXCOL    = 72;
openTag   = sprintf('%s%s ', PREFIX, name);

% Split into individual tokens at comma boundaries
tokens = strtrim(strsplit(allPairs, ', '));

lines  = {};
curLine = openTag;

for i = 1:numel(tokens)
    tok = tokens{i};
    if i < numel(tokens)
        tok = [tok, ','];    % add comma except after last
    end
    candidate = [curLine, tok];
    if length(candidate) <= MAXCOL || length(curLine) <= length(openTag)
        curLine = candidate;
        if i < numel(tokens)
            curLine = [curLine, ' '];
        end
    else
        lines{end+1} = curLine; %#ok<AGROW>
        curLine = [CONT, tok, ' '];
    end
end
lines{end+1} = [curLine, '$'];

for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end


%==========================================================================
% HELPERS — build 'KEY=VALUE' strings
%==========================================================================

function pairs = addScalar(pairs, s, field, key)
if isfield(s, field) && ~isempty(s.(field))
    v = s.(field);
    pairs{end+1} = sprintf('%s=%s', key, fmtNum(v));
end
end

function pairs = addVector(pairs, s, field, key)
if isfield(s, field) && ~isempty(s.(field))
    v = s.(field)(:)';  % force row
    if numel(v) == 1
        pairs{end+1} = sprintf('%s(1)=%s', key, fmtNum(v));
    else
        vals = strjoin(arrayfun(@fmtNum, v, 'UniformOutput', false), ',');
        pairs{end+1} = sprintf('%s(1)=%s', key, vals);
    end
end
end

function pairs = addLogical(pairs, s, field, key)
if isfield(s, field) && ~isempty(s.(field))
    if s.(field)
        pairs{end+1} = sprintf('%s=.TRUE.', key);
    else
        pairs{end+1} = sprintf('%s=.FALSE.', key);
    end
end
end

function str = formatArr(key, v)
% Format array as KEY(1)=v1,v2,...
v = v(:)';
vals = strjoin(arrayfun(@fmtNum, v, 'UniformOutput', false), ',');
str = sprintf('%s(1)=%s', key, vals);
end

function s = fmtNum(v)
% Format a number cleanly: integer-valued -> no decimal, else %g
if v == fix(v) && abs(v) < 1e10
    s = sprintf('%.1f', v);   % DATCOM needs at least one decimal for reals
else
    s = sprintf('%g', v);
end
end