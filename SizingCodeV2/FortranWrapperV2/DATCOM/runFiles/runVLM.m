function out = runVLM(geom, cfg, opts)
%RUNVLM  Run JKayVLM from MATLAB and return DATCOM-compatible tables.
%
%   out = runVLM(geom, cfg)
%   out = runVLM(geom, cfg, Name, Value, ...)
%
%   geom  - kevin_cad geometry struct (from loadAircraft)
%   cfg   - struct with fields:
%             .machVec  - vector of Mach numbers       e.g. [0.3, 0.5]
%             .alphaVec - alpha schedule (deg)          e.g. -4:2:20
%             .xcg      - CG x-location (m from nose)
%             .zcg      - CG z-location (m)
%             .Re       - Reynolds number (scalar or same length as machVec)
%           Optional:
%             .icase    - 1=lon, 2=lat, 3=full (default 3)
%             .ch       - height above ground m (default 1e6, OGE)
%
%   Name-Value opts:
%     'exePath'   - full path to JKayVLM exe  (default: auto-detect via which)
%     'outDir'    - where to write output files (default: exeDir)
%     'keepFiles' - true = keep input/output files (default false)
%     'cdCorr'    - true = add flat-plate skin-friction CD0 (default false)

arguments
    geom
    cfg
    opts.exePath   {mustBeTextScalar} = ""
    opts.outDir    {mustBeTextScalar} = ""
    opts.keepFiles (1,1) logical      = false
    opts.cdCorr    (1,1) logical      = false
end

% -------------------------------------------------------------------------
%  Locate JKayVLM executable
% -------------------------------------------------------------------------
exePath = char(opts.exePath);
if isempty(exePath)
    if ispc
        exePath = which('JKayVLM.exe');
    else
        exePath = which('JKayVLM');
    end
end
if isempty(exePath)
    error('runVLM:noExe', ...
        ['JKayVLM executable not found on the MATLAB path.\n', ...
         'Add the folder containing it to the path, or pass:\n', ...
         '  runVLM(geom, cfg, ''exePath'', ''C:\\path\\to\\JKayVLM.exe'')']);
end

% -------------------------------------------------------------------------
%  Resolve exeDir and HelperFiles — mirrors runDatcom layout exactly
%  Structure:  ParentFolder/HelperFiles/   and   ParentFolder/DATCOM/src/
%  So HelperFiles is two levels up from exeDir.
% -------------------------------------------------------------------------
exeDir    = fileparts(exePath);
exeDir    = char(java.io.File(exeDir).getCanonicalPath());

helperDir = fullfile(exeDir, '..', '..', 'HelperFiles');
helperDir = char(java.io.File(helperDir).getCanonicalPath());

% Inject HelperFiles into PATH for the duration of this function call
oldPath  = getenv('PATH');
setenv('PATH', [helperDir, pathsep, oldPath]);
cleanEnv = onCleanup(@() setenv('PATH', oldPath));  %#ok<NASGU>

% -------------------------------------------------------------------------
%  Output directory — default to exeDir so files land with DATCOM outputs
% -------------------------------------------------------------------------
outDir = char(opts.outDir);
if isempty(outDir)
    outDir = exeDir;
end
if ~isfolder(outDir), mkdir(outDir); end

% -------------------------------------------------------------------------
%  Validate cfg inputs
% -------------------------------------------------------------------------
machVec  = cfg.machVec(:)';
alphaVec = cfg.alphaVec(:)';
nMach    = numel(machVec);

ReVec = cfg.Re;
if isscalar(ReVec), ReVec = repmat(ReVec, 1, nMach); end
assert(numel(ReVec) == nMach, 'cfg.Re must be scalar or same length as cfg.machVec');

icase = 3;   if isfield(cfg,'icase'), icase = cfg.icase; end
ch    = 1e6; if isfield(cfg,'ch'),    ch    = cfg.ch;    end

colNames = {'Alpha','CD','CL','CM','CN','CA','XCP','CLA','CMA','CYB','CNB','CLB'};
PI = pi;

% -------------------------------------------------------------------------
%  Write shared geometry files into exeDir (Mach-independent)
% -------------------------------------------------------------------------
gcfg.mach  = machVec(1);
gcfg.xcg   = cfg.xcg;
gcfg.zcg   = cfg.zcg;
gcfg.icase = icase;
gcfg.ch    = ch;

[~, lonFile, latFile] = write_vlm_input(geom, gcfg, exeDir);
lonName = 'vlm_lon.dat';
latName = 'vlm_lat.dat';

% -------------------------------------------------------------------------
%  Loop over Mach numbers
% -------------------------------------------------------------------------
tables  = struct('caseTitle',{},'Mach',{},'Reynolds',{},'Sref',{},'data',{});
rawCell = cell(1, nMach);
scalars = struct([]);

for iM = 1:nMach
    M  = machVec(iM);
    Re = ReVec(iM);
    fprintf('runVLM: running M=%.2f ...\n', M);

    % Write main input file into exeDir
    mcfg.mach  = M;
    mcfg.xcg   = cfg.xcg;
    mcfg.zcg   = cfg.zcg;
    mcfg.icase = icase;
    mcfg.ch    = ch;

    mainFile = write_vlm_input(geom, mcfg, exeDir);
    [~, mainBase, mainExt] = fileparts(mainFile);
    mainName = [mainBase, mainExt];

    % Output file — JKayVLM writes to CWD (exeDir)
    outBase = sprintf('o%03d.txt', round(M*100));   
    exeOutPath = fullfile(exeDir, outBase);
    dstOutPath = fullfile(outDir, outBase);

    if isfile(exeOutPath), delete(exeOutPath); end
    if ~strcmp(exeDir, outDir) && isfile(dstOutPath), delete(dstOutPath); end

    % Build stdin response:
    %   line 1: output filename
    %   line 2: 'y' — read from file
    %   line 3: main input filename
    %   line 4: blank — satisfies READ(*,*) that replaced PAUSE
    stdinStr = sprintf('%s\ny\n%s\n\n', outBase, mainName);
    rspFile  = fullfile(exeDir, 'vlm_stdin.txt');
    fid = fopen(rspFile, 'w');
    fprintf(fid, '%s', stdinStr);
    fclose(fid);

    % Build system command — inject HelperFiles directly into the cmd.exe
    % session via set PATH=... so DLLs are found even if setenv didn't propagate.
    if ispc
        cmd = sprintf(...
            'cd /d "%s" && set "PATH=%s;%%PATH%%" && "%s" < "%s"', ...
            exeDir, helperDir, exePath, rspFile);
    else
        cmd = sprintf('cd "%s" && PATH="%s:$PATH" "%s" < "%s"', ...
                      exeDir, helperDir, exePath, rspFile);
    end

    [status, sysout] = system(cmd);

    if ~isfile(exeOutPath)
        warning('runVLM:noOutput', ...
            ['JKayVLM produced no output for M=%.2f\n', ...
             '  status = %d  (0x%08X)\n', ...
             '  0xC0000135 = DLL not found\n', ...
             '  0xC0000005 = crash\n', ...
             '  exeDir:    %s\n', ...
             '  helperDir: %s\n', ...
             '  stdout:    %s'], ...
            M, status, mod(status+2^32,2^32), exeDir, helperDir, sysout);
        continue
    end

    % Move output to outDir if different from exeDir
    if ~strcmp(exeDir, outDir)
        movefile(exeOutPath, dstOutPath, 'f');
        finalOutPath = dstOutPath;
    else
        finalOutPath = exeOutPath;
    end

    rawText     = fileread(finalOutPath);
    rawCell{iM} = rawText;

    % Parse scalar derivatives
    sc          = parseVLMOutput(rawText);
    sc.Mach     = M;
    sc.Reynolds = Re;
    if iM == 1
        scalars = sc;
    else
        scalars(iM) = sc;
    end

    % Reconstruct full alpha sweep from VLM slopes (linear theory)
    CLa  = sc.CLalpha;
    CL0  = sc.CL0;
    CMa  = sc.Cmalpha;
    CM0  = sc.CM0;
    CdiK = sc.CdiCL2;
    CYB  = sc.Cybeta;
    CNB  = sc.Cnbeta;
    CLB  = sc.Clbeta;

    nAlpha = numel(alphaVec);
    rows   = zeros(nAlpha, 12);

    for jA = 1:nAlpha
        alpha_deg = alphaVec(jA);
        alpha_rad = alpha_deg * PI / 180;

        CL   = CL0 + CLa * alpha_rad;
        CM   = CM0 + CMa * alpha_rad;
        CD_i = CL^2 * CdiK;

        CD0 = 0;
        if opts.cdCorr && ~isnan(Re)
            Re_L = Re * getval(geom.wing.average_chord);
            if Re_L > 0
                CD0 = 2.0 * 0.455 / (log10(Re_L))^2.58;
            end
        end
        CD = CD_i + CD0;

        CN  =  CL * cos(alpha_rad) + CD * sin(alpha_rad);
        CA  =  CD * cos(alpha_rad) - CL * sin(alpha_rad);

        if abs(CL) > 1e-6
            XCP = -(CM * getval(geom.wing.average_chord)) / CL + cfg.xcg;
        else
            XCP = NaN;
        end

        CLAdeg = CLa * PI / 180;
        CMAdeg = CMa * PI / 180;

        if abs(alpha_deg) < 0.5
            cyb = CYB; cnb = CNB; clb = CLB;
        else
            cyb = NaN; cnb = NaN; clb = NaN;
        end

        rows(jA,:) = [alpha_deg, CD, CL, CM, CN, CA, XCP, ...
                      CLAdeg, CMAdeg, cyb, cnb, clb];
    end

    tbl             = array2table(rows, 'VariableNames', colNames);
    entry.caseTitle = sprintf('JKayVLM M=%.2f', M);
    entry.Mach      = M;
    entry.Reynolds  = Re;
    entry.Sref      = getval(geom.ref_area);
    entry.data      = tbl;
    tables(end+1)   = entry; %#ok<AGROW>

    % Cleanup per-run files
    if ~opts.keepFiles
        deleteIfExists(mainFile);
        deleteIfExists(rspFile);
        deleteIfExists(finalOutPath);
    end
end

% Cleanup shared geometry files
if ~opts.keepFiles
    deleteIfExists(lonFile);
    deleteIfExists(latFile);
end

out.tables  = tables;
out.raw     = rawCell;
out.scalars = scalars;
end


% =========================================================================
function deleteIfExists(f)
if isfile(f), delete(f); end
end

function v = getval(x)
if isstruct(x), v = x.v; else, v = double(x); end
end