function exportFig(name)
    fig = gcf;
    if ~isvalid(fig)
        error('No valid figure found.');
    end

    filepath = fullfile("C:\Users\VonBe\Downloads", name);
    if ~endsWith(filepath, '.pdf')
        filepath = filepath + ".pdf";
    end

    axList = findobj(fig, 'Type', 'axes');
    nAx    = numel(axList);

    % --- Store originals ---
    orig_color    = fig.Color;
    orig_units    = fig.PaperUnits;
    orig_size     = fig.PaperSize;
    orig_pos      = fig.PaperPosition;
    orig_renderer = fig.Renderer;

    orig_ax = struct();
    for k = 1:nAx
        ax                     = axList(k);
        orig_ax(k).Color       = ax.Color;
        orig_ax(k).XColor      = ax.XColor;
        orig_ax(k).YColor      = ax.YColor;
        orig_ax(k).ZColor      = ax.ZColor;
        orig_ax(k).TitleColor  = ax.Title.Color;
        orig_ax(k).XLabelColor = ax.XLabel.Color;
        orig_ax(k).YLabelColor = ax.YLabel.Color;
    end

    try
        fig.Color    = 'none';
        fig.Renderer = 'painters';

        color = [0, 0, 0];
        color2 = [1, 1, 1];

        for k = 1:nAx
            ax                = axList(k);
            ax.Color          = color2;
            ax.XColor         = color;
            ax.YColor         = color;
            ax.ZColor         = color;
            ax.Title.Color    = color;
            ax.XLabel.Color   = color;
            ax.YLabel.Color   = color;
            ax.GridColor      = color;
            ax.MinorGridColor = color;
        end

        fig.PaperUnits    = 'inches';
        fig.PaperSize     = [4.25, 3.5];
        fig.PaperPosition = [0, 0, 4.25, 3.5];

        print(fig, filepath, '-dpdf', '-painters');

        % Convert PDF to SVG via Inkscape
        svg_path = strrep(filepath, '.pdf', '.svg');
        inkscape  = '"C:\Program Files\Inkscape\bin\inkscape.exe"';
        cmd       = sprintf('%s --export-type=svg --export-filename="%s" "%s"', ...
                            inkscape, svg_path, filepath);
        [status, msg] = system(cmd);
        if status == 0
            fprintf('Saved: %s\n', svg_path);
        else
            fprintf('PDF saved but Inkscape conversion failed: %s\n', msg);
            fprintf('You can convert manually by opening the PDF in Inkscape.\n');
        end

        fprintf('Saved: %s\n', filepath);

    catch e
        fprintf('Export failed: %s\n', e.message);
    end

    % --- Restore ---
    fig.Color         = orig_color;
    fig.PaperUnits    = orig_units;
    fig.PaperSize     = orig_size;
    fig.PaperPosition = orig_pos;
    fig.Renderer      = orig_renderer;

    for k = 1:nAx
        ax                = axList(k);
        ax.Color          = orig_ax(k).Color;
        ax.XColor         = orig_ax(k).XColor;
        ax.YColor         = orig_ax(k).YColor;
        ax.ZColor         = orig_ax(k).ZColor;
        ax.Title.Color    = orig_ax(k).TitleColor;
        ax.XLabel.Color   = orig_ax(k).XLabelColor;
        ax.YLabel.Color   = orig_ax(k).YLabelColor;
    end
end