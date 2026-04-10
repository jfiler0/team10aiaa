matlabSetup

%% CHANGE THE SCALERS
settings = readSettings();
settings.TSFC_scaler = 1.65;

%% BUILD MISSIONS - Hornet
Hi_Hi_Hi = { ...
    missionSeg("TAKEOFF", 'FIXED_WF', [0.98, 5]), ... % basic takeoff
    missionSeg("CRUISE_OUT", 'CRUISE', nm2m(597), [kt2ms(484) NaN], [ft2m(40000) NaN] ), ... % using the best range number from charcteristics doc
    missionSeg("COMBAT", 'COMBAT', [2, 3, 1, 8], [NaN, NaN], [ft2m(30000), NaN] ), ... % 2 min at afterburning subs 5 at intermediate thrust. Deploy both Aim9x. Drop to 30000
    missionSeg("CRUISE_BACK", 'CRUISE', nm2m(597), [kt2ms(484) NaN], [ft2m(40000) NaN] ), ... % using the best range number from charcteristics doc
    missionSeg("LOITER", 'LOITER', 20, [NaN, NaN], [ft2m(10000), NaN] ), ... % maintain 10kf for 20 minutes
    missionSeg("APPROACH", 'LOITER', 5, [NaN, NaN], [ft2m(10000), 0] ), ... % descend from 10kf to sealevel in 5 minutes
    missionSeg("LANDING", 'FIXED_WF', [0.98, 5]) }; % basic landing/taxi
writeMissionStruct(Hi_Hi_Hi, "Hornet_Hi_Hi_Hi", ["AIM-9X" "" "" "" "" "" "" "AIM-9X"]);

% hi hi hi but with 2 aim 120s
Hi_Hi_Hi{2} = missionSeg("CRUISE_OUT", 'CRUISE', nm2m(574), [kt2ms(484) NaN], [ft2m(40000) NaN] );
Hi_Hi_Hi{4} = missionSeg("CRUISE_BACK", 'CRUISE', nm2m(574), [kt2ms(484) NaN], [ft2m(40000) NaN] );
writeMissionStruct(Hi_Hi_Hi, "Hornet_Hi_Hi_Hi_AIM120", ["AIM-9X" "AIM-120" "" "" "" "" "AIM-120" "AIM-9X"]);

% hi hi hi but with 1 tank
Hi_Hi_Hi{2} = missionSeg("CRUISE_OUT", 'CRUISE', nm2m(676), [kt2ms(484) NaN], [ft2m(40000) NaN] );
Hi_Hi_Hi{4} = missionSeg("CRUISE_BACK", 'CRUISE', nm2m(676), [kt2ms(484) NaN], [ft2m(40000) NaN] );
writeMissionStruct(Hi_Hi_Hi, "Hornet_Hi_Hi_Hi_1TANK", ["AIM-9X" "" "" "" "FPU-12" "" "" "AIM-9X"]);

% hi hi hi but with 3 tank
Hi_Hi_Hi{2} = missionSeg("CRUISE_OUT", 'CRUISE', nm2m(759), [kt2ms(484) NaN], [ft2m(40000) NaN] );
Hi_Hi_Hi{4} = missionSeg("CRUISE_BACK", 'CRUISE', nm2m(759), [kt2ms(484) NaN], [ft2m(40000) NaN] );
writeMissionStruct(Hi_Hi_Hi, "Hornet_Hi_Hi_Hi_3TANK", ["AIM-9X" "" "" "FPU-12" "FPU-12" "FPU-12" "" "AIM-9X"]);

Intercept = { ...
    missionSeg("TAKEOFF", 'FIXED_WF', [0.98, 5]), ... % basic takeoff
    missionSeg("CRUISE_OUT", 'CRUISE', nm2m(201), [1.4*295 NaN], [ft2m(40000) NaN] ), ... % estimating M1.4
    missionSeg("COMBAT", 'COMBAT', [2, 3, 1, 2, 7, 8], [NaN, NaN], [ft2m(30000), NaN] ), ... % 2 min at Deploy both Aim9x + AIM120. Drop to 30000
    missionSeg("CRUISE_BACK", 'CRUISE', nm2m(201), [kt2ms(482) NaN], [ft2m(40000) NaN] ), ... % assume we can cruise back
    missionSeg("LOITER", 'LOITER', 20, [NaN, NaN], [ft2m(10000), NaN] ), ... % maintain 10kf for 20 minutes
    missionSeg("APPROACH", 'LOITER', 5, [NaN, NaN], [ft2m(10000), 0] ), ... % descend from 10kf to sealevel in 5 minutes
    missionSeg("LANDING", 'FIXED_WF', [0.98, 5]) }; % basic landing/taxi
writeMissionStruct(Intercept, "Hornet_Intercept", ["AIM-9X" "AIM-120" "" "" "FPU-12" "" "AIM-120" "AIM-9X"]);

Intercept{2} = missionSeg("CRUISE_OUT", 'CRUISE', nm2m(279), [1.4*295 NaN], [ft2m(40000) NaN] );
Intercept{4} = missionSeg("CRUISE_BACK", 'CRUISE', nm2m(279), [kt2ms(482) NaN], [ft2m(40000) NaN] );
writeMissionStruct(Intercept, "Hornet_Intercept_3TANK", ["AIM-9X" "AIM-120" "" "FPU-12" "FPU-12" "FPU-12" "AIM-120" "AIM-9X"]);

%% TEST RUNS

data_hornet = eval_hornet_error(settings);
res_hornet_tot = norm(data_hornet.res);

T = table();
T.("Error Name") = data_hornet.des';
T.("Percent Error") = 100 *data_hornet.res';
T.("Computed") = data_hornet.val';
T.("Target") = data_hornet.tar';

disp(T)
fprintf("Total error for the hornet: %.2f percent \n", 100*res_hornet_tot )