function cd_induced = call_idrag(p)
%CALL_IDRAG Run Fortran wrapper and return cd_induced (Windows robust)

    folder  = fileparts(mfilename('fullpath'));

    exePath = fullfile(folder,"Applications/", "run_idrag.exe");
    inFile  = fullfile(folder,"InputFiles/", "idrag_input.txt");
    outFile = fullfile(folder,"OutputFiles/", "idrag_result.txt");
    outLog = fullfile(folder,"LogFiles/", "run_stdout.txt");
    errLog = fullfile(folder,"LogFiles/", "run_stderr.txt");

    if ~isfile(exePath)
        error("Missing run_idrag.exe: %s", exePath);
    end

    % 1) Write input
    write_idrag_input(p, inFile, outFile);
    if ~isfile(inFile)
        error("Input file was not created: %s", inFile);
    end
   
    if isfile(outLog), delete(outLog); end
    if isfile(errLog), delete(errLog); end

    % 3) Run using PowerShell (very robust quoting) + redirect logs
    %    -LiteralPath handles spaces safely
    psCmd = sprintf([ ...
        'powershell -NoProfile -Command "', ...
        '$ErrorActionPreference=''Stop''; ', ...
        'Set-Location -LiteralPath ''%s''; ', ...
        '& ''%s'' ''%s'' 1> ''%s'' 2> ''%s''; ', ...
        'exit $LASTEXITCODE', ...
        '"'], ...
        folder, exePath, inFile, outLog, errLog);

    [status, txt] = system(psCmd);

    % 4) Always show exit status + any captured launcher text
    fprintf("Fortran launcher exit STATUS = %d\n", status);
    if ~isempty(strtrim(txt))
        disp("=== system() text ===");
        disp(txt);
    end

    % 5) If failed, show logs (if they exist)
    if status ~= 0
        if isfile(outLog)
            disp("=== run_stdout.txt ===");
            disp(fileread(outLog));
        end
        if isfile(errLog)
            disp("=== run_stderr.txt ===");
            disp(fileread(errLog));
        end

        error("Fortran execution failed. See run_stdout.txt / run_stderr.txt in %s", folder);
    end

    % 6) Read result
    cd_induced = read_idrag_output(folder, outFile);

end
