clear; clc; close all;
addAllPath

matlabSetup
simple_model % does not need to be run everytime - just regenerates lookups/analyisis functions being used
build_default_settings(); % rebuilds the setting file to a defined default 
build_f18_template(); % creates a sample JSON file called f18_superhornet
build_atmosphere_lookup(-5000, ft2m(100000), 500); % Refresh atmosphere lookup

clear; % since the main file should not inherit anything from these calls