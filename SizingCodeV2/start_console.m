% Starts the console interaction program

initialize;
matlabSetup;

console = console_class();

% cond order: H, MV, N, W, T

% commandList = ["load HellstingerV3"];


commandList = ["load f18_superhornet"];


% commandList = ["load kevin_cad","INSPECT","GRAPHING", "maxPerformance"];

% commandList = ["load f18_superhornet", "geomInfo", "INSPECT", "setCond", "0", "2", "1", "1", "1", "printData", "GRAPHING", "geomView"];

commandList = [];


% commandList = ["load f18_superhornet", "INSPECT", "print"];


% commandList = ["load f18_superhornet", "geomInfo", "INSPECT", "setCond", "0", "2", "1", "1", "1", "printData"];

% commandList = ["load kevin_cad"];
% commandList = ["load HellstingerV3","geomInfo", "inspect", "printCostBreakdown"];
% commandList = ["load kevin_cad","INSPECT","GRAPHING", "maxPerformance"];

% commandList = ["load f18_superhornet", "geomInfo", "INSPECT", "setCond", "10000", "2", "1", "1", "1", "printData", "q"];

%commandList = ["load f18_superhornet","INSPECT","GRAPHING", "levelFlightPerformance"];

%commandList = ["load Hellstingerv3", "INSPECT","GRAPHING", "geomView"];
console.start(commandList);