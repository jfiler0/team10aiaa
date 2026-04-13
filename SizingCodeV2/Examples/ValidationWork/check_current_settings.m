matlabSetup
settings = readSettings();

X = [settings.TSFC_scaler, settings.CDp_scaler, settings.CDw_scaler, settings.TA_scaler];

settings_tuning(X, true)

% 1.7284 -> using engine face