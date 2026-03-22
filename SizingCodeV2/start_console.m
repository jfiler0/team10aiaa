% Starts the console interaction program

initialize;
matlabSetup;

console = console_class();

% cond order: H, MV, N, W, T

commandList = ["load f18_superhornet"];
<<<<<<< HEAD

% commandList = ["load kevin_cad"];
% commandList = ["load kevin_cad","geomInfo", "inspect", "printCostBreakdown"];
=======
% commandList = ["load kevin_cad","INSPECT","GRAPHING", "maxPerformance"];

>>>>>>> 235083e7a9c978098dd0c8d10967886361c01020
% commandList = ["load f18_superhornet", "geomInfo", "INSPECT", "setCond", "0", "2", "1", "1", "1", "printData", "GRAPHING", "geomView"];
% commandList = ["load f18_superhornet", "geomInfo", "INSPECT", "setCond", "10000", "2", "1", "1", "1", "printData", "q"];
% commandList = ["load f18_superhornet","INSPECT","GRAPHING", "maxSustainedTurn"];

console.start(commandList);