%BUILD_FRICTION_MEX  Compile friction_mex.F90 into a platform MEX binary.
%
%   Automatically installs the MinGW-w64 MATLAB Add-On and configures the
%   Fortran MEX compiler if they are not already present.
%
%   Usage (run from the folder containing friction_mex.F90):
%       build_friction_mex
%
%   Re-run after editing friction_mex.F90 to rebuild the binary.

fprintf('\n=== build_friction_mex ===\n');

% -------------------------------------------------------------------------
%  0. Locate source file (must be in the same folder as this script)
% -------------------------------------------------------------------------
scriptDir = fileparts(mfilename('fullpath'));
src       = fullfile(scriptDir, 'friction_mex.F90');

if ~isfile(src)
    error('build_friction_mex:missing', ...
        'Cannot find friction_mex.F90 in:\n  %s', scriptDir);
end

% Change into that folder so mex output lands next to the source.
origDir    = cd(scriptDir);
cleanupDir = onCleanup(@() cd(origDir));  %#ok<NASGU>

% -------------------------------------------------------------------------
%  1. Ensure MinGW-w64 Add-On is installed  (Windows only)
%     On Linux/Mac gfortran is installed at the OS level; skip this block.
% -------------------------------------------------------------------------
if ispc
    ensure_mingw_installed();
end

% -------------------------------------------------------------------------
%  2. Ensure a Fortran MEX compiler is selected
% -------------------------------------------------------------------------
ensure_fortran_compiler();

% -------------------------------------------------------------------------
%  3. Compile
% -------------------------------------------------------------------------
fprintf('\nCompiling friction_mex.F90 ...\n');
try
    mex('friction_mex.F90', '-output', 'friction_mex');
    fprintf('\nBuild SUCCESS: friction_mex.%s\n', mexext);
    fprintf('Location: %s\n\n', fullfile(scriptDir, ['friction_mex.' mexext]));
catch ME
    fprintf(2, '\nBuild FAILED: %s\n', ME.message);
    fprintf(2, 'Try the verbose build for details:\n');
    fprintf(2, '  mex -v friction_mex.F90 -output friction_mex\n\n');
    return
end

% -------------------------------------------------------------------------
%  4. Smoke test
% -------------------------------------------------------------------------
fprintf('Running smoke test (F-15 @ M1.2 / 35 kft) ...\n');
try
    caseDef.title = 'F-15 smoke test';
    caseDef.Sref  = 608;
    caseDef.scale = 1;
    caseDef.inmd  = 0;
    caseDef.components = struct( ...
        'name',  {'FUSELAGE','OUTB''D WING','HORIZ. TAIL','TWIN   V. T.'}, ...
        'Swet',  {550.00,  698.00, 222.00, 250.00}, ...
        'Refl',  {54.65,   12.7,   8.3,    6.7   }, ...
        'tc',    {0.055,   0.050,  0.050,  0.045 }, ...
        'icode', {1,       0,      0,      0     }, ...
        'trans', {0.0,     0.0,    0.0,    0.0   } ...
    );
    caseDef.conds = [1.2, 35.0];
    out = run_Friction(caseDef);
    disp(out.table);
    fprintf('Smoke test PASSED.\n\n');
catch ME2
    fprintf(2, 'Smoke test failed: %s\n', ME2.message);
    fprintf(2, 'Make sure runFriction.m is on the MATLAB path.\n\n');
end


% =========================================================================
%  Helper: install MinGW-w64 Add-On if not already present
% =========================================================================
function ensure_mingw_installed()

    ADDON_NAME = 'MATLAB Support for MinGW-w64 C/C++/Fortran Compiler';

    % Check whether any Add-On with "MinGW" in its name is already installed.
    try
        installed = matlab.addons.installedAddons();
        already   = any(contains(installed.Name, 'MinGW', 'IgnoreCase', true));
    catch
        % matlab.addons not available on very old MATLAB — assume present.
        already = true;
    end

    if already
        fprintf('MinGW-w64 Add-On: already installed.\n');
        return
    end

    % Not installed — attempt silent install from the Add-On server.
    fprintf('MinGW-w64 Add-On not found. Attempting automatic install ...\n');
    fprintf('(This requires an internet connection and may take a minute.)\n');

    try
        matlab.addons.installAddon(ADDON_NAME);
        fprintf('MinGW-w64 Add-On installed successfully.\n');
    catch ME_install
        % Silent install failed (no internet, permissions, old MATLAB, etc.)
        fprintf(2, '\nAutomatic install failed: %s\n', ME_install.message);
        fprintf(2, ['\nPlease install manually:\n', ...
            '  Home tab > Add-Ons > Get Add-Ons\n', ...
            '  Search for "MinGW-w64 Compiler" and click Install.\n', ...
            '  Then re-run build_friction_mex.\n\n']);

        % Try to open the Add-On Explorer pre-filtered to MinGW.
        try
            matlab.addons.addonExplorer('MinGW');
        catch
            % addonExplorer not available on this MATLAB version — skip.
        end

        error('build_friction_mex:noMinGW', ...
            'MinGW-w64 must be installed before building the MEX file.');
    end
end


% =========================================================================
%  Helper: make sure a Fortran MEX compiler is configured
% =========================================================================
function ensure_fortran_compiler()

    % Check whether one is already selected.
    try
        cc = mex.getCompilerConfigurations('Fortran', 'Selected');
    catch
        cc = [];
    end

    if ~isempty(cc)
        fprintf('MEX Fortran compiler: %s  (%s)\n', cc.Name, cc.Version);
        return
    end

    % None selected — see if any Fortran compiler is *available* to choose.
    try
        all_cc = mex.getCompilerConfigurations('Fortran', 'Installed');
    catch
        all_cc = [];
    end

    if isempty(all_cc)
        error('build_friction_mex:noFortranCompiler', ...
            ['No Fortran MEX compiler found.\n', ...
             'On Windows: install the MinGW-w64 Add-On (see above).\n', ...
             'On Linux:   sudo apt install gfortran\n', ...
             'On Mac:     brew install gcc\n', ...
             'Then re-run build_friction_mex.']);
    end

    % At least one compiler exists but none is selected — auto-select the
    % first available one (usually the only one: MinGW gfortran on Windows).
    fprintf('No Fortran MEX compiler selected — configuring automatically ...\n');
    try
        cfgFile = all_cc(1).MexOpt;   % path to the compiler XML config
        mex('-setup', cfgFile);
        cc = mex.getCompilerConfigurations('Fortran', 'Selected');
        fprintf('MEX Fortran compiler: %s  (%s)\n', cc.Name, cc.Version);
    catch
        % Auto-select from config file failed; fall back to interactive prompt.
        fprintf('Opening compiler selector — choose the Fortran (gfortran) option.\n');
        mex('-setup', 'fortran');

        cc = mex.getCompilerConfigurations('Fortran', 'Selected');
        if isempty(cc)
            error('build_friction_mex:setupAborted', ...
                'No Fortran compiler was selected. Re-run build_friction_mex to try again.');
        end
        fprintf('MEX Fortran compiler: %s  (%s)\n', cc.Name, cc.Version);
    end
end