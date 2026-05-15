matlabSetup
settings = readSettings();
X0 = [];
names = fieldnames(settings.scalers);
for i = 1:length(names)
    X0 = [X0, settings.scalers.(names{i}).return_current_scalers()];
end

enabled_scalers = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
settings_tuning(X0, true, enabled_scalers)