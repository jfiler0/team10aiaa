function plot_0412_planform(varargin)
%PLOT_0412_PLANFORM  Top-down planform view for the 0412_Optimization aircraft.
%
%  plot_0412_planform()
%  plot_0412_planform('strips', nv_lerx, nv_main, nv_elev)
%  plot_0412_planform('awave', cfg)
%  plot_0412_planform('datcom', xb, rb, x_cg_full, x_cg_empty, ...
%                     x_ac_wb, Xnp_ft, SM_mach, machPts, ...
%                     VLM_LIMIT, cbar_ft, validMask, isVLMpts)
%
%  Requires R2014b+ for 4-element [R G B alpha] Color vectors.
%  Compatible with R2025b (no special text interpreter characters).

%% ---- Parse inputs ------------------------------------------------------
showStrips  = false;
showAwave   = false;
showDatcom  = false;
nv_lerx = []; nv_wing = []; nv_elev = [];
xfus_cell = {}; fusard_cell = {};
xb_ft = []; rb_ft = [];
x_cg_full_ft = NaN; x_cg_empty_ft = NaN; x_ac_wb_ft = NaN;
Xnp_ft = []; SM_mach = []; machPts = [];
VLM_LIMIT = 0.6; cbar_ft = NaN;
validMask = []; isVLMpts = [];

k = 1;
while k <= numel(varargin)
    if ischar(varargin{k}) || isstring(varargin{k})
        switch lower(char(varargin{k}))
            case 'strips'
                showStrips = true;
                nv_lerx = varargin{k+1}(:);
                nv_wing = varargin{k+2}(:);
                nv_elev = varargin{k+3}(:);
                k = k + 4;
            case 'awave'
                showAwave   = true;
                cfgIn       = varargin{k+1};
                xfus_cell   = cfgIn.XFUS;
                fusard_cell = cfgIn.FUSARD;
                k = k + 2;
            case 'datcom'
                showDatcom    = true;
                xb_ft         = varargin{k+1}(:)';
                rb_ft         = varargin{k+2}(:)';
                x_cg_full_ft  = varargin{k+3};
                x_cg_empty_ft = varargin{k+4};
                x_ac_wb_ft    = varargin{k+5};
                Xnp_ft        = varargin{k+6}(:)';
                SM_mach       = varargin{k+7}(:)';
                machPts       = varargin{k+8}(:)';
                VLM_LIMIT     = varargin{k+9};
                cbar_ft       = varargin{k+10};
                validMask     = logical(varargin{k+11}(:)');
                isVLMpts      = logical(varargin{k+12}(:)');
                k = k + 13;
            otherwise
                k = k + 1;
        end
    else
        k = k + 1;
    end
end

ft2m = 0.3048;

%% ---- Geometry (metres) -------------------------------------------------
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

fus_x = [0,      3.045,  13.415, 12.649, 15.24, ...
         15.24,  12.649, 13.415,  3.045,  0];
fus_y = [0,      0.977,   0.977,  0.906,  0.906, ...
        -0.906, -0.906,  -0.977, -0.977,  0];

%% ---- Colour scheme -----------------------------------------------------
CL.lerx = {[0.980 0.931 0.853], [0.729 0.459 0.090]};
CL.wing = {[0.902 0.945 0.984], [0.094 0.373 0.647]};
CL.tail = {[0.882 0.961 0.933], [0.059 0.431 0.337]};
CL.fuse = {[0.929 0.929 0.922], [0.373 0.373 0.357]};
CL.cg   = [0.20 0.20 0.20];
CL.ac   = [0.70 0.15 0.15];
CL.np   = [0.15 0.40 0.75];

%% ---- Build panels ------------------------------------------------------
lerx_p = secs2panels(lerx_secs);
main_p = secs2panels(main_secs);
elev_p = secs2panels(elev_secs);

%% ---- Figure layout -----------------------------------------------------
fig = figure('Name', '0412 Planform', 'NumberTitle', 'off', ...
             'WindowStyle', 'normal');

if showAwave || showDatcom
    fig.Position = [100 100 1150 520];
    subplot(1, 2, 1);
else
    fig.Position = [100 100 700 640];
end

axP = gca;
hold(axP, 'on');
axis(axP, 'equal');
grid(axP, 'on');
axP.GridAlpha = 0.12;
axP.GridColor = [0.5 0.5 0.5];
axP.TickDir   = 'out';
axP.Box       = 'on';

%% ---- Fuselage ----------------------------------------------------------
patch(axP, fus_x, fus_y, CL.fuse{1}, 'EdgeColor', CL.fuse{2}, ...
    'LineWidth', 1.5, 'HandleVisibility', 'off');
plot(axP, [0 16], [0 0], '--', 'Color', [0.7 0.7 0.7 0.6], ...
    'LineWidth', 0.5, 'HandleVisibility', 'off');

%% ---- LERX/wing junction marker -----------------------------------------
plot(axP, [7.3152 13.415], [ 2.172  2.172], ':', ...
    'Color', [CL.lerx{2} 0.5], 'LineWidth', 0.75, 'HandleVisibility', 'off');
plot(axP, [7.3152 13.415], [-2.172 -2.172], ':', ...
    'Color', [CL.lerx{2} 0.5], 'LineWidth', 0.75, 'HandleVisibility', 'off');

%% ---- Surface panels ----------------------------------------------------
draw_surface(axP, lerx_p, CL.lerx);
draw_surface(axP, main_p, CL.wing);
draw_surface(axP, elev_p, CL.tail);

%% ---- VLM strip lines ---------------------------------------------------
if showStrips
    draw_strips(axP, lerx_p, nv_lerx, CL.lerx{2});
    draw_strips(axP, main_p, nv_wing, CL.wing{2});
    draw_strips(axP, elev_p, nv_elev, CL.tail{2});
end

%% ---- AWAVE fuselage station ticks -------------------------------------
if showAwave
    for seg = 1:numel(xfus_cell)
        for xi = xfus_cell{seg}(:)'
            plot(axP, [xi xi], [-0.45 0.45], '-', ...
                'Color', [0.45 0.45 0.45 0.55], 'LineWidth', 0.75, ...
                'HandleVisibility', 'off');
        end
    end
end

%% ---- DATCOM overlays --------------------------------------------------
if showDatcom
    xb_m = xb_ft * ft2m;
    rb_m = rb_ft * ft2m;
    for j = 1:numel(xb_m)
        hw = min(rb_m(j), 0.9);
        plot(axP, [xb_m(j) xb_m(j)], [-hw hw], '-', ...
            'Color', [0.45 0.45 0.45 0.55], 'LineWidth', 0.75, ...
            'HandleVisibility', 'off');
    end
    x_ac_m = x_ac_wb_ft * ft2m;
    plot(axP, [x_ac_m x_ac_m], [-3.5 3.5], '-', ...
        'Color', CL.ac, 'LineWidth', 2.0, ...
        'DisplayName', sprintf('Wing-body AC  (%.2f m)', x_ac_m));
    cg_lo_m = min(x_cg_full_ft, x_cg_empty_ft) * ft2m;
    cg_hi_m = max(x_cg_full_ft, x_cg_empty_ft) * ft2m;
    fill(axP, [cg_lo_m cg_hi_m cg_hi_m cg_lo_m], [-3.5 -3.5 3.5 3.5], ...
        CL.cg, 'FaceAlpha', 0.10, 'EdgeColor', CL.cg, 'LineStyle', '--', ...
        'LineWidth', 1.2, ...
        'DisplayName', sprintf('CG travel  (%.2f - %.2f m)', cg_lo_m, cg_hi_m));
    valid_np = Xnp_ft(validMask) * ft2m;
    if ~isempty(valid_np)
        np_lo = min(valid_np);  np_hi = max(valid_np);
        fill(axP, [np_lo np_hi np_hi np_lo], [-1.8 -1.8 1.8 1.8], ...
            CL.np, 'FaceAlpha', 0.12, 'EdgeColor', CL.np, 'LineStyle', ':', ...
            'LineWidth', 1.0, ...
            'DisplayName', sprintf('NP range  (%.2f - %.2f m)', np_lo, np_hi));
    end
    text(axP, x_ac_m, -4.3, 'AC', 'FontSize', 8, 'FontWeight', 'bold', ...
        'Color', CL.ac, 'HorizontalAlignment', 'center', ...
        'Interpreter', 'none');
    text(axP, (cg_lo_m+cg_hi_m)/2, -4.3, 'CG range', 'FontSize', 8, ...
        'Color', CL.cg, 'HorizontalAlignment', 'center', ...
        'Interpreter', 'none');
end

%% ---- Panel index labels ------------------------------------------------
label_panels(axP, lerx_p, 'L', CL.lerx{2});
label_panels(axP, main_p, 'W', CL.wing{2});
label_panels(axP, elev_p, 'E', CL.tail{2});

%% ---- Sweep angle annotations ------------------------------------------
% Use plain ASCII - no LaTeX, no degree symbol, no em dash
sw_lerx = atan2d(lerx_secs(2,1)-lerx_secs(1,1), lerx_secs(2,2)-lerx_secs(1,2));
sw_main = atan2d(main_secs(end,1)-main_secs(1,1), main_secs(end,2)-main_secs(1,2));
text(axP, 5.0, 2.5, sprintf('LE sweep = %.1f deg', sw_lerx), ...
    'FontSize', 7.5, 'Color', CL.lerx{2}, 'HorizontalAlignment', 'center', ...
    'Interpreter', 'none');
text(axP, 9.8, 5.5, sprintf('LE sweep = %.1f deg', sw_main), ...
    'FontSize', 7.5, 'Color', CL.wing{2}, 'HorizontalAlignment', 'center', ...
    'Interpreter', 'none');

%% ---- Scale bar ---------------------------------------------------------
sb_y = -8.0;
plot(axP, [0 5],   [sb_y sb_y],         '-', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.5, 'HandleVisibility','off');
plot(axP, [0 0],   [sb_y-0.1 sb_y+0.1], '-', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.5, 'HandleVisibility','off');
plot(axP, [5 5],   [sb_y-0.1 sb_y+0.1], '-', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.5, 'HandleVisibility','off');
text(axP, 2.5, sb_y-0.35, '5 m', 'FontSize', 8, 'HorizontalAlignment', 'center', ...
    'Color', [0.3 0.3 0.3], 'Interpreter', 'none');

text(axP, 0.3,  7.8, 'port', 'FontSize', 8, 'Color', [0.5 0.5 0.5], 'Interpreter', 'none');
text(axP, 0.3, -7.8, 'stbd', 'FontSize', 8, 'Color', [0.5 0.5 0.5], 'Interpreter', 'none');
annotation_nose(axP);

%% ---- Legend ------------------------------------------------------------
h_f = patch(axP, NaN, NaN, CL.fuse{1}, 'EdgeColor', CL.fuse{2}, 'LineWidth', 1.5);
h_l = patch(axP, NaN, NaN, CL.lerx{1}, 'EdgeColor', CL.lerx{2}, 'LineWidth', 0.75);
h_w = patch(axP, NaN, NaN, CL.wing{1}, 'EdgeColor', CL.wing{2}, 'LineWidth', 0.75);
h_t = patch(axP, NaN, NaN, CL.tail{1}, 'EdgeColor', CL.tail{2}, 'LineWidth', 0.75);
leg_str = {'fuselage', 'LERX (L1)', 'main wing (W1-W5)', 'H-tail (E1-E2)'};
if showStrips
    leg_str{end+1} = sprintf('VLM strips (%d/%d/%d)', sum(nv_lerx), sum(nv_wing), sum(nv_elev));
end
if showAwave
    leg_str{end+1} = 'fuselage x-stations';
end
if showDatcom
    leg_str{end+1} = sprintf('Wing-body AC  (%.2f m)', x_ac_wb_ft*ft2m);
    leg_str{end+1} = 'CG travel';
    leg_str{end+1} = 'NP range';
end
legend(axP, [h_f h_l h_w h_t], leg_str(1:4), ...
    'Location', 'northwest', 'FontSize', 8, 'Interpreter', 'none');

%% ---- Axes limits and labels --------------------------------------------
xlim(axP, [-0.5, 16.5]);
ylim(axP, [-8.8,  8.8]);
xlabel(axP, 'x (m), longitudinal', 'Interpreter', 'none');
ylabel(axP, 'y (m), spanwise',     'Interpreter', 'none');

if showStrips
    title(axP, sprintf('0412 Opt -- VLM panels (%d total strips)', ...
        sum(nv_lerx)+sum(nv_wing)+sum(nv_elev)), 'Interpreter', 'none');
elseif showAwave
    title(axP, '0412 Opt -- AWAVE geometry (ticks = x-stations)', 'Interpreter', 'none');
elseif showDatcom
    title(axP, '0412 Opt -- DATCOM geometry (ticks = body stations)', 'Interpreter', 'none');
else
    title(axP, '0412 Opt -- planform', 'Interpreter', 'none');
end

hold(axP, 'off');

%% ---- AWAVE area distribution subplot ----------------------------------
if showAwave
    subplot(1, 2, 2);
    axA = gca;
    hold(axA, 'on');

    x_all = []; a_all = [];
    for seg = 1:numel(xfus_cell)
        x_all = [x_all, xfus_cell{seg}(:)'];   %#ok<AGROW>
        a_all = [a_all, fusard_cell{seg}(:)'];  %#ok<AGROW>
    end
    [x_all, ~] = unique(x_all, 'stable');
    a_all = a_all(1:numel(x_all));

    fill(axA, [x_all fliplr(x_all)], [a_all zeros(1,numel(a_all))], ...
        CL.fuse{1}, 'EdgeColor', 'none', 'FaceAlpha', 0.55);
    plot(axA, x_all, a_all, '-', 'Color', CL.fuse{2}, 'LineWidth', 1.5);
    scatter(axA, x_all, a_all, 18, CL.fuse{2}, 'filled');

    refs = {3.0452, 'LERX LE', CL.lerx{2};
            7.3152, 'wing LE', CL.wing{2};
           13.415,  'root TE', CL.wing{2}};
    for r = 1:size(refs,1)
        xline(axA, refs{r,1}, '--', 'Color', refs{r,3}, 'LineWidth', 0.75, ...
            'Label', refs{r,2}, 'LabelHorizontalAlignment', 'left', ...
            'LabelVerticalAlignment', 'bottom', 'FontSize', 7, ...
            'Interpreter', 'none');
    end

    grid(axA, 'on'); axA.GridAlpha = 0.12; axA.TickDir = 'out';
    xlim(axA, [0, 16]); ylim(axA, [0, max(a_all)*1.2]);
    xlabel(axA, 'x (m)',                    'Interpreter', 'none');
    ylabel(axA, 'cross-sectional area (m2)', 'Interpreter', 'none');
    title(axA,  'fuselage area distribution','Interpreter', 'none');
    hold(axA, 'off');
end

%% ---- DATCOM NP & SM subplot -------------------------------------------
if showDatcom && ~isempty(machPts)
    subplot(1, 2, 2);
    axD = gca;
    hold(axD, 'on');

    yyaxis(axD, 'left');
    msk = validMask & isVLMpts;
    if any(msk)
        plot(axD, machPts(msk), Xnp_ft(msk)*ft2m, 'b--^', ...
            'LineWidth', 2, 'MarkerSize', 7, 'DisplayName', 'Xnp (VLM)');
    end
    msk = validMask & ~isVLMpts;
    if any(msk)
        plot(axD, machPts(msk), Xnp_ft(msk)*ft2m, 'b-o', ...
            'LineWidth', 2, 'MarkerSize', 7, 'DisplayName', 'Xnp (DATCOM)');
    end
    if ~isnan(x_ac_wb_ft)
        yline(axD, x_ac_wb_ft*ft2m, 'r--', 'LineWidth', 1.5, ...
            'Label', 'Wing-body AC', 'LabelHorizontalAlignment', 'left', ...
            'LabelVerticalAlignment', 'bottom', 'FontSize', 7, ...
            'Interpreter', 'none', 'HandleVisibility', 'off');
    end
    ylabel(axD, 'Neutral point, x from nose (m)', 'Color', 'b', 'Interpreter', 'none');
    axD.YColor = 'b';

    % CG travel band
    if ~isnan(x_cg_full_ft) && ~isnan(x_cg_empty_ft)
        xl = [min(machPts) max(machPts)];
        cg_lo_m = min(x_cg_full_ft, x_cg_empty_ft) * ft2m;
        cg_hi_m = max(x_cg_full_ft, x_cg_empty_ft) * ft2m;
        fill(axD, [xl(1) xl(2) xl(2) xl(1)], ...
                  [cg_lo_m cg_lo_m cg_hi_m cg_hi_m], ...
             CL.cg, 'FaceAlpha', 0.08, 'EdgeColor', 'none', ...
             'HandleVisibility', 'off');
        text(axD, xl(1)+0.02, (cg_lo_m+cg_hi_m)/2, 'CG range', ...
            'FontSize', 7, 'Color', CL.cg, 'VerticalAlignment', 'middle', ...
            'Interpreter', 'none');
    end

    yyaxis(axD, 'right');
    msk = validMask & isVLMpts;
    if any(msk)
        plot(axD, machPts(msk), SM_mach(msk)*100, 'r--^', ...
            'LineWidth', 2, 'MarkerSize', 7, 'DisplayName', 'SM pct (VLM)');
    end
    msk = validMask & ~isVLMpts;
    if any(msk)
        plot(axD, machPts(msk), SM_mach(msk)*100, 'r-o', ...
            'LineWidth', 2, 'MarkerSize', 7, 'DisplayName', 'SM pct (DATCOM)');
    end
    yline(axD, 0, 'k--', 'LineWidth', 1.0, 'HandleVisibility', 'off');
    yline(axD, 5, 'g:',  'LineWidth', 0.8, ...
        'Label', 'SM = 5 pct', 'LabelHorizontalAlignment', 'left', ...
        'FontSize', 7, 'Interpreter', 'none', 'HandleVisibility', 'off');
    ylabel(axD, 'Static margin (pct MAC)', 'Color', 'r', 'Interpreter', 'none');
    axD.YColor = 'r';

    xline(axD, VLM_LIMIT, 'k:', 'LineWidth', 1.2, ...
        'Label', sprintf('VLM|DAT M=%.2f', VLM_LIMIT), ...
        'LabelHorizontalAlignment', 'right', 'FontSize', 7, ...
        'Interpreter', 'none', 'HandleVisibility', 'off');

    grid(axD, 'on'); axD.GridAlpha = 0.12; axD.TickDir = 'out';
    xlabel(axD, 'Mach', 'Interpreter', 'none');
    title(axD,  'Neutral point and static margin vs Mach', 'Interpreter', 'none');
    legend(axD, 'Location', 'best', 'FontSize', 8, 'Interpreter', 'none');
    hold(axD, 'off');
end

%% ---- FIX: flush and raise window so it accepts focus ------------------
drawnow;
figure(fig);

end


%% =========================================================================
%%  Local functions
%% =========================================================================

function panels = secs2panels(secs)
n      = size(secs,1) - 1;
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
for k = 1:numel(panels)
    p = panels{k};
    patch(ax,  p(:,1),  p(:,2), CL{1}, 'EdgeColor', CL{2}, 'LineWidth', 0.75, 'HandleVisibility','off');
    patch(ax,  p(:,1), -p(:,2), CL{1}, 'EdgeColor', CL{2}, 'LineWidth', 0.75, 'HandleVisibility','off');
end
end


function draw_strips(ax, panels, nv, edge_c)
c4 = [edge_c, 0.40];
for k = 1:numel(panels)
    p = panels{k};
    n = nv(k);
    t = 0.5 * (1 - cos(pi * (1:n)' / (n+1)));
    for j = 1:n
        tj  = t(j);
        lex = p(1,1)+(p(2,1)-p(1,1))*tj;  ley = p(1,2)+(p(2,2)-p(1,2))*tj;
        tex = p(4,1)+(p(3,1)-p(4,1))*tj;  tey = p(4,2)+(p(3,2)-p(4,2))*tj;
        plot(ax, [lex tex], [ ley  tey], '-', 'Color', c4, 'LineWidth', 0.5, 'HandleVisibility','off');
        plot(ax, [lex tex], [-ley -tey], '-', 'Color', c4, 'LineWidth', 0.5, 'HandleVisibility','off');
    end
end
end


function label_panels(ax, panels, prefix, color)
for k = 1:numel(panels)
    p  = panels{k};
    cx = mean(p(:,1));
    cy = mean(p(:,2));
    s  = sprintf('%s%d', prefix, k);
    text(ax, cx,  cy, s, 'FontSize', 7, 'FontWeight', 'bold', 'Color', color, ...
        'HorizontalAlignment','center','VerticalAlignment','middle', ...
        'HandleVisibility','off', 'Interpreter','none');
    text(ax, cx, -cy, s, 'FontSize', 7, 'FontWeight', 'bold', 'Color', color, ...
        'HorizontalAlignment','center','VerticalAlignment','middle', ...
        'HandleVisibility','off', 'Interpreter','none');
end
end


function annotation_nose(ax)
patch(ax, [0 0.4 0.4], [0 0.25 -0.25], [0.4 0.4 0.4], ...
    'EdgeColor', 'none', 'HandleVisibility', 'off');
text(ax, 0.55, 0, 'fwd', 'FontSize', 8, 'Color', [0.5 0.5 0.5], ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
    'Interpreter', 'none');
end