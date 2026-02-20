% Starts the console interaction program

initialize;
matlabSetup;

console = console_class();

% cond order: H, MV, N, W, T

commandList = [];
% commandList = ["load f18_superhornet", "geomInfo", "INSPECT", "setCond", "0", "2", "1", "1", "1", "printData", "GRAPHING", "geomView"];
% commandList = ["load f18_superhornet", "geomInfo", "INSPECT", "setCond", "10000", "2", "1", "1", "1", "printData", "q"];
% commandList = ["load f18_superhornet","INSPECT","setCond", "", "0.5", "", "", "", "printData"];

console.start(commandList);