function process_airfoil(name, assign_to_main, flap_xpos, flap_def)
    % name -> main indicator of which file to look at
    % assign_to_main -> set as true if you do want this to overwrite the main .dat file (otherwise it will go to temp.dat)
    % flap_xpos -> from 0-1
    % flap_def -> in degrees with positive being down

    %% Check for the file
    projDir = fileparts(mfilename('fullpath')); % function folder
    dat_file = fullfile(projDir, name + ".dat");
    if ~isfile(dat_file)
        error('File "%s" not found in current folder.', dat_file);
    end

    %% Assign the needed variables
    coords = readmatrix(dat_file);
    if size(coords,2) ~= 2
        error('Airfoil file must have 2 numeric columns [x y].');
    end

    % --- Remove consecutive duplicate rows (tolerance for floating errors)
    tol = 1e-12;
    if size(coords,1) >= 2
        diffs = abs(diff(coords,1,1));
        dup_idx = all(diffs <= tol, 2);   % logical vector for rows that duplicate previous
        coords(dup_idx,:) = [];
    end
    if(sum(dup_idx) > 0)
        warning("Identified duplicate entries and removed them.")
    end

    xvec = coords(:, 1);
    yvec = coords(:, 2);
    len = length(xvec);

    %% Make sure things are oriented correctly (TE -> over the top -> LE -> down the bottom -> TE)
    [~, min_pos_x] = min(xvec);
    [~, max_pos_x] = max(xvec);
    if(min_pos_x==1 || min_pos_x==len)
        warning("Airfoil is incorrectly ordered: LE->TE->LE. Switching to TE->LE->TE")
        xvec = [ xvec(max_pos_x:(end-1)); xvec(1:max_pos_x) ];
        yvec = [ yvec(max_pos_x:(end-1)); yvec(1:max_pos_x) ];
    end

    [~, min_pos_y] = min(yvec);
    [~, max_pos_y] = max(yvec);
    if(min_pos_y < max_pos_y)
        warning("Airfoil is incorrectly oriented clockwise. Reversing to be counterclockwise")
        xvec = flip(xvec);
        yvec = flip(yvec);
    end

    scaling = 1/max(xvec);
    if(scaling ~= 1)
        warning("Airfoil does not have a chord length of 1. Scaling.")
        xvec = scaling*xvec;
        yvec = scaling*yvec;
    end

    coords(:, 1) = xvec;
    coords(:, 2) = yvec;
    
    %% Do any flap modifications
    if(flap_xpos < 1)
        [~, le_idx] = min(xvec);
        yt_flapx = interp1(xvec(1:le_idx), yvec(1:le_idx), flap_xpos); % Y position of the top part of the foil at the flap hinge
        yb_flapx = interp1(xvec(le_idx:len), yvec(le_idx:len), flap_xpos); % Y position of the bot part of the foil at the flap hinge
        
        yc_flapx = 0.5*(yt_flapx+yb_flapx); % Y position of the camber line of the foil at the flap hinge
        H = [flap_xpos yc_flapx];

        inflap = find(xvec > flap_xpos);

        theta = deg2rad(flap_def); %MATLAB and radians
        R = [cos(theta), -sin(theta); sin(theta),  cos(theta)];
        
        for (j=1:length(inflap))
            i = inflap(j); % Just since we already ran find

            coords(i, :) = (coords(i, :) - H )*R + H;

            if(coords(i, 1) < flap_xpos) % Ended up rotating past the hinge point
                coords(i, :) = [NaN NaN];
                %Can remove all NaN values later
            end
        end
        coords = rmmissing(coords); % Remove any of the marked NaN entries
    end

    %% Smooth out flap corner

    %% Do spline fit and cosine distribution

    %% Plot
    % plot(coords(:,1), coords(:,2))

    %% Save to .dat
    if(assign_to_main==false)
        dat_file = fullfile(projDir, "temp.dat");
    end
    % --- Save using fixed-point format (no scientific notation)
    fid = fopen(dat_file, 'w');
    if fid < 0
        error('Could not open "%s" for writing.', dat_file);
    end
    for i = 1:size(coords,1)
        fprintf(fid, '%.8f %.8f\n', coords(i,1), coords(i,2));
    end
    fclose(fid);
end