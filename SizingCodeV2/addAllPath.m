% Ran using the initialization function. Makes sure all files and folders in the working directory are added to path
% Skips the right click "Add all to path" normally needed
% But does require right clicking initialize and clicking "Run"

fullPath = mfilename('fullpath');
codeFolder = fileparts(fullPath);
mainFolder = fullfile(fileparts(codeFolder));

addpath( genpath(mainFolder) )