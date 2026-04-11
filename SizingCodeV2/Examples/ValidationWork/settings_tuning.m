function res = settings_tuning(X, print)

% X -> input vector of different settings to change
% print -> toggles the tables

% returns variable which is a measure of model error

%% CHANGE THE SCALERS
settings = readSettings();

settings.TSFC_scaler = X(1);
settings.CDp_scaler = X(2);
settings.TA_scaler = X(3);
settings.CDw_scaler  = X(4);

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

%% BUILD MISSIONS - Falcon
Hi_Hi_Hi = { ...
    missionSeg("TAKEOFF", 'FIXED_WF', [0.98, 5]), ... % basic takeoff
    missionSeg("CRUISE_OUT", 'CRUISE', nm2m(305), [kt2ms(501) NaN], [ft2m(42000) NaN] ), ... % using the best range number from charcteristics doc
    missionSeg("COMBAT", 'COMBAT', [2, 3, 1, 8], [NaN, NaN], [ft2m(30000), NaN] ), ... % 2 min at afterburning subs 5 at intermediate thrust. Deploy both Aim9x. Drop to 30000
    missionSeg("CRUISE_BACK", 'CRUISE', nm2m(305), [kt2ms(501) NaN], [ft2m(42000) NaN] ), ... % using the best range number from charcteristics doc
    missionSeg("LOITER", 'LOITER', 10, [NaN, NaN], [ft2m(10000), NaN] ), ... % maintain 10kf for 20 minutes
    missionSeg("APPROACH", 'LOITER', 5, [NaN, NaN], [ft2m(10000), 0] ), ... % descend from 10kf to sealevel in 5 minutes
    missionSeg("LANDING", 'FIXED_WF', [0.98, 5]) }; % basic landing/taxi
writeMissionStruct(Hi_Hi_Hi, "Falcon_Hi_Hi_Hi", ["AIM-9X" "" "370GAL" "" "" "370GAL" "" "AIM-9X"]);

Intercept = { ...
    missionSeg("TAKEOFF", 'FIXED_WF', [0.98, 5]), ... % basic takeoff
    missionSeg("CRUISE_OUT", 'CRUISE', nm2m(367/2), [kt2ms(660) NaN], [ft2m(42000) NaN] ), ... % using the best range number from charcteristics doc
    missionSeg("COMBAT", 'COMBAT', [4, 3, 1, 8], [NaN, NaN], [ft2m(30000), NaN] ), ... % 4 min at afterburning subs 5 at intermediate thrust. Deploy both Aim9x. Drop to 30000
    missionSeg("CRUISE_BACK", 'CRUISE', nm2m(367/2), [kt2ms(550) NaN], [ft2m(42000) NaN] ), ... % using the best range number from charcteristics doc
    missionSeg("LOITER", 'LOITER', 10, [NaN, NaN], [ft2m(10000), NaN] ), ... % maintain 10kf for 20 minutes
    missionSeg("APPROACH", 'LOITER', 5, [NaN, NaN], [ft2m(10000), 0] ), ... % descend from 10kf to sealevel in 5 minutes
    missionSeg("LANDING", 'FIXED_WF', [0.98, 5]) }; % basic landing/taxi
writeMissionStruct(Intercept, "Falcon_Intercept", ["AIM-9X" "" "370GAL" "" "" "370GAL" "" "AIM-9X"]);

%% BUILD MISSIONS - Corsair
Hi_Hi_Hi = { ...
    missionSeg("TAKEOFF", 'FIXED_WF', [0.98, 5]), ... % basic takeoff
    missionSeg("CRUISE_OUT", 'CRUISE', nm2m(894), [kt2ms(479) NaN], [ft2m(42000) NaN] ), ... % using the best range number from charcteristics doc
    missionSeg("CRUISE_BACK", 'CRUISE', nm2m(894), [kt2ms(479) NaN], [ft2m(42000) NaN] ), ... % using the best range number from charcteristics doc
    missionSeg("LOITER", 'LOITER', 10, [NaN, NaN], [ft2m(10000), NaN] ), ... % maintain 10kf for 20 minutes
    missionSeg("APPROACH", 'LOITER', 5, [NaN, NaN], [ft2m(10000), 0] ), ... % descend from 10kf to sealevel in 5 minutes
    missionSeg("LANDING", 'FIXED_WF', [0.98, 5]) }; % basic landing/taxi
writeMissionStruct(Hi_Hi_Hi, "Corsair_Hi_Hi_Hi", ["" "" "" "" "" "" "" ""]);

%% TEST RUNS

data_hornet = eval_hornet_error(settings);
res_hornet_tot = norm(data_hornet.res);

data_falcon = eval_falcon_error(settings);
res_falcon_tot = norm(data_falcon.res);

data_tomact = eval_tomcat_error(settings);
res_tomcat_tot = norm(data_tomact.res);

data_corsair = eval_corsair_error(settings);
res_corsair_tot = norm(data_corsair.res);

if print
    T = table();
    T.("Error Name") = data_hornet.des';
    T.("Percent Error") = 100 *data_hornet.res';
    T.("Computed") = data_hornet.val';
    T.("Target") = data_hornet.tar';
    
    disp(T)
    fprintf("Total error for the hornet: %.2f percent \n", 100*res_hornet_tot )
    
    T = table();
    T.("Error Name") = data_falcon.des';
    T.("Percent Error") = 100 *data_falcon.res';
    T.("Computed") = data_falcon.val';
    T.("Target") = data_falcon.tar';
    
    disp(T)
    fprintf("Total error for the falcon: %.2f percent \n", 100*res_falcon_tot )
    
    T = table();
    T.("Error Name") = data_tomact.des';
    T.("Percent Error") = 100 *data_tomact.res';
    T.("Computed") = data_tomact.val';
    T.("Target") = data_tomact.tar';
    
    disp(T)
    fprintf("Total error for the tomcat: %.2f percent \n", 100*res_tomcat_tot )
    
    T = table();
    T.("Error Name") = data_corsair.des';
    T.("Percent Error") = 100 *data_corsair.res';
    T.("Computed") = data_corsair.val';
    T.("Target") = data_corsair.tar';
    
    disp(T)
    fprintf("Total error for the corsair: %.2f percent \n", 100*res_corsair_tot )
end

res = norm([data_hornet.res data_falcon.res data_tomact.res data_corsair.res]);

end