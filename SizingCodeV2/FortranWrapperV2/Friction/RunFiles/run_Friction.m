function out = runFriction(caseDef)
%RUNFRICTION  Compute skin-friction and form drag via MEX backend.
%
%   out = runFriction(caseDef)
%
%   caseDef fields
%   --------------
%     .title      string          case title (informational only)
%     .Sref       scalar          reference area, ft^2
%     .scale      scalar          model scale factor (1 = full size)
%     .inmd       scalar          0 => conds(:,2) is altitude in kft
%                                 1 => conds(:,2) is Re/ft * 1e-6
%     .components struct array    one element per component, fields:
%                    .name   string
%                    .Swet   wetted area, ft^2
%                    .Refl   reference length, ft
%                    .tc     thickness ratio t/c
%                    .icode  form-factor code  0=wing/tail  1=body/nacelle
%                    .trans  transition location (0 = fully turbulent)
%     .conds      [ncases x 2]   [Mach, alt_or_RnL]
%
%   out fields
%   ----------
%     .table      MATLAB table, ncases rows, columns:
%                   Mach | Alt_ft | Re_per_ft | Cd_friction | Cd_form | Cd_total
%     .raw        ncases x 6 double matrix (same data, no headers)
%     .title      copy of caseDef.title

% --------------------------------------------------------------------------
%  Check MEX is available
% --------------------------------------------------------------------------
if ~exist('friction_mex', 'file')
    error('runFriction:noMex', ...
        ['friction_mex MEX file not found.\n', ...
         'Run  build_friction_mex  to compile it.']);
end

% --------------------------------------------------------------------------
%  Unpack component struct array
% --------------------------------------------------------------------------
comps  = caseDef.components;
ncomp  = numel(comps);

swets  = double([comps.Swet]);     % 1 x ncomp
refls  = double([comps.Refl]);     % 1 x ncomp
tcs    = double([comps.tc]);       % 1 x ncomp
icodes = double([comps.icode]);    % 1 x ncomp
trans  = double([comps.trans]);    % 1 x ncomp

% --------------------------------------------------------------------------
%  Unpack flight conditions
% --------------------------------------------------------------------------
conds   = caseDef.conds;           % ncases x 2
machs   = double(conds(:, 1)');    % 1 x ncases  (row vector)
xinputs = double(conds(:, 2)');    % 1 x ncases

% --------------------------------------------------------------------------
%  Call MEX
% --------------------------------------------------------------------------
raw = friction_mex( ...
    double(caseDef.Sref),  ...
    double(caseDef.scale), ...
    double(caseDef.inmd),  ...
    swets, refls, tcs, icodes, trans, ...
    machs, xinputs);

% raw is [ncases x 6]:
%   Mach | Alt_ft | Re_per_ft | Cd_friction | Cd_form | Cd_total

% --------------------------------------------------------------------------
%  Package output
% --------------------------------------------------------------------------
colNames = {'Mach', 'Alt_ft', 'Re_per_ft', 'Cd_friction', 'Cd_form', 'Cd_total'};

out.raw   = raw;
out.table = array2table(raw, 'VariableNames', colNames);
out.title = caseDef.title;
end