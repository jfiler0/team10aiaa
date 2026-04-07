function displayAircraftGeom(geom)

figure; hold on; axis equal; grid on;

drawSurface(geom.outline.coords.fuseage,   [0.6 0.6 0.6], FaceAlpha=0.5, Label='Fuselage');
drawSurface(geom.outline.coords.wing,      [0.2 0.4 0.8], FaceAlpha=0.4, Label='Wing',Mirror=true);
drawSurface(geom.outline.coords.elevator,  [0.8 0.3 0.2], FaceAlpha=0.4, Label='Elevator',Mirror=true);
drawSurface(geom.outline.coords.rudder,     [0.3 0.7 0.3], FaceAlpha=0.4, Label='Rudder',Mirror=true);

xlabel('x (m)'); ylabel('y (m)');
title('Aircraft Layout');

end

function h = drawSurface(points, color, options)
    arguments
        points      (:,:) double
        color       (1,:)
        options.FaceAlpha   (1,1) double = 0.3
        options.EdgeColor               = []
        options.EdgeAlpha   (1,1) double = 1.0
        options.LineWidth   (1,1) double = 1.5
        options.Label       (1,:) char  = ''
        options.FontSize    (1,1) double = 10
        options.Parent      = []
        options.Mirror      (1,1) logical = false
    end

    if isempty(options.Parent)
        ax = gca;
    else
        ax = options.Parent;
    end

    if isempty(options.EdgeColor)
        edgeColor = color;
    else
        edgeColor = options.EdgeColor;
    end

    x = points(:, 1);
    y = points(:, 2);
    if size(points, 2) >= 3
        z = points(:, 3);
    else
        z = zeros(size(x));
    end

    h.patch = patch(ax, x, y, z, color, ...
        'FaceAlpha', options.FaceAlpha, ...
        'EdgeColor', edgeColor, ...
        'EdgeAlpha', options.EdgeAlpha, ...
        'LineWidth', options.LineWidth);

    h.label = [];
    if ~isempty(options.Label)
        h.label = text(ax, mean(x), mean(y), mean(z), options.Label, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment',   'middle', ...
            'FontSize', options.FontSize, ...
            'Color', edgeColor);
    end

    % --- mirrored patch (y flipped, no label)
    h.mirror = [];
    if options.Mirror
        h.mirror = patch(ax, x, -y, z, color, ...
            'FaceAlpha', options.FaceAlpha, ...
            'EdgeColor', edgeColor, ...
            'EdgeAlpha', options.EdgeAlpha, ...
            'LineWidth', options.LineWidth);
    end
end