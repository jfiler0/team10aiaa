function exportPDF(name)
    fig = gcf;
    if ~isvalid(fig)
        error('No valid figure found.');
    end

    filepath = fullfile("C:\Users\jfile\Downloads", name);
    if ~endsWith(filepath, '.pdf')
        filepath = filepath + ".pdf";
    end

    try
        exportgraphics(gcf, filepath, 'ContentType', 'image'); % 'ContentType', 'vector'
    catch e
        fprintf('Export failed: %s\n', e.message);
    end
end