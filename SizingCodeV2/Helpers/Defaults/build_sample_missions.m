ferry_mission = { ...
    missionSeg("TAKEOFF", 'FIXED_WF', 0.98), ... % basic takeoff
    missionSeg("CLIMB", 'LOITER', 5, [NaN, 400], [0, ft2m(30000)] ), ... % climb to 30kf at a fixed climb rate in 5 minutes
    missionSeg("CRUISE_30", 'CRUISE', nm2m(500), [NaN, NaN], [ft2m(30000), NaN] ), ... % maintain 30kf for 500 nm
    missionSeg("CRUISE_FREE", 'CRUISE', nm2m(500)), ... % Unconsrained cruise for 500 nm
    missionSeg("CRUISE_COMPLEX", 'CRUISE', nm2m(500), [150, 260], [NaN, 0] ), ... % Slow to M0.4, go for 500 nm, end at M0.8 at sealevel
    missionSeg("LOITER", 'LOITER', 20, [NaN, NaN], [ft2m(10000), NaN] ), ... % maintain 10kf for 20 minutes
    missionSeg("APPROACH", 'LOITER', 5, [NaN, NaN], [ft2m(10000), 0] ), ... % descend from 10kf to sealevel in 5 minutes
    missionSeg("LANDING", 'FIXED_WF', 0.98)}; % basic landing/taxi

writeMissionStruct(ferry_mission, "Ferry_Mission_Test");

simple_range_mission = { ...
    missionSeg("CRUISE_1", 'CRUISE', nm2m(500), [NaN, NaN], [0, ft2m(30000)] ), ...
    missionSeg("CRUISE_2", 'CRUISE', nm2m(500), [NaN, NaN], [ft2m(30000), 0] ) };

writeMissionStruct(simple_range_mission, "Simple_Range_Mission");

simple_loiter_mission = { ...
    missionSeg("LOITER", 'LOITER', 30, [NaN, NaN], [2000, NaN] )};

writeMissionStruct(simple_loiter_mission, "Simple_Loiter_Mission");

