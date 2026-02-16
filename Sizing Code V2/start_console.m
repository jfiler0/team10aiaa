% Starts the console interaction program

initialize;
matlabSetup;

console = console_class();

commandList = [];
commandList = ["load f18_superhornet", "INSPECT"];

console.start(commandList);