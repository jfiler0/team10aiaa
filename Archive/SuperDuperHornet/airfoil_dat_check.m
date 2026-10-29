function airfoil_dat_check(dat_name)
% AIRFOIL_DAT_CHECK Ensure .dat file is ordered TE -> LE -> TE (XFOIL-friendly)
%   airfoil_dat_check("NACA2412")
%
% Loads <dat_name>.dat from the current folder, corrects ordering if needed,
% and re-saves with fixed-point formatting. Prompts only if a change is needed.

    dat_file = dat_name + ".dat";
    if ~isfile(dat_file)
        error('File "%s" not found in current folder.', dat_file);
    end

    % --- Load coordinates (assume two numeric columns)
    coords_raw = readmatrix(dat_file);
    if size(coords_raw,2) ~= 2
        error('Airfoil file must have 2 numeric columns [x y].');
    end

    coords = coords_raw; % working copy

    % --- Remove consecutive duplicate rows (tolerance for floating errors)
    tol = 1e-12;
    if size(coords,1) >= 2
        diffs = abs(diff(coords,1,1));
        dup_idx = all(diffs <= tol, 2);   % logical vector for rows that duplicate previous
        coords(dup_idx,:) = [];
    end

    % Need at least 3 points to proceed
    if size(coords,1) < 3
        error('Not enough points in the .dat after duplicate removal.');
    end

    % --- Identify leading edge (min x) and trailing edge (max x)
    [minX, idx_le] = min(coords(:,1));
    [maxX, idx_te] = max(coords(:,1));
    N = size(coords,1);

    % If idx_le is 1 or N, it's still valid: the split will handle it
    % --- Split into two segments at the LE index:
    seg1 = coords(1:idx_le, :);   % first segment: either TE->LE or LE->TE
    seg2 = coords(idx_le:end, :); % second segment: the complement

    % --- Identify which segment is top vs bottom:
    % Top should have the larger maximum y value
    max1 = max(seg1(:,2));
    max2 = max(seg2(:,2));
    if max1 >= max2
        top = seg1;
        bottom = seg2;
    else
        top = seg2;
        bottom = seg1;
    end

    % --- Force orientations for TE -> LE -> TE:
    % Top must be TE -> LE (x decreasing). If not, flip it.
    if top(1,1) < top(end,1)
        top = flipud(top);
    end
    % Bottom must be LE -> TE (x increasing). If not, flip it.
    if bottom(1,1) > bottom(end,1)
        bottom = flipud(bottom);
    end

    % --- Ensure trailing-edge y = 0 at both TE points:
    % In TE->LE->TE ordering top(1,:) is TE, bottom(end,:) is TE.
    top(1,2) = 0;
    bottom(end,2) = 0;

    % --- Merge into TE -> LE -> TE sequence.
    % top ends at LE, bottom starts at LE. To avoid duplicating LE, skip bottom(1).
    if size(bottom,1) >= 2
        coords_fixed = [top; bottom(2:end,:)];
    else
        % If bottom has only 1 point (degenerate), just concatenate
        coords_fixed = [top; bottom];
    end

    % --- If nothing changed (up to tolerance), report and exit
    if isequal(size(coords), size(coords_fixed)) && all(abs(coords - coords_fixed) < 1e-9, 'all')
        fprintf('Airfoil "%s" already in TE->LE->TE order. No changes made.\n', dat_file);
        return;
    end

    % --- Prompt user to save corrected file
    prompt = sprintf('Airfoil "%s" was corrected to TE->LE->TE ordering. Save changes? Y/N [Y]: ', dat_file);
    s = input(prompt, 's');
    if isempty(s)
        s = 'Y';
    end
    if upper(s) ~= 'Y'
        fprintf('No changes saved.\n');
        return;
    end

    % --- Save using fixed-point format (no scientific notation)
    fid = fopen(dat_file, 'w');
    if fid < 0
        error('Could not open "%s" for writing.', dat_file);
    end
    for i = 1:size(coords_fixed,1)
        fprintf(fid, '%.8f %.8f\n', coords_fixed(i,1), coords_fixed(i,2));
    end
    fclose(fid);

    fprintf('Airfoil "%s" has been rewritten in TE->LE->TE order (fixed-point format).\n', dat_file);
end