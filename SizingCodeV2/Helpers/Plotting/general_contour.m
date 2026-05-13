function general_contour(xname, yname, zname, title_name, X, Y, z_long, filter_vec, do_0_line, limits)

    % When values in filter_grid are above 0, Z is set to NaN

    Z = reshape(z_long', size(X));

    if nargin < 8
        filter_grid = - ones(size(Z));
    else
        filter_grid = reshape(filter_vec', size(X));
    end
    
    % Check if we have enough valid data to interpolate
    valid_points = sum(~isnan(Z(:)));
    if valid_points < 4
        warning('Insufficient valid data points (%d) for contour plot: %s', valid_points, title_name);
        return;
    end
    
    [X_fine, Y_fine, Z_fine] = upsample_grid(X, Y, Z, filter_grid, 4);
    
    if nargin < 10 || isempty(limits)
        % Calculate limits ignoring NaN values
        valid_data = Z_fine(~isnan(Z_fine));
        if ~isempty(valid_data)
            limits = [min(valid_data) max(valid_data)];
        else
            limits = [0 1];  % Default if all NaN
        end
    end
    if nargin < 9
        do_0_line = false;
    end
    
    figure("Name", title_name);
    surf(X_fine, Y_fine, Z_fine, 'EdgeColor', 'none', HandleVisibility='off');
    view(2);  % flatten to top-down 2D view
    % shading interp; % can comment this out to not shade
    hold on;
    
    if do_0_line && min(Z_fine(:)) < 0 && max(Z_fine(:)) > 0
        contour(X_fine, Y_fine, Z_fine, [0 0], 'k', 'LineWidth', 2, HandleVisibility='off');
    end
    
    axis tight
    cb = colorbar;
    ylabel(cb, zname);
    colormap(jet);
    xlabel(xname);
    ylabel(yname);
    title(title_name);
    clim(limits);
    zlim(limits);
    addSiddsShit(limits(2));
    hold off
end

function [X_fine, Y_fine, Z_fine, C_fine] = upsample_grid(X, Y, Z, filter_grid, factor)
    x_vec = X(1, :);
    y_vec = Y(:, 1);
    x_fine = linspace(x_vec(1), x_vec(end), length(x_vec) * factor);
    y_fine = linspace(y_vec(1), y_vec(end), length(y_vec) * factor);
    [X_fine, Y_fine] = meshgrid(x_fine, y_fine);
    
    % Check if there are enough valid points for interpolation
    valid_mask = ~isnan(Z);
    if sum(valid_mask(:)) < 4
        error("Not enough valid points")
    end
    
    % Try spline first, fall back to linear if it fails
    Z_fine = interp2(X, Y, Z, X_fine, Y_fine, 'spline');
    C_fine = interp2(X, Y, filter_grid, X_fine, Y_fine, 'spline');

    Z_fine(C_fine > 0) = NaN; % where the filter constraint is violated. Set points to NaN 
end