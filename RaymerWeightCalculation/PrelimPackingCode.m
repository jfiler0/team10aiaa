%% Preliminary Packing Code 
% Ver. 4.1, 4.7.26
% AOE 4106 Air Vehicle Design / Team 10 - AIAA Strike Fighter / Kevin Xu

% Notes: 
% 1. All length dimensions normalized WRT fuselage length
% 2. Requires 'WeightsCGTable_Actual.xlsx' Excel table
% 3. Elements in the Excel Table can be ignored by seting the category...
%       (Col. 1) to blank

clc; clear; close all; format compact

%% Import Parameters from Excel

datamat = readtable('WeightsCGTable_Actual.xlsx', 'VariableNamingRule','preserve'); 
datamat = datamat(:, 1:16);

[component_count, ~] = size(datamat); 

% Eliminate empty rows from table (loop backwards to avoid index shifting)
for index1 = component_count:-1:1
    if strcmp(datamat{index1, 1}, '') || ismissing(datamat{index1, 1}) || ismissing(datamat{index1, 3}) || datamat{index1, 4} == 0
        datamat(index1, :) = [];
    end
end

[component_count, cols] = size(datamat); 

%% Initialize 3D-Surface, make aircraft
TR = stlread('TestAssm_Clean_Rough.STL');
pts = double(TR.Points);

% 1) Find the nose: the vertex with the minimum X coordinate
[~, nose_idx] = min(pts(:,1));
nose = pts(nose_idx, :);
% fprintf('Nose point: X=%.2f, Y=%.2f, Z=%.2f (mm)\n', nose(1), nose(2), nose(3));

% 2) Shift all points so nose is exactly at origin
pts(:,1) = pts(:,1) - nose(1);
pts(:,2) = pts(:,2) - nose(2);
pts(:,3) = pts(:,3) - nose(3);

% 3) Convert mm to in
pts = pts * 0.00328084 * 12;

% 4) Bake in axis convention: X-aft, Y-port(+), Z-down(+)
temp = pts(:, 2);
pts(:,2) = pts(:,3);   
pts(:,3) = -temp;   

% Surface properties
surf_props = {'FaceColor', [0.2, 0.4, 1.0], ...
    'FaceAlpha', 0.1, ...
    'EdgeColor', [0, 0, 0.8], ...
    'EdgeAlpha', 0.05};

% Plot
figure(1);
set(gcf, 'Renderer', 'opengl');
hold on;
trisurf(TR.ConnectivityList, pts(:,1),  pts(:, 2), pts(:,3),  surf_props{:});

ax = gca;
set(ax, 'ZDir', 'reverse');
set(ax, 'YDir', 'reverse')
view(-45, 90);

axis equal; grid on; box off;
xlabel('x, inch (+ aft)'); ylabel('y, inch (+ left)'); zlabel('z, inch (+ down)');

% Extremities directly from pts (no extra negations needed)
x_min = min(pts(:,1)); x_max = max(pts(:,1));
y_min = min(pts(:,2)); y_max = max(pts(:,2));
z_min = min(pts(:,3)); z_max = max(pts(:,3));

xlim([x_min-24 x_max+24]);
ylim([y_min-24 y_max+24]);
zlim([z_min-24 z_max+24]);

%% Add Components
% Color of categories, RGB
categories = {
    'Engines',                                [0, 191, 255];    % deep sky blue
    'Fuel System',                            [0, 150, 255];    % medium blue
    'Fuel Tanks',                             [255, 255, 0];    % yellow
    'Pneumatic Systems',                      [255, 100, 0];    % orange-red
    'Hydraulic Systems',                      [255, 200, 0];    % amber/gold
    'Electrical Power Systems',               [160, 32, 240];   % purple
    'Cooling Systems',                        [180, 100, 220];  % light purple
    'Avionics',                               [0, 0, 0];        % black
    'Radar, Sensors, Targeting Systems',      [255, 0, 255];    % magenta
    'Environmental Control, Pilot Systems',   [0, 180, 0];      % green
    'Landing Gear',                           [50, 50, 50];     % dark grey
    'Armaments',                              [255, 0, 0];      % red
    'Structure',                              [180, 180, 180];  % light grey
};

% Make boxes based on nondim coordinates

for index = 1:component_count
    % Extract component parameters from the datamat table
    % componentCat = datamat{index, 1}; % Get the component category
    componentCat = char(datamat{index, 1});
    componentName = datamat{index, 2}; % Get the component name
    dimensions = datamat{index, 5:7};   % Get the dimensions (dx, dy, dz)
    centergravloc = datamat{index,8:10};

    % Get the color
    % color = categories{strcmp(categories(:, 1), componentCat), 2} / 255; % Get the color for the component
    rowIdx = find(strcmp(categories(:, 1), componentCat));
    color = categories{rowIdx, 2} / 255;

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

% Calculate area-weighted distributions for Ixx, Iyy, Izz; 
Ixx = table2array(datamat(:, 3))'*(((table2array(datamat(:, 9))-cg_tot(2)).^2 + (table2array(datamat(:, 10))-cg_tot(3)).^2) + 1/12 * (table2array(datamat(:, 6)).^2 + table2array(datamat(:, 7)).^2)); 
Iyy = table2array(datamat(:, 3))'*(((table2array(datamat(:, 8))-cg_tot(1)).^2 + (table2array(datamat(:, 10))-cg_tot(3)).^2) + 1/12 * (table2array(datamat(:, 5)).^2 + table2array(datamat(:, 7)).^2)); 
Izz = table2array(datamat(:, 3))'*(((table2array(datamat(:, 8))-cg_tot(1)).^2 + (table2array(datamat(:, 9))-cg_tot(2)).^2) + 1/12 * (table2array(datamat(:, 5)).^2 + table2array(datamat(:, 6)).^2)); 

disp("The total system mass is " + sum_mass + " pounds.")
disp("The Center of Gravity is X: " + cg_tot(1) + " Y: " + cg_tot(2) + " Z: " + cg_tot(3) + " fuselage lengths relative to the nose.")

str = sprintf("Total mass: %.2f lbs\nCG — X: %.3f  Y: %.3f  Z: %.3f fuselage lengths from nose\nMoments of Inertia — Ixx: %.4g lb-in^2  Iyy: %.4g lb-in^2  Izz: %.4g lb-in^2", ...
    sum_mass, cg_tot(1), cg_tot(2), cg_tot(3), Ixx, Iyy, Izz);

annotation('textbox', [0.02, 0.02, 0.5, 0.08], ...
    'String', str, ...
    'FitBoxToText', 'on', ...
    'BackgroundColor', 'white', ...
    'EdgeColor', 'black', ...
    'FontSize', 10);

hold off

%% Ensure that code is constantly running (JEFFREY: If it integrates with your code)

% last_modified = dir('WeightsCGTable_Actual.xlsx').datenum;
% 
% figure(1); % create once
% 
% while true
%     pause(1);
%     current_modified = dir('WeightsCGTable_Actual.xlsx').datenum;
% 
%     if current_modified ~= last_modified
%         last_modified = current_modified;
% 
%         run('PrelimPackingCode.m'); % update plot only
%     end
% 
%     if ishandle(1)
%         figure(1); % keep it in foreground
%     end
% end
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
    'FontSize', 4, ...
    'FontWeight', 'bold', ...
    'Color', 'k', ...
    'BackgroundColor', 'white', ...
    'EdgeColor',       'black', ...
    'Margin',          2);
end