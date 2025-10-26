clear; clc;
% Compute lifting-line solution
b = 8;
c_r = 1;
c_t = 2;
alpha = deg2rad(5);
alpha0 = deg2rad(-2);
N = 80;

results = llt(b, c_r, c_t, alpha, alpha0, N);

% Spanwise positions normalized by semi-span
y_norm = results.y / (b/2);

%% Plotting
figure;

% Top subplot: spanwise Cl distribution
subplot(2,1,1);
plot(y_norm, results.cl, '-o','LineWidth',1.5);
ylim([0 max(results.cl)])
xlabel('y/(b/2)');
ylabel('c_l');
title('Spanwise Lift Coefficient Distribution');
grid on;

% Bottom subplot: rotated wing planform
subplot(2,1,2);
hold on;

% Wing coordinates (span along x, chord along y)
x_span = results.y;        % x-axis: spanwise
y_top  = results.c/2;      % top chord edge
y_bot  = -results.c/2;     % bottom chord edge

% Right half-wing
fill([x_span; flipud(x_span)], [y_bot; flipud(y_top)], [0.7 0.9 1], 'EdgeColor','b');

% Left half-wing mirrored
fill(-[x_span; flipud(x_span)], -[y_bot; flipud(y_top)], [0.7 0.9 1], 'EdgeColor','b');

axis equal;
xlabel('y (spanwise)');
ylabel('x (chordwise)');
title('Wing Planform');
grid on;

% Display aerodynamic properties on the figure
AR_text  = sprintf('AR = %.3f', results.AR);
S_text   = sprintf('S = %.3f', results.S);
e_text   = sprintf('e = %.3f', results.e);
CDi_text = sprintf('C_D_i = %.3f', results.CDi);

text(0.2*b, max(results.c)*0.6, {AR_text, S_text, e_text, CDi_text}, ...
    'FontSize',10, 'BackgroundColor','w', 'EdgeColor','k');
