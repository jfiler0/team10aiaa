% Starts the console interaction program

initialize;
matlabSetup;

console = console_class();

% cond order: H, MV, N, W, T

commandList = ["load f18_superhornet"];
% commandList = ["load kevin_cad","INSPECT","GRAPHING", "maxPerformance"];
% commandList = ["load kevin_cad","geomInfo", "inspect", "printCostBreakdown"];
% commandList = ["load f18_superhornet", "geomInfo", "INSPECT", "setCond", "0", "2", "1", "1", "1", "printData", "GRAPHING", "geomView"];
% commandList = ["load f18_superhornet", "geomInfo", "INSPECT", "setCond", "10000", "2", "1", "1", "1", "printData", "q"];
% commandList = ["load f18_superhornet","INSPECT","GRAPHING", "maxSustainedTurn"];

console.start(commandList);