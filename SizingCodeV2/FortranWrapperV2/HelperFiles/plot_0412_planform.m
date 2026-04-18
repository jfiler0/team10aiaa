function plot_0412_planform(varargin)
%PLOT_0412_PLANFORM  Top-down planform view for the 0412_Optimization aircraft.
%
%  Add ONE of these calls to the relevant drag script immediately after the
%  analysis runs:
%
%  In CD0 analysis script (basic wetted-area overview):
%    plot_0412_planform()
%
%  In idrag_example_0412.m (adds cosine VLM strip lines):
%    plot_0412_planform('strips', nv_lerx, nv_main, nv_elev)
%    where nv_lerx, nv_main, nv_elev are the column-vector strip counts
%    already computed by stripCounts() in that script.
%
%  In awave_example_0412.m (adds fuselage station markers + area subplot):
%    plot_0412_planform('awave', cfg)
%    where cfg is the struct passed to write_awave_input.
%
%  Requires R2014b+ for 4-element [R G B alpha] Color vectors.

%% ---- Parse inputs ------------------------------------------------------
showStrips = false;
showAwave  = false;
nv_lerx = []; nv_wing = []; nv_elev = [];
xfus_cell = {}; fusard_cell = {};

k = 1;
while k <= numel(varargin)
    if ischar(varargin{k})
        switch lower(varargin{k})
            case 'strips'
                showStrips = true;
                nv_lerx = varargin{k+1}(:);
                nv_wing = varargin{k+2}(:);
                nv_elev = varargin{k+3}(:);
                k = k + 4;
            case 'awave'
                showAwave = true;
                cfgIn     = varargin{k+1};
                xfus_cell   = cfgIn.XFUS;
                fusard_cell = cfgIn.FUSARD;
                k = k + 3;
            otherwise
                k = k + 1;
        end
    else
        k = k + 1;
    end
end

%% ---- Geometry (metres) -------------------------------------------------
% Section tables: [le_x, le_y, chord]
lerx_secs = [ 3.0452,  0.9772, 10.370;
              7.3152,  2.1720,  6.100];

main_secs = [ 7.3152,  2.1720,  6.100;
              7.6886,  2.7016,  5.640;
              9.1821,  4.8198,  3.800;
              9.5555,  5.3494,  3.340;
             10.6756,  6.9380,  1.960;
             11.0490,  7.4676,  1.500];

elev_secs = [12.6492,  1.0000,  2.5908;
             12.7646,  1.2088,  2.4754;
             13.8037,  3.0884,  1.4363];

% Fuselage planform outline (top-down, both sides)
fus_x = [0,      3.045,  13.415, 12.649, 15.24, ...
         15.24,  12.649, 13.415,  3.045,  0];
fus_y = [0,      0.977,   0.977,  0.906,  0.906, ...
        -0.906, -0.906,  -0.977, -0.977,  0];

%% ---- Colour scheme (RGB) -----------------------------------------------
% Each entry: {fill, edge}
CL.lerx = {[0.980 0.931 0.853], [0.729 0.459 0.090]};
CL.wing = {[0.902 0.945 0.984], [0.094 0.373 0.647]};
CL.tail = {[0.882 0.961 0.933], [0.059 0.431 0.337]};
CL.fuse = {[0.929 0.929 0.922], [0.373 0.373 0.357]};

%% ---- Build panel corner arrays -----------------------------------------
lerx_p = secs2panels(lerx_secs);
main_p = secs2panels(main_secs);
elev_p = secs2panels(elev_secs);

%% ---- Figure and axes ---------------------------------------------------
fig = figure('Name', '0412 Planform', 'NumberTitle', 'off');

if showAwave
    subplot(1, 2, 1);
    fig.Position = [100 100 1100 500];
else
    fig.Position = [100 100 680 620];
end

axP = gca;
hold(axP, 'on');
axis(axP, 'equal');
grid(axP, 'on');
axP.GridAlpha   = 0.12;
axP.GridColor   = [0.5 0.5 0.5];
axP.TickDir     = 'out';
axP.Box         = 'on';

%% ---- Fuselage ----------------------------------------------------------
patch(axP, fus_x, fus_y, CL.fuse{1}, ...
    'EdgeColor', CL.fuse{2}, 'LineWidth', 1.5, 'HandleVisibility', 'off');

% Centreline
plot(axP, [0 16], [0 0], '--', 'Color', [0.7 0.7 0.7 0.6], ...
    'LineWidth', 0.5, 'HandleVisibility', 'off');

%% ---- LERX/wing junction spanwise marker --------------------------------
% Dashed line at y = ±2.172 m marking where LERX hands off to main wing
plot(axP, [7.3152, 13.4152], [ 2.172,  2.172], ':', ...
    'Color', [CL.lerx{2}, 0.5], 'LineWidth', 0.75, 'HandleVisibility', 'off');
plot(axP, [7.3152, 13.4152], [-2.172, -2.172], ':', ...
    'Color', [CL.lerx{2}, 0.5], 'LineWidth', 0.75, 'HandleVisibility', 'off');

%% ---- Surface panels ----------------------------------------------------
draw_surface(axP, lerx_p, CL.lerx);
draw_surface(axP, main_p, CL.wing);
draw_surface(axP, elev_p, CL.tail);

%% ---- VLM strip lines (idrag mode) -------------------------------------
if showStrips
    draw_strips(axP, lerx_p, nv_lerx, CL.lerx{2});
    draw_strips(axP, main_p, nv_wing, CL.wing{2});
    draw_strips(axP, elev_p, nv_elev, CL.tail{2});
end

%% ---- Awave fuselage station ticks (awave mode) ------------------------
if showAwave
    for seg = 1:numel(xfus_cell)
        for xi = xfus_cell{seg}(:)'
            plot(axP, [xi xi], [-0.45 0.45], '-', ...
                'Color', [0.45 0.45 0.45 0.55], 'LineWidth', 0.75, ...
                'HandleVisibility', 'off');
        end
    end
end

%% ---- Panel index labels ------------------------------------------------
label_panels(axP, lerx_p, 'L', CL.lerx{2});
label_panels(axP, main_p, 'W', CL.wing{2});
label_panels(axP, elev_p, 'E', CL.tail{2});

%% ---- Sweep angle annotations ------------------------------------------
% Compute LE sweep angles from section tables
sw_lerx = atan2d(lerx_secs(2,1)-lerx_secs(1,1), lerx_secs(2,2)-lerx_secs(1,2));
sw_main = atan2d(main_secs(end,1)-main_secs(1,1), main_secs(end,2)-main_secs(1,2));

text(axP, 5.0, 2.5, sprintf('\\Lambda_{LE} = %.1f°', sw_lerx), ...
    'FontSize', 7.5, 'Color', CL.lerx{2}, 'HorizontalAlignment', 'center');
text(axP, 9.8, 5.5, sprintf('\\Lambda_{LE} = %.1f°', sw_main), ...
    'FontSize', 7.5, 'Color', CL.wing{2}, 'HorizontalAlignment', 'center');

%% ---- Scale bar ---------------------------------------------------------
sb_y = -8.0;
plot(axP, [0 5],     [sb_y sb_y],   '-', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.5, 'HandleVisibility','off');
plot(axP, [0 0],     [sb_y-0.1, sb_y+0.1], '-', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.5, 'HandleVisibility','off');
plot(axP, [5 5],     [sb_y-0.1, sb_y+0.1], '-', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.5, 'HandleVisibility','off');
text(axP, 2.5, sb_y-0.35, '5 m', 'FontSize', 8, 'HorizontalAlignment', 'center', 'Color', [0.3 0.3 0.3]);

%% ---- Port/stbd labels --------------------------------------------------
text(axP, 0.3,  7.8, 'port',  'FontSize', 8, 'Color', [0.5 0.5 0.5]);
text(axP, 0.3, -7.8, 'stbd',  'FontSize', 8, 'Color', [0.5 0.5 0.5]);

% Nose arrow
annotation_nose(axP);

%% ---- Legend ------------------------------------------------------------
h_f = patch(axP, NaN, NaN, CL.fuse{1}, 'EdgeColor', CL.fuse{2}, 'LineWidth', 1.5);
h_l = patch(axP, NaN, NaN, CL.lerx{1}, 'EdgeColor', CL.lerx{2}, 'LineWidth', 0.75);
h_w = patch(axP, NaN, NaN, CL.wing{1}, 'EdgeColor', CL.wing{2}, 'LineWidth', 0.75);
h_t = patch(axP, NaN, NaN, CL.tail{1}, 'EdgeColor', CL.tail{2}, 'LineWidth', 0.75);

leg_str = {'fuselage', 'LERX (L1)', 'main wing (W1–W5)', 'H-tail (E1–E2)'};
if showStrips
    leg_str{end+1} = sprintf('VLM strips (%d/%d/%d)', sum(nv_lerx), sum(nv_wing), sum(nv_elev));
end
if showAwave
    leg_str{end+1} = 'fuselage x-stations';
end
legend(axP, [h_f h_l h_w h_t], leg_str(1:4), ...
    'Location', 'northwest', 'FontSize', 8);

%% ---- Axes limits and labels --------------------------------------------
xlim(axP, [-0.5, 16.5]);
ylim(axP, [-8.8,  8.8]);
xlabel(axP, 'x (m)  —  longitudinal');
ylabel(axP, 'y (m)  —  spanwise');

if showStrips
    title(axP, sprintf('0412\\_Opt  —  VLM panels  (%d total strips)', ...
        sum(nv_lerx)+sum(nv_wing)+sum(nv_elev)));
elseif showAwave
    title(axP, '0412\\_Opt  —  AWAVE geometry  (ticks = x-stations)');
else
    title(axP, '0412\\_Opt  —  planform');
end

hold(axP, 'off');

%% ---- Awave area distribution subplot ----------------------------------
if showAwave
    subplot(1, 2, 2);
    axA = gca;
    hold(axA, 'on');

    % Concatenate segments and remove duplicates at boundaries
    x_all = []; a_all = [];
    for seg = 1:numel(xfus_cell)
        x_all = [x_all, xfus_cell{seg}(:)'];   %#ok<AGROW>
        a_all = [a_all, fusard_cell{seg}(:)'];  %#ok<AGROW>
    end
    [x_all, ia] = unique(x_all, 'stable');
    a_all = a_all(ia);

    % Filled area curve
    fill(axA, [x_all, fliplr(x_all)], [a_all, zeros(1,numel(a_all))], ...
        CL.fuse{1}, 'EdgeColor', 'none', 'FaceAlpha', 0.55);
    plot(axA, x_all, a_all, '-', 'Color', CL.fuse{2}, 'LineWidth', 1.5);

    % Station dots
    scatter(axA, x_all, a_all, 18, CL.fuse{2}, 'filled');

    % Reference lines: LERX LE, wing LE, root TE
    refs = {3.0452, 'LERX LE', CL.lerx{2};
            7.3152, 'wing LE', CL.wing{2};
           13.415,  'root TE', CL.wing{2}};
    for r = 1:size(refs,1)
        xr = refs{r,1};
        xline(axA, xr, '--', 'Color', refs{r,3}, 'LineWidth', 0.75, ...
            'Label', refs{r,2}, 'LabelHorizontalAlignment', 'left', ...
            'LabelVerticalAlignment', 'bottom', 'FontSize', 7);
    end

    grid(axA, 'on');
    axA.GridAlpha = 0.12;
    axA.TickDir   = 'out';
    xlim(axA, [0, 16]);
    ylim(axA, [0, max(a_all) * 1.2]);
    xlabel(axA, 'x (m)');
    ylabel(axA, 'cross-sectional area (m^2)');
    title(axA, 'fuselage area distribution');

    hold(axA, 'off');
end

end  % main function


%% =========================================================================
%%  Local functions
%% =========================================================================

function panels = secs2panels(secs)
%SECS2PANELS  Convert Nx3 section table [le_x, le_y, chord] to panel cells.
%  Output panels{k} = 4x2 array, rows = [root-LE; tip-LE; tip-TE; root-TE].
n = size(secs,1) - 1;
panels = cell(n,1);
for k = 1:n
    rx = secs(k,1);   ry = secs(k,2);   rc = secs(k,3);
    tx = secs(k+1,1); ty = secs(k+1,2); tc = secs(k+1,3);
    panels{k} = [rx,    ry;
                 tx,    ty;
                 tx+tc, ty;
                 rx+rc, ry];
end
end


function draw_surface(ax, panels, CL)
%DRAW_SURFACE  Draw port (y>0) and starboard (y<0) polygons for a surface.
for k = 1:numel(panels)
    p = panels{k};
    patch(ax, p(:,1),  p(:,2), CL{1}, 'EdgeColor', CL{2}, ...
        'LineWidth', 0.75, 'HandleVisibility', 'off');
    patch(ax, p(:,1), -p(:,2), CL{1}, 'EdgeColor', CL{2}, ...
        'LineWidth', 0.75, 'HandleVisibility', 'off');
end
end


function draw_strips(ax, panels, nv, edge_c)
%DRAW_STRIPS  Cosine-compressed VLM strip lines (spacing_flag=3).
%  Uses 4-element [R G B alpha] Color — requires R2014b+.
c4 = [edge_c, 0.40];
for k = 1:numel(panels)
    p = panels{k};
    n = nv(k);
    t = 0.5 * (1 - cos(pi * (1:n)' / (n+1)));   % cosine positions in [0,1]
    for j = 1:n
        tj = t(j);
        le_x = p(1,1) + (p(2,1)-p(1,1)) * tj;
        le_y = p(1,2) + (p(2,2)-p(1,2)) * tj;
        te_x = p(4,1) + (p(3,1)-p(4,1)) * tj;
        te_y = p(4,2) + (p(3,2)-p(4,2)) * tj;
        plot(ax, [le_x te_x], [ le_y  te_y], '-', 'Color', c4, 'LineWidth', 0.5, 'HandleVisibility','off');
        plot(ax, [le_x te_x], [-le_y -te_y], '-', 'Color', c4, 'LineWidth', 0.5, 'HandleVisibility','off');
    end
end
end


function label_panels(ax, panels, prefix, color)
%LABEL_PANELS  Small panel index label at each panel centroid (both sides).
for k = 1:numel(panels)
    p  = panels{k};
    cx = mean(p(:,1));
    cy = mean(p(:,2));
    s  = sprintf('%s%d', prefix, k);
    text(ax, cx,  cy, s, 'FontSize', 7, 'FontWeight', 'bold', 'Color', color, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'HandleVisibility', 'off');
    text(ax, cx, -cy, s, 'FontSize', 7, 'FontWeight', 'bold', 'Color', color, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'HandleVisibility', 'off');
end
end


function annotation_nose(ax)
%ANNOTATION_NOSE  Small filled triangle at the nose pointing forward (left).
xv = [0,  0.4,  0.4];
yv = [0,  0.25, -0.25];
patch(ax, xv, yv, [0.4 0.4 0.4], 'EdgeColor', 'none', 'HandleVisibility','off');
text(ax, 0.55, 0, 'fwd', 'FontSize', 8, 'Color', [0.5 0.5 0.5], ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
end