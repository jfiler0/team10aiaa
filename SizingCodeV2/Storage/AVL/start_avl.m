fullPath = mfilename('fullpath');
codeFolder = fileparts(fullPath);
avlPath = fullfile(codeFolder, "avl.exe");

cmd = sprintf('start cmd /k "cd /d "%s" && "%s" aircraft.avl"', codeFolder, avlPath);
system(cmd);