clear; clc; close all;

% ===============================
% INPUTS
% ================================
rho = 0.0023769;
S   = 555;
W   = 50000;

CL_max_pos =  1.7;
CL_max_neg = -0.90;

n_max =  8;
n_min = -3;

V_C_knots = 600;
V_D_knots = 750;

N = 20000;

% ===============================
% VELOCITY ARRAY
% ================================
V_knots = linspace(0, V_D_knots, N);
V_fts   = V_knots * 1.68781;

% ===============================
% STALL CURVES
% ================================
n_stall_pos = (0.5 .* rho .* V_fts.^2 .* CL_max_pos       .* S) ./ W;
n_stall_neg = (0.5 .* rho .* V_fts.^2 .* abs(CL_max_neg)  .* S) ./ W * -1;

% ===============================
% KEY SPEEDS
% ================================
Vs_pos_fts   = sqrt((2*W) / (rho*S*CL_max_pos));
Vs_pos_knots = Vs_pos_fts / 1.68781;

Vs_neg_fts   = sqrt((2*W) / (rho*S*abs(CL_max_neg)));
Vs_neg_knots = Vs_neg_fts / 1.68781;

Va_pos_fts   = Vs_pos_fts * sqrt(n_max);
Va_pos_knots = Va_pos_fts / 1.68781;

Va_neg_fts   = Vs_neg_fts * sqrt(abs(n_min));
Va_neg_knots = Va_neg_fts / 1.68781;

% ===============================
% ENVELOPE
% ================================
n_upper = min(n_stall_pos, n_max);
n_lower = max(n_stall_neg, n_min);

% ===============================
% COLORS
% ================================
c_red    = [0.85 0.07 0.07];
c_yellow = [1.00 0.85 0.00];
c_green  = [0.13 0.60 0.18];

% ===============================
% STALL ARC INDEX RANGES
% ================================
idx_pos = V_knots >= 0 & V_knots <= Va_pos_knots;
idx_neg = V_knots >= 0 & V_knots <= Va_neg_knots;
V_arc_p = V_knots(idx_pos);  n_arc_p = n_stall_pos(idx_pos);
V_arc_n = V_knots(idx_neg);  n_arc_n = n_stall_neg(idx_neg);

% ===============================
% FIGURE
% ================================
% figure('Color','w', 'Position',[80 80 1100 680]);
% ax = axes('Position',[0.10 0.10 0.85 0.83]);
% hold on;
% ax.Color = 'w';
figure;
hold on;

% ===============================
% FILLED REGIONS — back to front
% ================================

n_plot_max =  12;
n_plot_min =  -5;

% --- RED: full background band above n_max and below n_min ---
% Upper red rectangle: Va_pos -> V_D, n_max -> ceiling
patch([Va_pos_knots, V_D_knots, V_D_knots, Va_pos_knots], ...
      [n_max, n_max, n_plot_max, n_plot_max], ...
      c_red, 'EdgeColor','none');

% Lower red rectangle: Va_neg -> V_D, n_min -> floor
patch([Va_neg_knots, V_D_knots, V_D_knots, Va_neg_knots], ...
      [n_min, n_min, n_plot_min, n_plot_min], ...
      c_red, 'EdgeColor','none');

% --- GREEN: normal flight envelope (Vs_pos -> V_C) ---
idx_VS  = find(V_knots >= Vs_pos_knots, 1);
idx_VC  = find(V_knots >= V_C_knots,    1);
V_grn   = V_knots(idx_VS:idx_VC);
nu_grn  = n_upper(idx_VS:idx_VC);
nl_grn  = n_lower(idx_VS:idx_VC);
patch([V_grn, fliplr(V_grn)], [nu_grn, fliplr(nl_grn)], ...
      c_green, 'EdgeColor','none');

% --- YELLOW: caution region (V_C -> V_D) ---
idx_VD  = find(V_knots >= V_D_knots, 1);
V_yel   = V_knots(idx_VC:idx_VD);
nu_yel  = n_upper(idx_VC:idx_VD);
nl_yel  = n_lower(idx_VC:idx_VD);
patch([V_yel, fliplr(V_yel)], [nu_yel, fliplr(nl_yel)], ...
      c_yellow, 'EdgeColor','none');

% ===============================
% ENVELOPE OUTLINES
% ================================
lw_env = 2.8;

% Positive stall arc
plot(V_arc_p, n_arc_p, 'k-', 'LineWidth', lw_env);

% Negative stall arc
plot(V_arc_n, n_arc_n, 'k-', 'LineWidth', lw_env);

% Top horizontal: Va_pos -> V_D at n_max
plot([Va_pos_knots, V_D_knots], [n_max, n_max], 'k-', 'LineWidth', lw_env);

% Bottom horizontal: Va_neg -> V_D at n_min
plot([Va_neg_knots, V_D_knots], [n_min, n_min], 'k-', 'LineWidth', lw_env);

% Right boundary: V_D, n_min to n_max
plot([V_D_knots, V_D_knots], [n_min, n_max], 'k-', 'LineWidth', lw_env);

% Stall curve extensions to zero (left tip)
% plot([0, Vs_pos_knots], [0, 1],  'k-', 'LineWidth', lw_env);
% plot([0, Vs_neg_knots], [0, -1], 'k-', 'LineWidth', lw_env);

% ===============================
% STRUCTURAL LIMIT DASHED LINES
% ================================
plot([0, V_D_knots+20], [n_max+2, n_max+2], 'k--', 'LineWidth', 1.8);
plot([0, V_D_knots+20], [n_min-1, n_min-1], 'k--', 'LineWidth', 1.8);

% ===============================
% SPEED VERTICAL LINES
% ================================
% V_C dashed
plot([V_C_knots, V_C_knots], [n_min, n_max], 'k--', 'LineWidth', 2.0);

% V_D solid (right boundary already drawn; add label line below envelope)
plot([V_D_knots, V_D_knots], [n_min, n_max], 'k-', 'LineWidth', lw_env);

% n=1 dotted reference
plot([0, V_D_knots+20], [1, 1], ':k', 'LineWidth', 1.2);

% n=0 solid reference
plot([0, V_D_knots+20], [0, 0], '-k', 'LineWidth', 1.0);

% ===============================
% KEY POINT MARKERS
% ================================
ms = 10;
plot(Vs_pos_knots, 1,     'ko', 'MarkerFaceColor','k', 'MarkerSize',ms);
plot(Va_pos_knots, n_max, 'ks', 'MarkerFaceColor','k', 'MarkerSize',ms);
plot(Va_neg_knots, n_min, 'ks', 'MarkerFaceColor','k', 'MarkerSize',ms);
plot(V_D_knots,    n_max, 'ks', 'MarkerFaceColor','k', 'MarkerSize',ms);
plot(V_D_knots,    n_min, 'ks', 'MarkerFaceColor','k', 'MarkerSize',ms);
plot(V_C_knots,    n_max, 'ks', 'MarkerFaceColor','k', 'MarkerSize',ms);
plot(V_C_knots,    n_min, 'ks', 'MarkerFaceColor','k', 'MarkerSize',ms);

% ===============================
% SPEED LABELS (rotated on vertical lines)
% ================================
text(V_C_knots+2, 2 + (n_min+n_max)/2, sprintf('$V_C = %.0f$ kt', V_C_knots), ...
     'Rotation',90, 'FontSize',11, 'FontWeight','bold', ...
     'HorizontalAlignment','center', 'VerticalAlignment','bottom', 'Interpreter','latex');

text(V_D_knots+2, 2 + (n_min+n_max)/2, sprintf('$V_D = %.0f$ kt', V_D_knots), ...
     'Rotation',90, 'FontSize',11, 'FontWeight','bold', ...
     'HorizontalAlignment','center', 'VerticalAlignment','bottom', 'Interpreter','latex');

% ===============================
% POINT LABELS
% ================================
text(Vs_pos_knots+65, 1.5, sprintf('$V_{s+} = %.0f$ kt', Vs_pos_knots), ...
     'FontSize',10, 'FontWeight','bold', 'Interpreter','latex');

text(Va_pos_knots+40, n_max-0.15, sprintf('$V_A = %.0f$ kt', Va_pos_knots), ...
     'FontSize',10, 'FontWeight','bold', 'VerticalAlignment','top', 'Interpreter','latex');

text(Va_neg_knots+20, n_min+0.15, sprintf('$V_{A-} = %.0f$ kt', Va_neg_knots), ...
     'FontSize',10, 'FontWeight','bold', 'VerticalAlignment','bottom', 'Interpreter','latex');

% % ===============================
% % REGION LABELS
% % ================================
% % Normal flight envelope
% mid_green_V = (Vs_pos_knots + V_C_knots) / 2 + 30;
% text(mid_green_V, 2.0, 'Normal flight envelope', ...
%      'FontSize',14, 'FontWeight','bold', 'Color','w', ...
%      'HorizontalAlignment','center', 'Interpreter','latex');
% 
% % Level unaccelerated flight arrow label
% text(mid_green_V - 30, 0.55, 'Level', ...
%      'FontSize',10, 'Color','w', 'HorizontalAlignment','center', 'Interpreter','latex');
% text(mid_green_V - 30, 0.15, 'Unaccelerated Flight', ...
%      'FontSize',10, 'Color','w', 'HorizontalAlignment','center', 'Interpreter','latex');
% 
% % Caution region
% mid_yellow_V = (V_C_knots + V_D_knots) / 2;
% text(mid_yellow_V, 1.5, 'Caution Region', ...
%      'FontSize',13, 'FontWeight','bold', 'Color','k', ...
%      'HorizontalAlignment','center', 'Interpreter','latex');
% 
% % Structural damage labels (inside red, just outside envelope)
% text(mid_yellow_V, n_max + 1.2, 'Structural damage likely', ...
%      'FontSize',10, 'FontWeight','bold', 'Color','w', 'HorizontalAlignment','center', 'Interpreter','latex');
% text(mid_yellow_V, n_max + 2.2, 'Structural failure likely', ...
%      'FontSize',10, 'FontWeight','bold', 'Color','w', 'HorizontalAlignment','center', 'Interpreter','latex');
% text(mid_yellow_V, n_min - 0.5, 'Structural damage likely', ...
%      'FontSize',10, 'FontWeight','bold', 'Color','w', 'HorizontalAlignment','center', 'Interpreter','latex');
% text(mid_yellow_V, n_min - 1.3, 'Structural failure likely', ...
%      'FontSize',10, 'FontWeight','bold', 'Color','w', 'HorizontalAlignment','center', 'Interpreter','latex');

% ===============================
% AXIS FORMATTING
% ================================
% grid off; box on;
% ax.GridColor  = [0.15 0.15 0.15];
% ax.GridAlpha  = 0.25;
% ax.LineWidth  = 1.5;
% ax.FontName   = 'Arial';
% ax.Layer      = 'top';

xlim([0, V_D_knots + 50]);
ylim([n_plot_min, n_plot_max]);
% xticks(0:100:V_D_knots+50);
% yticks(-4:2:12);

xlabel('EAS [knots]');
ylabel('Load Factor [G]');
title('V-n Diagram');

% ===============================
% CONSOLE OUTPUT
% ================================
fprintf('Vs+  = %.2f knots\n', Vs_pos_knots);
fprintf('Vs-  = %.2f knots\n', Vs_neg_knots);
fprintf('Va+  = %.2f knots\n', Va_pos_knots);
fprintf('Va-  = %.2f knots\n', Va_neg_knots);
fprintf('Vc   = %.2f knots\n', V_C_knots);
fprintf('Vd   = %.2f knots\n', V_D_knots);