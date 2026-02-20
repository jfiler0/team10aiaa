%% callcomponenttable function

% The point of this code is to call the table of component weights,
% locations, or other properties for each component in our aircraft.

% The code will read the table from an excel file (or csv file) and then
% bring forth the data from the file as a matlab table object.

function component_table = callcomponenttable()

component_table = readtable('ComponentTable.xlsx');

end