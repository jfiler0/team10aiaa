clear; clc; close all; % clean up
addAllPath % get all files and folders in the working diretory aded to path

matlabSetup % settings for nice graphs
build_default_settings(); % rebuilds the setting file to a defined default 
% simple_model % does not need to be run everytime - just regenerates lookups/analyisis functions being used
build_f18_template(); % creates a sample JSON file called f18_superhornet
build_sample_missions();
build_atmosphere_lookup(-5000, ft2m(100000), 500); % Refresh atmosphere lookup

build_standard_stores;

clear; % since the main file should not inherit anything from these calls

disp("Good to go!")