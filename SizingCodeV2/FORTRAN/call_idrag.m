function cd_induced = call_idrag(p)
%CALL_IDRAG Run Fortran idrag and return cd_induced.
    folder       = fileparts(mfilename('fullpath'));
    exePath      = '..\Applications\run_idrag.exe';
    inFile       = '..\InputFiles\idrag_input.txt';
    stdinFile    = '..\InputFiles\idrag_stdin.txt';
    outFile      = 'idrag_output.txt';
    resultFile      = 'idrag_result.txt';
    outLog       = '..\LogFiles\run_stdout.txt';
    errLog       = '..\LogFiles\run_stderr.txt';
    workingPath  = fullfile(folder, 'OutputFiles');
    startingPath = pwd;
    cd(workingPath);

    assert(isfile(exePath), "Missing run_idrag.exe: %s", exePath);

    write_idrag_input(p, inFile, outFile);
    assert(isfile(inFile), "Input file was not created: %s", inFile);

    fid = fopen(stdinFile, 'w');
    fprintf(fid, "'%s'\n'%s'\n", inFile, outFile);
    fclose(fid);

    if isfile(outLog), delete(outLog); end
    if isfile(errLog), delete(errLog); end

    % cmd = sprintf('"%s" < "%s" > "%s" 2> "%s"', exePath, stdinFile, outLog, errLog);
    cmd = sprintf('"%s" "%s" > "%s" 2> "%s"', exePath, inFile, outLog, errLog);
    [status, txt] = system(cmd);

    if ~isempty(strtrim(txt))
        disp("=== system() text ==="); disp(txt);
    end
    if status ~= 0
        if isfile(outLog), disp("=== run_stdout.txt ==="); disp(fileread(outLog)); end
        if isfile(errLog), disp("=== run_stderr.txt ==="); disp(fileread(errLog)); end
        cd(startingPath);
        error("Fortran execution failed. See logs in %s", folder);
    end

    cd_induced = read_idrag_output(folder, resultFile);
    cd(startingPath);
end