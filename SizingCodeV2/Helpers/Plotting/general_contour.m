function general_contour(xname, yname, zname, title_name, X, Y, z_long, do_0_line, limits)
    if nargin < 9
        limits = [min(z_long) max(z_long)];
    end
    if nargin < 8
        do_0_line = false;
    end

    Z = reshape(z_long', size(X));
    [X_fine, Y_fine, Z_fine] = upsample_grid(X, Y, Z, 4);

    figure("Name", title_name);
    surf(X_fine, Y_fine, Z_fine, 'EdgeColor', 'none');
    view(2);  % flatten to top-down 2D view
    shading interp;
    hold on;

    if do_0_line && min(Z_fine(:)) < 0 && max(Z_fine(:)) > 0
        contour(X_fine, Y_fine, Z_fine, [0 0], 'k', 'LineWidth', 2);
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
end

function [X_fine, Y_fine, Z_fine] = upsample_grid(X, Y, Z, factor)
    x_vec = X(1, :);
    y_vec = Y(:, 1);
    x_fine = linspace(x_vec(1), x_vec(end), length(x_vec) * factor);
    y_fine = linspace(y_vec(1), y_vec(end), length(y_vec) * factor);
    [X_fine, Y_fine] = meshgrid(x_fine, y_fine);
    Z_fine = interp2(X, Y, Z, X_fine, Y_fine, 'spline');
end