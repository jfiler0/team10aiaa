function writeStoreStruct(short_name, full_name, weight, length, diameter, type, fuel_vol)

settings = readSettings(); % its okay to read it like this if it is not in a tight loop

% short_name - a simple, good file format name (no spaces)
% full_name - a full string that can include space
% weight - in Newtons
% length - in meters
% diameter - in m2 (ignore fins, focus on the body)
% type - matched to codes in settings
%   Missile - settings.codes.MISSILE
%   Bomb - settings.codes.BOMB
%   Tank - settings.codes.TANK
%       * The type lookups are inputs to how the drag is calculated
% fuel_vol - liters

if(nargin < 7)
    fuel_vol = 0;
end

comp = struct();

comp.short_name = json_entry("File Name", short_name, "s");
comp.full_name = json_entry("Full Name", full_name, "s");
comp.weight = json_entry("Weight", weight, "N");
comp.length = json_entry("Length", length, "m");
comp.diameter = json_entry("Diameter", diameter, "m");
comp.frontal_area = json_entry("Frontal Area", pi * (diameter/2)^2, "m2");

comp.type = json_entry("Store Type Code", type, "");
comp.fuel_vol = json_entry("Fuel Volume", fuel_vol, "L");

comp.rack_num = 0; % starting at 1 at the left wingtip. Is set in setLoadout
comp.rack_ypos = 0; % normalized by wingspan. Is set in setLoadout

fullPath = mfilename('fullpath');
codeFolder = fileparts(fullPath);
saveFile = fullfile(codeFolder, "../..","Aircraft Files/Stores", comp.short_name.v + ".json");
% If this is changed, setLoadout must also be changed

jsonText = jsonencode(comp, 'PrettyPrint', true);

% Write JSON text to a file
fileID = fopen(saveFile, 'w');
fwrite(fileID, jsonText, 'char');
fclose(fileID);

end