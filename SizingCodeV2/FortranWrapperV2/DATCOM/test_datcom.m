%% test_datcom.m
% Verifies write_datcom_input + runDatcom + parseDatcomOutput against
% known reference values from ex1.out (EX1 Case 1, body-alone, M=0.6).
%
% EX1 Case 1 is ideal for verification:
%   - Body alone (no wing CLMAX termination)
%   - Single Mach, 11 clean alpha points from -6 to 24 deg
%   - No BUILD mode incremental blocks
%   - Known reference values from ex1.out lines 415-425
%
% Reference (ex1.out, Case 1, M=0.6, Re=4.28e6):
%   alpha  CD     CL      CM
%   -6.0   0.023  -0.021  -0.0205
%   -4.0   0.022  -0.014  -0.0137
%   -2.0   0.021  -0.007  -0.0068
%    0.0   0.021   0.000   0.0000
%    2.0   0.021   0.007   0.0068
%    4.0   0.022   0.014   0.0137
%    8.0   0.025   0.027   0.0273
%   12.0   0.029   0.041   0.0410
%   16.0   0.036   0.055   0.0546
%   20.0   0.044   0.069   0.0683
%   24.0   0.054   0.082   0.0820

clear; clc;

tol = 0.02;   % DATCOM output has 3 decimal places

%% --- Build input struct — exact reproduction of EX1 Case 1 ------------
cfg     = struct();
cfg.dim = 'FT';   % no BUILD card — single clean output block

c = struct();
c.caseid = 'APPROXIMATE AXISYMMETRIC BODY SOLUTION, EXAMPLE PROBLEM 1, CASE 1';

c.fltcon.nmach  = 1;
c.fltcon.mach   = 0.60;
c.fltcon.nalpha = 11;
c.fltcon.alschd = [-6, -4, -2, 0, 2, 4, 8, 12, 16, 20, 24];
c.fltcon.rnnub  = 4.28e6;

c.optins.sref  = 8.85;
c.optins.cbarr = 2.48;
c.optins.blref = 4.28;

c.synths.xcg = 4.14;
c.synths.zcg = -0.20;

c.body.nx    = 10;
c.body.bnose = 1;   % ogive nose
c.body.bln   = 2.59;
c.body.bla   = 3.67;
c.body.x = [0.0, 0.258, 0.589, 1.260, 2.260, 2.590, 2.930, 3.590, 4.570, 6.260];
c.body.r = [0.0, 0.186, 0.286, 0.424, 0.533, 0.533, 0.533, 0.533, 0.533, 0.533];
c.body.s = [0.0, 0.080, 0.160, 0.323, 0.751, 0.883, 0.939, 1.032, 1.032, 1.032];
c.body.p = [0.0, 1.00,  1.42,  2.01,  3.08,  3.34,  3.44,  3.61,  3.61,  3.61];

cfg.cases(1) = c;

%% --- Write and run -----------------------------------------------------
inpFile = write_datcom_input(cfg, 'test_ex1_case1.inp');
out     = runDatcom(inpFile, keepOut=true);
if isfile(inpFile), delete(inpFile); end

%% --- Find the M=0.6 block with 11 rows ---------------------------------
target = [];
for k = 1:numel(out.tables)
    t = out.tables(k);
    if abs(t.Mach - 0.6) < 0.01 && height(t.data) == 11
        if ~all(isnan(t.data.CL))
            target = t;
        end
    end
end

% Fall back: accept any M=0.6 block with the most rows
if isempty(target)
    best = 0;
    for k = 1:numel(out.tables)
        t = out.tables(k);
        if abs(t.Mach - 0.6) < 0.01 && height(t.data) > best
            best   = height(t.data);
            target = t;
        end
    end
end

fprintf('=== DATCOM EX1 Case 1 Verification (body-alone, M=0.6) ===\n');
fprintf('Blocks parsed: %d   Blocks at M=0.6: %d\n', ...
    numel(out.tables), sum(abs([out.tables.Mach]-0.6)<0.01));

% % n-blocks
% 
% fprintf('All blocks:\n');
% for k = 1:numel(out.tables)
%     t = out.tables(k);
%     fprintf('  [%d] M=%.2f  rows=%d  title="%s"\n', ...
%         k, t.Mach, height(t.data), t.caseTitle);
% end

if isempty(target)
    fprintf('FAIL: No M=0.6 block found in output.\n');
    fprintf('Check out.raw to see what DATCOM produced.\n');
    return
end

fprintf('Using block with %d rows: "%s"\n\n', height(target.data), target.caseTitle);

%% --- Reference values --------------------------------------------------
%       alpha   CD      CL       CM
ref = [ -6.0,  0.023, -0.021, -0.0205;
        -4.0,  0.022, -0.014, -0.0137;
        -2.0,  0.021, -0.007, -0.0068;
         0.0,  0.021,  0.000,  0.0000;
         2.0,  0.021,  0.007,  0.0068;
         4.0,  0.022,  0.014,  0.0137;
         8.0,  0.025,  0.027,  0.0273;
        12.0,  0.029,  0.041,  0.0410;
        16.0,  0.036,  0.055,  0.0546;
        20.0,  0.044,  0.069,  0.0683;
        24.0,  0.054,  0.082,  0.0820];

%% --- Compare -----------------------------------------------------------
d    = target.data;
pass = true;
nref = size(ref, 1);
nfound = 0;

fprintf('  %-6s  %-7s %-7s %-5s   %-7s %-7s %-5s   %-8s %-8s %-5s\n', ...
    'alpha', 'CD_got', 'CD_ref', 'CD?', 'CL_got', 'CL_ref', 'CL?', ...
    'CM_got', 'CM_ref', 'CM?');

for i = 1:nref
    a_ref  = ref(i,1);
    CD_ref = ref(i,2);
    CL_ref = ref(i,3);
    CM_ref = ref(i,4);

    idx = find(abs(d.Alpha - a_ref) < 0.1, 1);
    if isempty(idx)
        fprintf('  %-6.1f  NOT FOUND\n', a_ref);
        pass = false;
        continue
    end
    nfound = nfound + 1;

    CD = d.CD(idx);  CL = d.CL(idx);  CM = d.CM(idx);
    CD_ok = ~isnan(CD) && abs(CD - CD_ref) <= tol;
    CL_ok = ~isnan(CL) && abs(CL - CL_ref) <= tol;
    CM_ok = ~isnan(CM) && abs(CM - CM_ref) <= tol;

    if ~CD_ok || ~CL_ok || ~CM_ok, pass = false; end

    strs = {'FAIL','OK'};
    ok   = @(x) strs{double(x)+1};
    fprintf('  %-6.1f  %-7.3f %-7.3f %-5s   %-7.3f %-7.3f %-5s   %-8.4f %-8.4f %-5s\n', ...
        a_ref, CD, CD_ref, ok(CD_ok), CL, CL_ref, ok(CL_ok), CM, CM_ref, ok(CM_ok));
end

fprintf('\nFound %d/%d reference alpha points.\n', nfound, nref);
fprintf('\n');

if pass && nfound == nref
    fprintf('PASS — all %d points match within tolerance %.3f\n', nref, tol);
elseif pass
    fprintf('PARTIAL PASS — matched points are within tolerance, but %d points missing\n', ...
        nref - nfound);
else
    fprintf('FAIL — one or more values outside tolerance %.3f\n', tol);
    fprintf('\nDiagnostic tips:\n');
    fprintf('  1. Type: disp(out.tables(k).data) to inspect each block\n');
    fprintf('  2. Check input file was written correctly (compare to EX1.INP)\n');
    fprintf('  3. Parser title extraction may need adjustment for this output format\n');
end

