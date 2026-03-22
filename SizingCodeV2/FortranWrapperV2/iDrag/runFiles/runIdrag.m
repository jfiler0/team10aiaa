function out = runIdrag(cfg)
%RUNIDRAG  Compute induced drag coefficient via MEX backend.
%
%   out = runIdrag(cfg)
%
%   cfg fields
%   ----------
%   Scalars:
%     .input_mode   0 = design (compute optimal loads for cl_design)
%                   1 = analysis (evaluate given loads)
%     .sym_flag     1 = symmetric configuration, 0 = asymmetric
%     .cl_design    design lift coefficient
%     .cm_flag      0 = no Cm constraint, 1 = apply Cm constraint
%     .cm_design    design pitching moment coefficient (about cg)
%     .xcg          x-location of centre of gravity (same units as xc)
%     .cp           chordwise centre-of-pressure location (fraction of chord)
%     .sref         reference area (projected onto xy-plane)
%     .cavg         average chord of reference surface(s)
%     .npanels      number of panels (max 5)
%
%   Arrays  (all npanels x 4, each row = one panel, columns = corners):
%     .xc           x corner coordinates  [npanels x 4]
%     .yc           y corner coordinates  [npanels x 4]
%     .zc           z corner coordinates  [npanels x 4]
%
%     Corner ordering per row:
%       col 1 = root LE,  col 2 = tip LE,  col 3 = tip TE,  col 4 = root TE
%
%   Vectors  (length npanels):
%     .nvortices    number of vortices per panel
%     .spacing_flag vortex spacing: 0=equal, 1=outboard, 2=inboard,
%                                   3=end-compressed
%
%   Scalar:
%     .load_flag    0 = loads are Cn values
%                   1 = loads are Cn*c/cavg values
%
%   Vector  (length >= sum(nvortices), required only when input_mode=1):
%     .loads        spanwise load distribution
%
%   out fields
%   ----------
%     .cd_induced   induced drag coefficient  (scalar double)

% -------------------------------------------------------------------------
%  Check MEX binary exists for this platform
% -------------------------------------------------------------------------
if exist('idrag_mex', 'file') ~= 3
    error('runIdrag:noMex', ...
        ['No idrag_mex.%s found for this platform.\n', ...
         'Run build_idrag_mex.m once to compile it.'], mexext);
end

% -------------------------------------------------------------------------
%  Validate and unpack cfg
% -------------------------------------------------------------------------
np = double(cfg.npanels);

% Geometry: force npanels x 4
xc = double(cfg.xc);
yc = double(cfg.yc);
zc = double(cfg.zc);
assert(isequal(size(xc), [np, 4]), 'runIdrag: xc must be npanels x 4');
assert(isequal(size(yc), [np, 4]), 'runIdrag: yc must be npanels x 4');
assert(isequal(size(zc), [np, 4]), 'runIdrag: zc must be npanels x 4');

% nvortices / spacing_flag: ensure column vectors length np
nv = double(cfg.nvortices(:));
sf = double(cfg.spacing_flag(:));
if isscalar(nv), nv = repmat(nv, np, 1); end
if isscalar(sf), sf = repmat(sf, np, 1); end
assert(numel(nv) >= np, 'runIdrag: nvortices must have >= npanels entries');
assert(numel(sf) >= np, 'runIdrag: spacing_flag must have >= npanels entries');
nv = nv(1:np);
sf = sf(1:np);

% loads: default to zeros for design mode
nv_tot = sum(nv);
if isfield(cfg, 'loads') && ~isempty(cfg.loads)
    loads = double(cfg.loads(:));
else
    loads = zeros(nv_tot, 1);
end

% -------------------------------------------------------------------------
%  Call MEX
% -------------------------------------------------------------------------
cd_induced = idrag_mex( ...
    double(cfg.input_mode),  ...
    double(cfg.sym_flag),    ...
    double(cfg.cl_design),   ...
    double(cfg.cm_flag),     ...
    double(cfg.cm_design),   ...
    double(cfg.xcg),         ...
    double(cfg.cp),          ...
    double(cfg.sref),        ...
    double(cfg.cavg),        ...
    double(cfg.npanels),     ...
    xc, yc, zc,              ...
    nv, sf,                  ...
    double(cfg.load_flag),   ...
    loads);

% -------------------------------------------------------------------------
%  Package output
% -------------------------------------------------------------------------
out.cd_induced = cd_induced;
end