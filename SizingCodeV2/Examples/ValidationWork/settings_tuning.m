matlabSetup

settings = readSettings();
settings.TSFC_scaler = 1;

[res_hornet, des_hornet] = eval_hornet_error(settings);
res_hornet_tot = norm(res_hornet);

T = table();
T.("Error Name") = des_hornet';
T.("Percent Error") = 100 *res_hornet';

disp(T)
fprintf("Total error for the hornet: %.2f percent \n", 100*res_hornet_tot )