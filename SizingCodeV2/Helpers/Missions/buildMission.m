function mission_obj = buildMission(name, segObjs,  loadout)
    name = matlab.lang.makeValidName(name);
    
    mission_obj = struct();
    mission_obj.name = json_entry("Name", name, "s");
    mission_obj.segObjs = segObjs;
    mission_obj.loadout = loadout;
end