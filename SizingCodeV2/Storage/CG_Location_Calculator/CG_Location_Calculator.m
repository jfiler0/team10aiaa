%% Center of Gravity Location Calculator

% Notes:
% The goal of this calculator is to determine the aircraft's current center
% of gravity, not an estimate. This make it a lot cleaner as I don't need
% to come up with weight estimations for the more general aircraft
% components.

clear; clc; close all;

%% Inputs
% component_table; This isn't an input, but it is called to summon the component property table.
% TOGW; This is needed to know the "all-else-empty" weight of the aircraft.
% L; length of the aircraft relative to the nose of the aircraft to the
% back most point.

TOGW = 38000;
L = 60; %ft


% ** The "all-else-empty" weight of the aircraft is a variable to consider
% the parts of the aircraft not included in the weight the components such
% as struts etc.

%% Outputs
% cg; final center of gravity of the aircraft

%% Main Code
%% Step 1: Load in table of component details

% Function callcomponenttable.m is used to summon the excel table and
% import it into matlab. This part of the code is its own code to allow the
% table to be directly editted as needed. (i.e. utilizing a differnet
% weight estiamte and inserting it into the table)

component_table = callcomponenttable; % call the function to load the table

%% Step 2: For each component, calculate their center of gravity relative to the object itself.

numComponents = height(component_table); %determine the number of components in table

% For now we are assuming the center of gravity of each component is their
% centroid. Later, the larger components which are significant will be
% better defined.

cgComponents = zeros(numComponents, 1); % Initialize array to store center of gravity for each component

for i = 1:numComponents
    cgComponents(i) = component_table.ComponentLocationRelativeToNoseTip(i) + component_table.ComponentCentroidLocation(i); % Assuming 'CG' is a column in the component_table
end

% We now have the list of component cgs. Now we determine sum of weights,
% sum of products of each component cg and weight, and determine the cg of
% the aircraft.

%% CG Calculation #1
% This calculator assumes that there is no "all-else-empty" component to
% the aircraft. This means that the entirety of TOGW accounted for in the
% component property table.

% weights = component_table.ComponentWeight; % Extract weights of each component
% totalWeight = sum(weights); % Calculate total weight of all components
% weightedCG = sum(cgComponents .* weights) / totalWeight; % Calculate the overall center of gravity


%% CG Calculation #2
% This calculator consider an "all-else-empty" component of the aircraft.

weights = component_table.ComponentWeight; % Extract weights of each component

% determine the all-else-empty component
weightAllElseEmpty = TOGW - sum(weights);
% assume all else empty's cg is located at the center of the aircraft.
cgAllElseEmpty = 0.5*L;

% Calculate total weight including the all-else-empty component
totalWeight = sum(weights) + weightAllElseEmpty;

weightedCG = (sum(cgComponents .* weights) + weightAllElseEmpty * cgAllElseEmpty) / totalWeight; % Calculate the overall center of gravity including all-else-empty component

%% Output the calculated center of gravity
cg = weightedCG; % Assign the calculated CG to the output variable

if isnan(cg)
    disp('Error, must complete table')
else
    disp(['The center of gravity of the aircraft is located at: ', num2str(cg), ' ft from the nose.']);
end



