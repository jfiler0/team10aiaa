fullPath = mfilename('fullpath');
codeFolder = fileparts(fullPath);
mainFolder = fullfile(fileparts(codeFolder));

disp(mainFolder)

addpath( genpath(mainFolder) )