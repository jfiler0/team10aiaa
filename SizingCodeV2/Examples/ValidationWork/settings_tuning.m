function res = settings_tuning(X, print, enabled_scalers)

% X -> input vector of different settings to change
% print -> toggles the tables

% returns variable which is a measure of model error

%% CHANGE THE SCALERS

settings = readSettings();

names = fieldnames(settings.scalers);
idx = 1;
for i = 1:length(names)
    if(enabled_scalers(i)==1)
        scale_len = length(settings.scalers.(names{i}).return_current_scalers()); % number of scalers
        settings.scalers.(names{i}) = settings.scalers.(names{i}).set_current_scalers(X(idx:idx+scale_len-1));
        idx = idx + scale_len;
    end
end

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

% fprintf("Average error: %.3f perc\n",100*mean(abs([data_hornet.res, data_falcon.res, data_tomcat.res, data_corsair.res])))
% fprintf("Average error (f18): %.3f perc\n",100*mean(abs(data_hornet.res)))
% fprintf("Average error (f16): %.3f perc\n",100*mean(abs(data_falcon.res)))
% fprintf("Average error (f14): %.3f perc\n",100*mean(abs(data_tomcat.res)))
% fprintf("Average error (f7e): %.3f perc\n",100*mean(abs(data_corsair.res)))


end