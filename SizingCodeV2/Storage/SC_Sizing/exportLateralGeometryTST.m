function exportLateralGeometryTST(filename, headerText, sections)
% exportLateralGeometryTST
%
% Writes an X-Men Systems lateral geometry data file (.tst)
% using precomputed geometry values.
%
% INPUTS:
%   filename   - string, e.g. 'lateral_geometry.tst'
%   headerText - string, first line of the file
%   sections   - struct array with fields:
%       .panel1_pts   (4x3 double)  % [x y z]
%       .panel1_flags (1x2 double)
%       .panel2_pts   (4x3 double)
%       .panel2_flags (1x2 double)
%
% NOTES:
%   - This function does NO geometry calculations.
%   - Formatting matches Chapter 5 / screenshot layout.
%   - You control all numbers upstream.

    fid = fopen(filename, 'w');
    if fid == -1
        error('Could not open file for writing.');
    end

    cleanupObj = onCleanup(@() fclose(fid));

    %% Header
    fprintf(fid, '%s\n', headerText);

    %% Number of geometry sections
    nSections = numel(sections);
    fprintf(fid, '%d.\n', nSections);

    %% Loop through sections
    for i = 1:nSections

        % ---- Panel 1 points ----
        writePoints(fid, sections(i).panel1_pts);

        % ---- Panel 1 flags ----
        writeFlags(fid, sections(i).panel1_flags);

        % ---- Panel 2 points ----
        writePoints(fid, sections(i).panel2_pts);

        % ---- Panel 2 flags ----
        writeFlags(fid, sections(i).panel2_flags);

    end

end

%% --------------------------------------------------------
function writePoints(fid, pts)
% pts must be 4x3: [x y z]

    if ~isequal(size(pts), [4 3])
        error('Point array must be 4x3.');
    end

    for k = 1:4
        fprintf(fid, '%8.3f, %8.3f, %8.3f\n', ...
            pts(k,1), pts(k,2), pts(k,3));
    end
end

%% --------------------------------------------------------
function writeFlags(fid, flags)
% flags must be 1x2

    if numel(flags) ~= 2
        error('Flag array must have 2 elements.');
    end

    fprintf(fid, '%6.2f, %6.2f\n', flags(1), flags(2));
end
