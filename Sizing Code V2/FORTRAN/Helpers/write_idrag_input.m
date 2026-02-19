function inFile = write_idrag_input(p, inFile, outFile)

%WRITE_IDRAG_INPUT Writes idrag_input.txt in fixed format Fortran driver expects.

% assert(isfile(inFile), "Input file path does not exist: %s", inFile);

fid = fopen(inFile, "w");
assert(fid>0, "Could not open %s for writing.", inFile);

% fprintf(fid, "%s\n", string(p.outfile));
fprintf(fid, "%s\n", string(outFile));
fprintf(fid, "%s\n", string(p.title));

fprintf(fid, "%d %d %d\n", p.input_mode, p.write_flag, p.sym_flag);
fprintf(fid, "%.16g\n", p.cl_design);
fprintf(fid, "%d %.16g %.16g %.16g\n", p.cm_flag, p.cm_design, p.xcg, p.cp);
fprintf(fid, "%.16g %.16g\n", p.sref, p.cavg);
fprintf(fid, "%d\n", p.npanels);

for i = 1:p.npanels
    fprintf(fid, "%d %d\n", p.nvortices(i), p.spacing_flag(i));
    for j = 1:4
        fprintf(fid, "%.16g %.16g %.16g\n", p.xc(i,j), p.yc(i,j), p.zc(i,j));
    end
end

fprintf(fid, "%d\n", p.load_flag);

if p.input_mode == 1
    loads = p.loads(:);
    for k = 1:numel(loads)
        fprintf(fid, "%.16g\n", loads(k));
    end
end

fclose(fid);
end
