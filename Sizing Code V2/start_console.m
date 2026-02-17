% Starts the console interaction program

initialize;
matlabSetup;

console = console_class();

commandList = [];
% commandList = ["load f18_superhornet", "geomInfo", "INSPECT", "setCond", "0", "0.6", "6", "0.5", "0.66", "printData", "q"];

console.start(commandList);