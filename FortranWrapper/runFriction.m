function out = runFriction(caseDef)
%RUNFRICTION  MATLAB wrapper for friction_cli.exe
%
% caseDef fields:
%   .title  (char)
%   .Sref   (ft^2)
%   .scale  (unitless)
%   .inmd   (0 or 1)
%   .components: struct array with fields:
%       name (char), Swet (ft^2), Refl (ft), tc, icode, trans
%   .conds: Nx2 array:
%       [Mach, xinput] where xinput = h[kft] if inmd=0, or (Re/ft)/1e6 if inmd=1
%
% output:
%   out.table: table from CSV with drag breakdown
%
% Requirements:
%   friction_cli.exe must be on PATH or in same folder as this .m file.

    arguments
        caseDef struct
    end

    exeName = "friction_cli.exe";  % change for linux/mac: "friction_cli"
    thisDir = fileparts(mfilename("fullpath"));

    inFile  = fullfile(tempdir, "friction_case.dat");
    outCSV  = fullfile(tempdir, "friction_out.csv");

    % 1) Write dataset file
    writeFrictionDataset(inFile, caseDef);

    % 2) Run Fortran executable
    % Use quotes around paths (spaces-safe)
    cmd = sprintf('"%s" "%s" "%s"', fullfile(thisDir, exeName), inFile, outCSV);
    [status, cmdout] = system(cmd);

    if status ~= 0
        error("friction_cli failed (status=%d).\nCommand output:\n%s", status, cmdout);
    end

    % 3) Read CSV output
    T = readtable(outCSV);

    out = struct();
    out.table = T;
end

function writeFrictionDataset(filename, c)
% Writes in the classic dataset layout your Fortran reader expects.

    fid = fopen(filename, 'w');
    assert(fid>0, "Could not open input file for writing: %s", filename);

    cleanup = onCleanup(@() fclose(fid));

    % Title line
    fprintf(fid, '%s\n', c.title);

    % SREF SCALE NCOMP INMD
    ncomp = numel(c.components);
    fprintf(fid, '%.6f %.6f %.0f %.0f\n', c.Sref, c.scale, ncomp, c.inmd);

    % Component lines:
    % name (first ~16 chars), then: SWET REFL TC ICODE TRANS
    for i = 1:ncomp
        comp = c.components(i);

        % enforce max 16 chars for name field (Fortran takes first 16)
        name16 = comp.name;
        if strlength(name16) > 16
            name16 = extractBefore(name16, 17);
        end

        % pad name to 16 chars so numeric parsing starts at col 17
        name16 = pad(name16, 16, 'right');

        fprintf(fid, '%s %12.5f %10.5f %10.5f %6.1f %10.5f\n', ...
            name16, comp.Swet, comp.Refl, comp.tc, comp.icode, comp.trans);
    end

    % Flight conditions: Mach xinput; terminate with Mach <= 0
    conds = c.conds;
    for k = 1:size(conds,1)
        fprintf(fid, '%10.3f %10.3f\n', conds(k,1), conds(k,2));
    end
    fprintf(fid, '%10.3f %10.3f\n', 0.0, 0.0); % terminator
end
