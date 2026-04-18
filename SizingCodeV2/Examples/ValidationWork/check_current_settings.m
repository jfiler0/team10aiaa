matlabSetup
settings = readSettings();

% X = [settings.TSFC_scaler, settings.CDp_scaler, settings.CDw_scaler, settings.TA_scaler];

% settings.CD0_scaler = X(1); % general scaler to parasite drag
% settings.CDi_scaler = X(2);
% settings.CDw_scaler = X(3); % general scaler to wave drag
% settings.CLa_scaler = X(4);
% settings.CDp_scaler = X(5);
% settings.TA_scaler = X(6);
% settings.TSFC_scaler = X(7); % 1.3
% settings.WE_scaler = X(8); % scales all components and the final empty weight 0.8752
% settings.WF_ratio =  X(9); % WF = WF_ratio * (MTOW - WE) -> internal fuel weight

X = [settings.CD0_scaler, settings.CDi_scaler, settings.CDw_scaler, settings.CLa_scaler, settings.CDp_scaler, settings.TA_scaler, settings.TSFC_scaler, settings.WE_scaler, settings.WF_ratio];

settings_tuning(X, true)

% 1.7284 -> using engine face