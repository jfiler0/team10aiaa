%BUILD_IDRAG_MEX  Compile idrag_mex.F into a platform MEX binary.
%
%   Automatically installs the MinGW-w64 MATLAB Add-On and configures the
%   Fortran MEX compiler if not already present.
%
%   idrag_mex.F, idrag_core.f, and sgefs.f must all be in the same folder
%   as this script.
%
%   Usage:
%       build_idrag_mex
%
%   Re-run after editing any of the Fortran source files.

fprintf('\n=== build_idrag_mex ===\n');

% -------------------------------------------------------------------------
%  0. Locate source files (must be in the same folder as this script)
% -------------------------------------------------------------------------
scriptDir = fileparts(mfilename('fullpath'));

required = {'idrag_mex.F', 'idrag_core.f', 'sgefs.f'};
for k = 1:numel(required)
    f = fullfile(scriptDir, required{k});
    if ~isfile(f)
        error('build_idrag_mex:missing', ...
            'Cannot find %s in:\n  %s', required{k}, scriptDir);
    end
end

% Change into the source folder so mex output lands next to the source.
origDir    = cd(scriptDir);
cleanupDir = onCleanup(@() cd(origDir)); %#ok<NASGU>

% -------------------------------------------------------------------------
%  1. Ensure MinGW-w64 Add-On is installed  (Windows only)
% -------------------------------------------------------------------------
if ispc
    ensure_mingw_installed();
end

% -------------------------------------------------------------------------
%  2. Ensure a Fortran MEX compiler is selected
% -------------------------------------------------------------------------
ensure_fortran_compiler();

% -------------------------------------------------------------------------
%  3. Compile  (gateway + core + linear solver in one mex call)
% -------------------------------------------------------------------------
fprintf('\nCompiling idrag_mex.F + idrag_core.f + sgefs.f ...\n');
try
    mex('idrag_mex.F', 'idrag_core.f', 'sgefs.f', '-output', 'idrag_mex');
    fprintf('\nBuild SUCCESS: idrag_mex.%s\n', mexext);
    fprintf('Location: %s\n\n', fullfile(scriptDir, ['idrag_mex.' mexext]));
catch ME
    fprintf(2, '\nBuild FAILED: %s\n', ME.message);
    fprintf(2, 'Try the verbose build for details:\n');
    fprintf(2, '  mex -v idrag_mex.F idrag_core.f sgefs.f -output idrag_mex\n\n');
    return
end

% -------------------------------------------------------------------------
%  4. Smoke test — flat rectangular wing, CL=0.5
% -------------------------------------------------------------------------
fprintf('Running smoke test (rectangular wing, CL=0.5) ...\n');
try
    cfg = struct();
    cfg.input_mode  = 0;      % design mode
    cfg.sym_flag    = 1;      % symmetric
    cfg.cl_design   = 0.5;
    cfg.cm_flag     = 0;
    cfg.cm_design   = 0.0;
    cfg.xcg         = 0.25;
    cfg.cp          = 0.25;
    cfg.sref        = 1.0;
    cfg.cavg        = 1.0;
    cfg.npanels     = 1;
    cfg.xc          = [0, 0, 1, 1];   % 1 x 4
    cfg.yc          = [0, 1, 1, 0];
    cfg.zc          = [0, 0, 0, 0];
    cfg.nvortices   = 30;
    cfg.spacing_flag = 3;
    cfg.load_flag   = 1;
    cfg.loads       = [];

    out = runIdrag(cfg);
    fprintf('  cd_induced = %.8f\n', out.cd_induced);
    fprintf('Smoke test PASSED.\n\n');
catch ME2
    fprintf(2, 'Smoke test failed: %s\n', ME2.message);
    fprintf(2, 'Make sure runIdrag.m is on the MATLAB path.\n\n');
end


% =========================================================================
%  Helper: install MinGW-w64 Add-On if not already present
% =========================================================================
function ensure_mingw_installed()

    ADDON_NAME = 'MATLAB Support for MinGW-w64 C/C++/Fortran Compiler';

    try
        installed = matlab.addons.installedAddons();
        already   = any(contains(installed.Name, 'MinGW', 'IgnoreCase', true));
    catch
        already = true;
    end

    if already
        fprintf('MinGW-w64 Add-On: already installed.\n');
        return
    end

    fprintf('MinGW-w64 Add-On not found. Attempting automatic install ...\n');
    fprintf('(Requires internet connection. May take a minute.)\n');

    try
        matlab.addons.installAddon(ADDON_NAME);
        fprintf('MinGW-w64 Add-On installed successfully.\n');
    catch ME_install
        fprintf(2, '\nAutomatic install failed: %s\n', ME_install.message);
        fprintf(2, ['Please install manually:\n', ...
            '  Home tab > Add-Ons > Get Add-Ons\n', ...
            '  Search "MinGW-w64 Compiler" and click Install.\n', ...
            '  Then re-run build_idrag_mex.\n\n']);
        try
            matlab.addons.addonExplorer('MinGW');
        catch
        end
        error('build_idrag_mex:noMinGW', ...
            'MinGW-w64 must be installed before building the MEX file.');
    end
end


% =========================================================================
%  Helper: make sure a Fortran MEX compiler is configured
% =========================================================================
function ensure_fortran_compiler()

    try
        cc = mex.getCompilerConfigurations('Fortran', 'Selected');
    catch
        cc = [];
    end

    if ~isempty(cc)
        fprintf('MEX Fortran compiler: %s  (%s)\n', cc.Name, cc.Version);
        return
    end

    try
        all_cc = mex.getCompilerConfigurations('Fortran', 'Installed');
    catch
        all_cc = [];
    end

    if isempty(all_cc)
        error('build_idrag_mex:noFortranCompiler', ...
            ['No Fortran MEX compiler found.\n', ...
             'Windows: install the MinGW-w64 Add-On (see above).\n', ...
             'Linux:   sudo apt install gfortran\n', ...
             'Mac:     brew install gcc\n', ...
             'Then re-run build_idrag_mex.']);
    end

    fprintf('No Fortran MEX compiler selected — configuring automatically ...\n');
    try
        mex('-setup', all_cc(1).MexOpt);
        cc = mex.getCompilerConfigurations('Fortran', 'Selected');
        fprintf('MEX Fortran compiler: %s  (%s)\n', cc.Name, cc.Version);
    catch
        fprintf('Opening compiler selector — choose the Fortran (gfortran) option.\n');
        mex('-setup', 'fortran');
        cc = mex.getCompilerConfigurations('Fortran', 'Selected');
        if isempty(cc)
            error('build_idrag_mex:setupAborted', ...
                'No compiler selected. Re-run build_idrag_mex to try again.');
        end
        fprintf('MEX Fortran compiler: %s  (%s)\n', cc.Name, cc.Version);
    end
end