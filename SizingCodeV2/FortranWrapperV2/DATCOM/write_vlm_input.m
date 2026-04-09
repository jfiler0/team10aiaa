function [mainFile, lonFile, latFile] = write_vlm_input(geom, cfg, outDir)
%WRITE_VLM_INPUT  Write JKayVLM input files from kevin_cad geom struct.
%
%   [mainFile, lonFile, latFile] = write_vlm_input(geom, cfg, outDir)
%
%   BP corner-point ordering required by JKayVLM GEOMETRY subroutine:
%     BP(1) = root LE    (y_root, x_LE_root)
%     BP(2) = tip  LE    (y_tip,  x_LE_tip )   <-- NOTE: tip, not root TE
%     BP(3) = tip  TE    (y_tip,  x_TE_tip )
%     BP(4) = root TE    (y_root, x_TE_root)
%
%   GEOMETRY computes:  B  = BP(2,y) - BP(1,y)   [span]
%                       Cr = BP(4,x) - BP(1,x)   [root chord]
%                       Ct = BP(3,x) - BP(2,x)   [tip  chord]
%
%   getval() handles fields that are either plain doubles or .v structs.

if nargin < 3 || isempty(outDir)
    outDir = pwd;
end
if ~isfolder(outDir), mkdir(outDir); end

if ~isfield(cfg,'icase'), cfg.icase = 3;   end
if ~isfield(cfg,'ch'),    cfg.ch    = 1e6; end

mach  = cfg.mach;
xcg   = cfg.xcg;
zcg   = cfg.zcg;
icase = cfg.icase;
ch    = cfg.ch;

Sref  = getval(geom.ref_area);
cbar  = getval(geom.wing.average_chord);
bspan = getval(geom.wing.span);

% -------------------------------------------------------------------------
%  Wing  (longitudinal section 1)
% -------------------------------------------------------------------------
sec  = geom.wing.sections;
nsec = numel(sec);

x_rLE  = getval(sec(1).le_x);
y_root = getval(sec(1).le_y);
z_root = getval(sec(1).le_z);
x_rTE  = getval(sec(1).te_x);

x_tLE  = getval(sec(nsec).le_x);
y_tip  = getval(sec(nsec).le_y);
z_tip  = getval(sec(nsec).le_z);
x_tTE  = getval(sec(nsec).te_x);

% Correct ordering: root-LE, tip-LE, tip-TE, root-TE
BPwing = [x_rLE, y_root, z_root;
          x_tLE, y_tip,  z_tip;
          x_tTE, y_tip,  z_tip;
          x_rTE, y_root, z_root];

slatWing = 0.0;
flapWing = 0.0;

% -------------------------------------------------------------------------
%  Horizontal tail / elevator  (longitudinal section 2)
% -------------------------------------------------------------------------
esec = geom.elevator.sections;
ney  = numel(esec);

x_hLE   = getval(esec(1).le_x);
y_hroot = getval(esec(1).le_y);
z_hroot = getval(esec(1).le_z);
x_hTE   = getval(esec(1).te_x);

x_htLE  = getval(esec(ney).le_x);
y_htip  = getval(esec(ney).le_y);
z_htip  = getval(esec(ney).le_z);
x_htTE  = getval(esec(ney).te_x);

% Correct ordering: root-LE, tip-LE, tip-TE, root-TE
BPelev = [x_hLE,  y_hroot, z_hroot;
          x_htLE, y_htip,  z_htip;
          x_htTE, y_htip,  z_htip;
          x_hTE,  y_hroot, z_hroot];

slatElev = 1.0;   % all-moving stabilator
flapElev = 0.0;

% -------------------------------------------------------------------------
%  Vertical tail / rudder  (lateral section 1)
%  JKayVLM lateral convention: body-z -> file-y, body-y -> file-z
%  VT spans in body-z (up), so root=lowest z, tip=highest z.
%  Correct ordering: root-LE, tip-LE, tip-TE, root-TE
% -------------------------------------------------------------------------
rsec = geom.rudder.sections;
nrs  = numel(rsec);

x_vLE   = getval(rsec(1).le_x);
z_vroot = getval(rsec(1).le_z);   % body-z at VT root (lower)
x_vTE   = getval(rsec(1).te_x);

x_vtLE  = getval(rsec(nrs).le_x);
z_vtip  = getval(rsec(nrs).le_z); % body-z at VT tip (upper)
x_vtTE  = getval(rsec(nrs).te_x);

% file col 2 = body-z (span direction), file col 3 = body-y = 0 (symmetric)
BPvt = [x_vLE,  z_vroot, 0;
        x_vtLE, z_vtip,  0;
        x_vtTE, z_vtip,  0;
        x_vTE,  z_vroot, 0];

slatVT = 0.0;
flapVT = 0.5;   % rudder = aft 50% of VT chord

% -------------------------------------------------------------------------
%  Write longitudinal geometry file
% -------------------------------------------------------------------------
lonFile = fullfile(outDir, 'vlm_lon.dat');
fid = fopen(lonFile, 'w');
fprintf(fid, 'JKayVLM longitudinal geometry - write_vlm_input.m\n');
fprintf(fid, '%10.5f\n', 2.0);

for j = 1:4
    fprintf(fid, '%10.5f%10.5f%10.5f\n', BPwing(j,1), BPwing(j,2), BPwing(j,3));
end
fprintf(fid, '%10.5f%10.5f\n', slatWing, flapWing);

for j = 1:4
    fprintf(fid, '%10.5f%10.5f%10.5f\n', BPelev(j,1), BPelev(j,2), BPelev(j,3));
end
fprintf(fid, '%10.5f%10.5f\n', slatElev, flapElev);
fclose(fid);

% -------------------------------------------------------------------------
%  Write lateral geometry file
% -------------------------------------------------------------------------
latFile = fullfile(outDir, 'vlm_lat.dat');
fid = fopen(latFile, 'w');
fprintf(fid, 'JKayVLM lateral geometry - write_vlm_input.m\n');
fprintf(fid, '%10.5f\n', 1.0);

for j = 1:4
    fprintf(fid, '%10.5f%10.5f%10.5f\n', BPvt(j,1), BPvt(j,2), BPvt(j,3));
end
fprintf(fid, '%10.5f%10.5f\n', slatVT, flapVT);
fclose(fid);

% -------------------------------------------------------------------------
%  Write main input file
% -------------------------------------------------------------------------
[~, lonBase, lonExt] = fileparts(lonFile);
[~, latBase, latExt] = fileparts(latFile);
lonName = [lonBase, lonExt];
latName = [latBase, latExt];

assert(numel(lonName) <= 12, 'lonFile name exceeds 12-char JKayVLM limit');
assert(numel(latName) <= 12, 'latFile name exceeds 12-char JKayVLM limit');

mainFile = fullfile(outDir, sprintf('vlm%03d.dat', round(mach*100)));
fid = fopen(mainFile, 'w');

fprintf(fid, '\n');
fprintf(fid, '%4.1f\n',  mach);
fprintf(fid, '%10.2f\n', Sref);
fprintf(fid, '%10.2f\n', cbar);
fprintf(fid, '%10.2f\n', bspan);
fprintf(fid, '%10.2f\n', ch);
fprintf(fid, '%1d\n',    icase);
fprintf(fid, '%10.3f\n', xcg);
fprintf(fid, '%10.3f\n', zcg);
fprintf(fid, '%-12s\n',  lonName);
if icase ~= 1 && icase ~= 4
    fprintf(fid, '%-12s\n', latName);
end
fprintf(fid, '%1d\n', 2);   % itail1 (HT = section 2)
fprintf(fid, '%1d\n', 2);   % itail2
fprintf(fid, '%1d\n', 1);   % iw1   (wing = section 1)
fprintf(fid, '%1d\n', 1);   % iw2

fclose(fid);
fprintf('write_vlm_input: wrote %s\n', mainFile);
end


% =========================================================================
function v = getval(x)
%GETVAL  Return numeric value whether input is plain double or a .v struct.
if isstruct(x), v = x.v; else, v = double(x); end
end