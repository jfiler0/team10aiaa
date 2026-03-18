Ferry_700nm = { ...
    missionSeg("TAKEOFF", 'FIXED_WF', [0.98, 5]), ... % basic takeoff
    missionSeg("CRUISE_FREE", 'CRUISE', nm2m(50), [NaN, NaN], [0, ft2m(10000)] ), ... % Climb to 10kf in 50nm
    missionSeg("CRUISE_FREE", 'CRUISE', nm2m(1400-50)), ... % Unconsrained cruise
    missionSeg("LOITER", 'LOITER', 20, [NaN, NaN], [ft2m(10000), NaN] ), ... % maintain 10kf for 20 minutes
    missionSeg("APPROACH", 'LOITER', 5, [NaN, NaN], [ft2m(10000), 0] ), ... % descend from 10kf to sealevel in 5 minutes
    missionSeg("LANDING", 'FIXED_WF', [0.98, 5])}; % basic landing/taxi

writeMissionStruct(Ferry_700nm, "Ferry_700nm",  ["AIM-9X" "" "" "" "" "" "" "AIM-9x"]);

Air2Air_700nm = { ...
    missionSeg("TAKEOFF", 'FIXED_WF', [0.98, 5]), ... % basic takeoff
    missionSeg("CLIMB_1", 'CRUISE', nm2m(50), [NaN, NaN], [0, ft2m(10000)] ), ... % Climb to 10kf in 50nm
    missionSeg("CRUISE_1", 'CRUISE', nm2m(650),[350,NaN]), ... % Unconsrained cruise for 700nm
    missionSeg("LOITER", 'LOITER', 20, [NaN, NaN], [ft2m(10000), NaN] ), ... % maintain 10kf for 20 minutes
    missionSeg("COMBAT", 'COMBAT', [8, 3, 1, 2, 3], [NaN, NaN], [ft2m(10000), NaN] ), ... %8 minutes of combat, full throttle, holing 3 Gs. Deploy racks 1,2,3
    missionSeg("CLIMB_2", 'CRUISE', nm2m(50), [NaN, NaN], [0, ft2m(10000)] ), ... % Climb to 10kf in 50nm
    missionSeg("CRUISE_2", 'CRUISE', nm2m(650)), ... % Unconsrained cruise for 700nm
    missionSeg("APPROACH", 'LOITER', 5, [NaN, NaN], [ft2m(10000), 0] ), ... % descend from 10kf to sealevel in 5 minutes
    missionSeg("LANDING", 'FIXED_WF', [0.98, 5])}; % basic landing/taxi

writeMissionStruct(Air2Air_700nm, "Air2Air_700nm",  ["AIM-9X" "AIM-9X" "AIM-120" "" "" "AIM-120" "AIM-9X" "AIM-9x"]);

Air2Gnd_700nm = { ...
    missionSeg("TAKEOFF", 'FIXED_WF', [0.98, 5]), ... % basic takeoff
    missionSeg("CLIMB_1", 'CRUISE', nm2m(50), [NaN, NaN], [0, ft2m(10000)] ), ... % Climb to 10kf in 50nm
    missionSeg("CRUISE_1", 'CRUISE', nm2m(600)), ... % Unconsrained cruise for 700nm
    missionSeg("DESCENT", 'CRUISE', nm2m(50), [NaN, 250], [NaN, 200] ), ...
    missionSeg("INTERDICTION", 'CRUISE', nm2m(20), [250, NaN], [200, NaN] ), ...
    missionSeg("COMBAT", 'COMBAT', [8, 3, 1, 2, 3], [NaN, NaN], [200, NaN] ), ... %8 minutes of combat, full throttle, holing 3 Gs. Deploy racks 1,2,3
    missionSeg("CLIMB OUT", 'CRUISE', nm2m(50), [250, NaN], [1000, ft2m(10000)] ), ...
    missionSeg("CRUISE_2", 'CRUISE', nm2m(650)), ... % Unconsrained cruise for 700nm
    missionSeg("APPROACH", 'LOITER', 5, [NaN, NaN], [ft2m(10000), 0] ), ... % descend from 10kf to sealevel in 5 minutes
    missionSeg("LANDING", 'FIXED_WF', [0.98, 5])}; % basic landing/taxi

writeMissionStruct(Air2Gnd_700nm, "Air2Gnd_700nm",  ["AIM-9X" "Mk-83" "Mk-83" "" "" "Mk-83" "Mk-83" "AIM-9x"]);

% OLD STUFF FROM SIZING 1

% %% Define Loadouts
%     % When applied to a plane they set extra payload weight, can add to potential fuel volume (if a tank), and add to CD0
%     clean_loadout = buildLoadout(["AIM-9X", "AIM-9X"]); % Just the sidewinders
%     ferry_loadout = buildLoadout(["AIM-9X", "FPU-12", "FPU-12", "FPU-12", "AIM-9X"]); % Three tanks
%     strike_loadout = buildLoadout(["AIM-9X", "FPU-12", "MK-83", "MK-83", "MK-83", "MK-83", "FPU-12", "AIM-9X"]); % 4 Mk83 bombs
%     air2air_loadout = buildLoadout(["AIM-9X", "AIM-120", "AIM-120", "AIM-120", "FPU-12", "AIM-120", "AIM-120", "AIM-120", "AIM-9X"]); % 6 amraams

%     air2air_700 = mission( [...
%         flightSegment2("TAKEOFF") 
%         flightSegment2("CLIMB", 0.7) 
%         flightSegment2("CRUISE", NaN, NaN, nm2m(700))
%         flightSegment2("LOITER", NaN, 10000, 20) % 20 min loiter
%         flightSegment2("COMBAT", 0.8, 1000, [8 0.5]) % 8 minutes of combat, deploy 50% of payload
%         flightSegment2("CRUISE", NaN, NaN, nm2m(700))
%         flightSegment2("LANDING") ] , ...
%         ...
%         air2air_loadout, "700nm Air 2 Air");
% 
%     % 5 cruise segments * 10 divisions * 93 function calls * 50 max internal function calls
% 
%     air2ground_700 = mission( [...
%         flightSegment2("TAKEOFF") 
%         flightSegment2("CLIMB", 0.85) % Check this mach
%         flightSegment2("CRUISE", NaN, NaN, nm2m(700)) % 700 nm flight
%         flightSegment2("LANDING") % Saying this is decent
%         flightSegment2("LOITER", NaN, ft2m(10000), 10) % 10 min loiter
%         flightSegment2("CLIMB", 0.85) % Check this mach
%         flightSegment2("CRUISE", 0.85, NaN, nm2m(50)) % Penetrate
%         flightSegment2("COMBAT", 0.85, 1000, [30/60 0]) % quick combat ***
%         flightSegment2("CLIMB", 0.85) % Check this mach
%         flightSegment2("CRUISE", NaN, NaN, nm2m(700)) % 700 nm flight
%         flightSegment2("LOITER", NaN, ft2m(10000), 20) % 20 min loiter
%         flightSegment2("LANDING") ] , ...
%         ...
%         strike_loadout, "700nm Strike");
% 
%     missionList = [air2ground_700 air2air_700]; % Missions to constraint

