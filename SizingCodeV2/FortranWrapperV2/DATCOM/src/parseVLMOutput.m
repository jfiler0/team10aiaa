function out = parseVLMOutput(rawText)
%PARSEVLMOUTPUT  Parse JKayVLM output text into a scalar struct.
%
%   out = parseVLMOutput(rawText)
%   out = parseVLMOutput(fileread('o030.txt'))
%
%   Strategy: for each line, identify the quantity by keyword then extract
%   the LAST number on that line.  This cleanly handles labels that contain
%   embedded '=' signs (e.g. "Cdi(at alpha = 0)   =   0.00123") without
%   needing complex regex escaping.
%
%   Output fields (NaN if not found):
%     .Mach .Sref .cbar .bspan .xcg
%     .CL0 .CM0 .Cdi0
%     .CLalpha .Cmalpha .CmCL .CdiCL2 .CL5 .Cdi5
%     .CLq .CMq
%     .Cybeta .Cnbeta .Clbeta
%     .Cyr .Cnr .Clr
%     .Clp .Cnp

out = struct( ...
    'Mach',    NaN, 'Sref',    NaN, 'cbar',    NaN, 'bspan',   NaN, ...
    'xcg',     NaN, ...
    'CL0',     NaN, 'CM0',     NaN, 'Cdi0',    NaN, ...
    'CLalpha', NaN, 'Cmalpha', NaN, 'CmCL',    NaN, 'CdiCL2',  NaN, ...
    'CL5',     NaN, 'Cdi5',    NaN, ...
    'CLq',     NaN, 'CMq',     NaN, ...
    'Cybeta',  NaN, 'Cnbeta',  NaN, 'Clbeta',  NaN, ...
    'Cyr',     NaN, 'Cnr',     NaN, 'Clr',     NaN, ...
    'Clp',     NaN, 'Cnp',     NaN);

lines = splitlines(string(rawText));

for k = 1:numel(lines)
    line = char(lines(k));
    n    = lastnum(line);           % last number on this line
    if isnan(n), continue; end

    % Match by the unique keyword fragment on each line.
    % Order matters for lines that share substrings — most specific first.
    if     contains(line, 'MACH NUMBER',        'IgnoreCase',true), out.Mach    = n;
    elseif contains(line, 'Sref',               'IgnoreCase',true) && ...
           contains(line, '='),                                      out.Sref    = n;
    elseif contains(line, 'c ref',              'IgnoreCase',true), out.cbar    = n;
    elseif contains(line, 'b ref',              'IgnoreCase',true), out.bspan   = n;
    elseif contains(line, 'X-cg',              'IgnoreCase',true), out.xcg     = n;

    % CL0 before CL-alpha / CL-q so the shorter token doesn't shadow them
    elseif contains(line, 'CL0 ')                                              , out.CL0      = n;
    elseif contains(line, 'Cm0 ')                                              , out.CM0      = n;
    elseif contains(line, 'Cdi(at alpha = 0)',  'IgnoreCase',true)             , out.Cdi0     = n;

    elseif contains(line, 'CL-alpha',           'IgnoreCase',true)             , out.CLalpha  = n;
    elseif contains(line, 'Cm-alpha',           'IgnoreCase',true)             , out.Cmalpha  = n;
    elseif contains(line, 'Cm/CL',              'IgnoreCase',true)             , out.CmCL     = n;
    elseif contains(line, 'Cdi/CL',             'IgnoreCase',true)             , out.CdiCL2   = n;
    elseif contains(line, 'CL (at alpha = 5)',  'IgnoreCase',true)             , out.CL5      = n;
    elseif contains(line, 'Cdi(at alpha = 5)',  'IgnoreCase',true)             , out.Cdi5     = n;

    elseif contains(line, 'CL-q',               'IgnoreCase',true)             , out.CLq      = n;
    elseif contains(line, 'CM-q',               'IgnoreCase',true)             , out.CMq      = n;

    elseif contains(line, 'Cy-beta',            'IgnoreCase',true)             , out.Cybeta   = n;
    elseif contains(line, 'Cn-beta',            'IgnoreCase',true)             , out.Cnbeta   = n;
    elseif contains(line, 'Cl-beta',            'IgnoreCase',true)             , out.Clbeta   = n;

    elseif contains(line, 'Cy-r',               'IgnoreCase',true)             , out.Cyr      = n;
    elseif contains(line, 'Cn-r',               'IgnoreCase',true)             , out.Cnr      = n;
    elseif contains(line, 'Cl-r',               'IgnoreCase',true)             , out.Clr      = n;

    elseif contains(line, 'Cl-p',               'IgnoreCase',true)             , out.Clp      = n;
    elseif contains(line, 'Cn-p',               'IgnoreCase',true)             , out.Cnp      = n;
    end
end
end


% =========================================================================
function n = lastnum(line)
%LASTNUM  Extract the last number on a text line. Returns NaN if none found.
%
%  Handles: integers, decimals, scientific notation (1.2E+03), negatives.
tok = regexp(line, '[-+]?\d+\.?\d*(?:[Ee][+-]?\d+)?', 'match');
if isempty(tok)
    n = NaN;
else
    n = str2double(tok{end});
    if isnan(n), n = NaN; end   % str2double returns NaN for non-numeric
end
end