function tables = parseDatcomOutput(rawText)
%PARSEDATCOMOUTPUT  Parse DATCOM datcom.out text into structured tables.
%
%   tables = parseDatcomOutput(rawText)
%   tables = parseDatcomOutput(fileread('datcom.out'))
%
%   Returns a struct array, one element per (case title × Mach) block
%   found in the output.  Each element has:
%
%     .caseTitle  string    CASEID label from the input deck
%     .Mach       double    Mach number for this block
%     .Reynolds   double    Reynolds number per ft
%     .Sref       double    Reference area (ft^2)
%     .data       table     Columns:
%                             Alpha  - angle of attack (deg)
%                             CD     - drag coefficient
%                             CL     - lift coefficient
%                             CM     - pitching moment coefficient
%                             CN     - normal force coefficient
%                             CA     - axial force coefficient
%                             XCP    - centre of pressure location
%                             CLA    - lift curve slope (per deg)
%                             CMA    - pitching moment slope (per deg)
%                             CYB    - side force derivative (per deg)
%                             CNB    - yawing moment derivative (per deg)
%                             CLB    - rolling moment derivative (per deg)
%
%   Values printed as "NDM" (no datcom method) are stored as NaN.
%   The value "******" for XCP at alpha=0 is stored as NaN.

tables = struct('caseTitle', {}, 'Mach', {}, 'Reynolds', {}, ...
                'Sref', {}, 'data', {});

lines = splitlines(string(rawText));
nlines = numel(lines);

% State variables
currentTitle   = '';
currentMach    = NaN;
currentRe      = NaN;
currentSref    = NaN;
inCoeffTable   = false;
inAuxSection   = false;   % true when inside AUXILIARY AND PARTIAL OUTPUT block
colNames       = {'Alpha','CD','CL','CM','CN','CA','XCP', ...
                  'CLA','CMA','CYB','CNB','CLB'};
rowBuffer      = [];

k = 1;
while k <= nlines
    line = char(lines(k));
    tline = strtrim(line);

    % ------------------------------------------------------------------
    %  Detect auxiliary output section — skip its coefficient tables
    %  to avoid duplicating the main results
    % ------------------------------------------------------------------
    if contains(line, 'AUXILIARY AND PARTIAL OUTPUT')
        inAuxSection = true;
    end
    if contains(line, 'CHARACTERISTICS AT ANGLE OF ATTACK') && ...
       ~contains(line, 'AUXILIARY')
        inAuxSection = false;
        % Title is 2 lines below this header (skip blank)
        if k+3 <= nlines
            titleLine = strtrim(char(lines(k+3)));
            if ~isempty(titleLine)
                currentTitle = titleLine;
            end
        end
    end

    % ------------------------------------------------------------------
    %  Flight condition / Mach line
    %  Format: "0 0.600                                   4.2800E+06  ..."
    %  The line starts with "0 " followed by Mach, then lots of spaces,
    %  then Reynolds number, then Sref.
    % ------------------------------------------------------------------
    tok = regexp(line, ...
        '^0\s+([\d.]+)\s+[\d.E+\-]*\s+([\d.E+\-]+)\s+([\d.E+\-]+)', ...
        'tokens', 'once');
    if ~isempty(tok)
        % Save any pending table before starting new Mach block
        if inCoeffTable && ~isempty(rowBuffer)
            tables(end+1) = makeTableEntry(currentTitle, currentMach, ...  %#ok<AGROW>
                currentRe, currentSref, rowBuffer, colNames);
            rowBuffer    = [];
            inCoeffTable = false;
        end
        currentMach = str2double(tok{1});
        currentRe   = str2double(tok{2});
        currentSref = str2double(tok{3});
    end

    % ------------------------------------------------------------------
    %  Column header line — marks start of a coefficient table
    %  "0 ALPHA     CD       CL       CM       CN       CA       XCP ..."
    % ------------------------------------------------------------------
    if ~inAuxSection && contains(line, 'ALPHA') && contains(line, 'CD') && ...
       contains(line, 'CL')    && contains(line, 'CM')
        % Save previous block if any
        if inCoeffTable && ~isempty(rowBuffer)
            tables(end+1) = makeTableEntry(currentTitle, currentMach, ...  %#ok<AGROW>
                currentRe, currentSref, rowBuffer, colNames);
            rowBuffer = [];
        end
        inCoeffTable = true;
        k = k + 1;
        continue
    end

    % ------------------------------------------------------------------
    %  Data rows within the coefficient table
    %  First token is alpha (numeric).  NDM / ****** handled as NaN.
    % ------------------------------------------------------------------
    if inCoeffTable
        % Detect lines that end the coefficient table:
        %   downwash section (Q/QINF, EPSLON), ANALYSIS TERMINATED,
        %   DATCOM form-feed ('1' or '1 text', NOT '12.0', '16.0'),
        %   blank lines, or 0*** warnings
        isDownwash = contains(line, 'Q/QINF') || contains(line, 'EPSLON') || ...
                     contains(line, 'ANALYSIS TERMINATED');
        isFormFeed = strcmp(tline, '1') || ...
                     (startsWith(tline, '1') && ~isempty(regexp(tline, '^1\s', 'once')));
        if isempty(tline) || isFormFeed || startsWith(tline, '0***') || isDownwash
            if ~isempty(rowBuffer)
                tables(end+1) = makeTableEntry(currentTitle, currentMach, ...  %#ok<AGROW>
                    currentRe, currentSref, rowBuffer, colNames);
                rowBuffer    = [];
                inCoeffTable = false;
            end
            k = k + 1;
            continue
        end

        % Try to parse as a data row: leading number (alpha angle)
        if ~isempty(regexp(tline, '^-?\d+\.\d', 'once'))
            row = parseDataRow(line);
            if ~isempty(row)
                rowBuffer(end+1, :) = row;  %#ok<AGROW>
            end
        end
    end

    k = k + 1;
end

% Flush any remaining open table
if inCoeffTable && ~isempty(rowBuffer)
    tables(end+1) = makeTableEntry(currentTitle, currentMach, ...
        currentRe, currentSref, rowBuffer, colNames);
end

end % parseDatcomOutput


% =========================================================================
function row = parseDataRow(line)
%PARSEDATAROW  Convert one coefficient data line into a 1x12 double row.
%
% Handles:
%   - Normal numeric values
%   - "NDM" (no datcom method) -> NaN
%   - "******" (undefined XCP) -> NaN
%   - Partially-filled rows (remaining cols = NaN)

row = NaN(1, 12);

% Replace NDM and ****** with a sentinel that sscanf can read
cleaned = strrep(line, 'NDM', ' NaN');
cleaned = strrep(cleaned, '******', ' NaN');

% Use regexp to extract all numbers/NaN tokens
tokens = regexp(cleaned, ...
    '(-?\d+\.?\d*(?:[Ee][+-]?\d+)?|NaN)', ...
    'match');

n = min(numel(tokens), 12);
for i = 1:n
    row(i) = str2double(tokens{i});
end

if n < 1
    row = [];  % nothing parsed
end
end


% =========================================================================
function entry = makeTableEntry(title, mach, re, sref, rowBuf, colNames)
entry.caseTitle = title;
entry.Mach      = mach;
entry.Reynolds  = re;
entry.Sref      = sref;
entry.data      = array2table(rowBuf, 'VariableNames', colNames);
end