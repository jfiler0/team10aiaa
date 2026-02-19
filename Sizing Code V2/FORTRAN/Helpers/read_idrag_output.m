function cd = read_idrag_output(folder, outFile)
%READ_IDRAG_OUTPUT Reads idrag_result.txt

assert(isfile(outFile), "Missing output file: %s", outFile);

line = strtrim(readlines(outFile));
parts = split(line(1));
assert(parts(1) == "cd_induced", "Unexpected output format.");
cd = str2double(parts(2));
end
