function res = settings_tuning(X, print)

% X -> input vector of different settings to change
% print -> toggles the tables

% returns variable which is a measure of model error

%% CHANGE THE SCALERS

settings = readSettings();

settings.CD0_scaler = X(1); % general scaler to parasite drag
settings.CDi_scaler = X(2);
settings.CDw_scaler = X(3); % general scaler to wave drag
settings.CLa_scaler = X(4);
settings.CDp_scaler = X(5);
settings.TA_scaler = X(6);
settings.TSFC_scaler = X(7); % 1.3
settings.WE_scaler = X(8); % scales all components and the final empty weight 0.8752
settings.WF_ratio =  X(9); % WF = WF_ratio * (MTOW - WE) -> internal fuel weight

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

try
    data_hornet = eval_hornet_error(settings);
    res_hornet_tot = norm(rmmissing(data_hornet.res));
    
    data_falcon = eval_falcon_error(settings);
    res_falcon_tot = norm(rmmissing(data_falcon.res));

    data_tomcat = eval_tomcat_error(settings);
    res_tomcat_tot = norm(rmmissing(data_tomcat.res));

    data_corsair = eval_corsair_error(settings);
    res_corsair_tot = norm(rmmissing(data_corsair.res));
catch Exception
    res = 1e6; % better than crashing
    warning("Hit an error: %s", Exception.message);
    return
end

if print

    % --- Build all four tables ---
    datasets = {data_hornet, data_falcon, data_tomcat, data_corsair};
    labels   = {'Hornet', 'Falcon', 'Tomcat', 'Corsair'};
    totals   = [res_hornet_tot, res_falcon_tot, res_tomcat_tot, res_corsair_tot];

    % Resolve output path to same folder as this script
    script_dir = fileparts(mfilename('fullpath'));
    xlsx_path  = fullfile(script_dir, 'settings_tuning_results.xlsx');

    % Delete stale file so old sheets don't persist
    if isfile(xlsx_path)
        delete(xlsx_path);
    end

    for k = 1:4

        d = datasets{k};

        T = table();
        T.("Error Name")    = d.des';
        T.("Percent Error") = 100 * d.res';
        T.("Computed")      = d.val';
        T.("Target")        = d.tar';

        % Console display
        disp(T)
        fprintf("Total error for the %s: %.2f percent\n", lower(labels{k}), 100 * totals(k));

        % Write sheet — writetable appends a new sheet each call
        writetable(T, xlsx_path, 'Sheet', labels{k});

    end

    % --- Summary sheet ---
    S = table(labels', 100 * totals', ...
        'VariableNames', {'Aircraft', 'Total_Error_Pct'});
    writetable(S, xlsx_path, 'Sheet', 'Summary');

    fprintf("\nResults written to: %s\n", xlsx_path);

end

weighting = [3, 1, 0.5, 1]; % F18, F16, F14, A-7E

res = norm( weighting.*[res_hornet_tot, res_falcon_tot, res_tomcat_tot, res_corsair_tot]/norm(weighting) );

fprintf("Average error: %.3f perc\n",100*mean(abs([data_hornet.res, data_falcon.res, data_tomcat.res, data_corsair.res])))

end