%% Preliminary Packing Code 
% Ver. 2.0, 3/18/26
% AOE 4106 Air Vehicle Design / Team 10 - AIAA Strike Fighter / Kevin Xu

% Notes: 
% 1. All length dimensions normalized WRT fuselage length
% 2. Requires 'WeightsCGTable.xlsx' Excel table

clc; clear; close all; format compact

%% Import Parameters from Excel

datamat = readtable('WeightsCGTable.xlsx', 'VariableNamingRule','preserve'); 
datamat = datamat(:, 1:16);

[component_count, cols] = size(datamat); 

% Eliminate empty rows from table (loop backwards to avoid index shifting)
for index1 = component_count:-1:1
    if strcmp(datamat{index1, 1}, '') || ismissing(datamat{index1, 1}) || ismissing(datamat{index1, 3}) || datamat{index1, 4} == 0
        datamat(index1, :) = [];
    end
end

[component_count, cols] = size(datamat); 

%% Initialize 3D-Surface, Make "Crayon Fuselage"
cone_length = 0.25; %n.d. fuselage lengths
cone_fineness = 0.25; %n.d.
cyl_length = 1 - cone_length; %n.d. fuselage lengths

x = linspace(0, cone_length, 50);
theta = linspace(0, 2*pi, 50);
[X, T] = meshgrid(x, theta);

R = cone_fineness * X;                  % cone radius profile
Y = R .* cos(T);
Z = R .* sin(T);

% Cylinder parameters
r_base = max(max(R));        % radius matches cone base
x_cyl = linspace(max(x), max(x) + cyl_length, 50);  % starts where cone ends

[X_cyl, T_cyl] = meshgrid(x_cyl, theta);
Y_cyl = r_base .* cos(T_cyl);
Z_cyl = r_base .* sin(T_cyl);

% Shared surface properties
surf_props = {'FaceColor', [0.2, 0.4, 1.0], ...
              'FaceAlpha', 0.1, ...
              'EdgeColor', [0, 0, 0.8], ...
              'EdgeAlpha', 0.2};

figure(1)
set(gcf, 'Renderer', 'opengl');
hold on;
surf(X,     Y,     Z,     surf_props{:});
surf(X_cyl, Y_cyl, Z_cyl, surf_props{:});
view(-45, 35.264);
axis equal; grid on
set(gca, 'ZDir', 'reverse'); set(gca, 'YDir', 'reverse');
xlabel('X'); ylabel('Y'); zlabel('Z');
xl = xlim; yl = ylim; zl = zlim;
line([xl(1) xl(2)], [0 0],      [0 0],      'Color', 'k', 'LineWidth', 1.5);
line([0 0],         [yl(1) yl(2)], [0 0],   'Color', 'k', 'LineWidth', 1.5);
line([0 0],         [0 0],      [zl(1) zl(2)], 'Color', 'k', 'LineWidth', 1.5);
box off

%% Add Components
% Color of categories, RGB
categories = {
    'Engines',                           [0, 191, 255];    % deep sky blue
    'Fuel System',                        [255, 165, 0];    % orange
    'Fuel Tanks',                         [255, 255, 0];    % yellow
    'Hydraulic Systems',                  [255, 200, 0];    % amber/gold
    'Electrical Power Systems',           [160, 32, 240];   % purple
    'Avionics',                           [0, 128, 255];    % medium blue
    'Radar, Sensors, Targeting Systems',  [255, 0, 255];    % magenta
    'Environmental Control, Pilot Systems',[0, 180, 0];     % green
    'Landing Gear',                       [0, 0, 0];        % black
    'Armaments',                          [255, 0, 0];      % red
    'Structure',                          [180, 180, 180];  % light grey
};

% Make boxes based on nondim coordinates

for index = 1:component_count
    % Extract component parameters from the datamat table
    componentCat = datamat{index, 1}; % Get the component category
    componentName = datamat{index, 2}; % Get the component name
    dimensions = datamat{index, 11:13};   % Get the dimensions (dx, dy, dz)
    centergravloc = datamat{index,14:16};

    % Get the color
    color = categories{strcmp(categories(:, 1), componentCat), 2} / 255; % Get the color for the component
    
    % Set temporary Surface Props 
    tempsurf_props = {'FaceColor', color, ...
              'FaceAlpha', 1};

    % Call the plotBox function to draw the component
    plotBox(centergravloc(1), centergravloc(2), centergravloc(3), dimensions(1), dimensions(2), dimensions(3), tempsurf_props, componentName);    
end


%% Finalize Plot
% Calculate Total Center of Gravity
sum_mass = sum(table2array(datamat(:, 3))); 
weighted_mass = table2array(datamat(:, 3))' * table2array(datamat(:, 14:16)); 
cg_tot = weighted_mass / sum_mass;
disp("The total system mass is " + sum_mass + " pounds.")
disp("The Center of Gravity is X: " + cg_tot(1) + " Y: " + cg_tot(2) + " Z: " + cg_tot(3) + " fuselage lengths relative to the nose.")

str = sprintf("Total mass: %.2f lbs\nCG — X: %.3f  Y: %.3f  Z: %.3f fuselage lengths from nose", ...
               sum_mass, cg_tot(1), cg_tot(2), cg_tot(3));

annotation('textbox', [0.02, 0.02, 0.5, 0.08], ...
    'String', str, ...
    'FitBoxToText', 'on', ...
    'BackgroundColor', 'white', ...
    'EdgeColor', 'black', ...
    'FontSize', 10);

hold off

%% Ensure that code is constantly running 

last_modified = dir('WeightsCGTable.xlsx').datenum;

while true
    pause(1);
    current_modified = dir('WeightsCGTable.xlsx').datenum;
    
    if current_modified ~= last_modified
        last_modified = current_modified;
        close all;
        run('PrelimPackingCode.m');
        return; % new run takes over, this one exits
    end
    
    figure(1);  % bring figure to foreground every second
end
%% Plotbox function
function plotBox(x0, y0, z0, dx, dy, dz, surf_props, label)
% x0,y0,z0 = CENTRE of box, dx,dy,dz = dimensions

% Compute corners from centre
x1 = x0 - dx/2;  x2 = x0 + dx/2;
y1 = y0 - dy/2;  y2 = y0 + dy/2;
z1 = z0 - dz/2;  z2 = z0 + dz/2;

% Define the 6 faces
% Bottom (Z = z1)
[X,Y] = meshgrid([x1 x2],[y1 y2]);
surf(X, Y, z1*ones(2,2), surf_props{:}); hold on
% Top (Z = z2)
surf(X, Y, z2*ones(2,2), surf_props{:});
% Front (Y = y1)
[X,Z] = meshgrid([x1 x2],[z1 z2]);
surf(X, y1*ones(2,2), Z, surf_props{:});
% Back (Y = y2)
surf(X, y2*ones(2,2), Z, surf_props{:});
% Left (X = x1)
[Y,Z] = meshgrid([y1 y2],[z1 z2]);
surf(x1*ones(2,2), Y, Z, surf_props{:});
% Right (X = x2)
surf(x2*ones(2,2), Y, Z, surf_props{:});

% Find closest corner to camera
corners = [x1 y1 z1;
           x1 y1 z2;
           x1 y2 z1;
           x1 y2 z2;
           x2 y1 z1;
           x2 y1 z2;
           x2 y2 z1;
           x2 y2 z2];

cam = campos;  % current camera position
dists = sqrt(sum((corners - cam).^2, 2));
[~, idx] = min(dists);
cx = corners(idx, 1);
cy = corners(idx, 2);
cz = corners(idx, 3);

% Label at closest corner
text(cx, cy, cz, label, ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment',   'middle', ...
    'FontSize', 8, ...
    'FontWeight', 'bold', ...
    'Color', 'k', ...
    'BackgroundColor', 'white', ...
    'EdgeColor',       'black', ...
    'Margin',          2);
end