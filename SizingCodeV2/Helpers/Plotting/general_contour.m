function general_contour(xname, yname, zname, title_name, X, Y, z_long, limits)

    if nargin < 8
        limits = [min(z_long) max(z_long)];
    end

    Z = reshape(z_long', size(X));
    
    % Spline interpolate to 4x resolution
    [X_fine, Y_fine, Z_fine] = upsample_grid(X, Y, Z, 4);

    figure("Name", title_name);
    contourf(X_fine, Y_fine, Z_fine, 20, 'LineColor', 'none');
    cb = colorbar;
    ylabel(cb, zname);

    colormap(jet);
    xlabel(xname);
    ylabel(yname);
    title(title_name);
    clim(limits);
end

function [X_fine, Y_fine, Z_fine] = upsample_grid(X, Y, Z, factor)
    x_vec = X(1, :);
    y_vec = Y(:, 1);
    x_fine = linspace(x_vec(1), x_vec(end), length(x_vec) * factor);
    y_fine = linspace(y_vec(1), y_vec(end), length(y_vec) * factor);
    [X_fine, Y_fine] = meshgrid(x_fine, y_fine);
    Z_fine = interp2(X, Y, Z, X_fine, Y_fine, 'spline');
end