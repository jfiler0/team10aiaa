function alpha = find_lapse_rate(h, M, AB_frac, plane)

    T_min = 1000;
    T_max = 13000;

    alpha_dry = queryAlpha(h, M);
    alpha_ab = queryAlpha(h, M);
    alpha = ( T_min*alpha_dry + AB_frac*( alpha_ab*T_max - alpha_dry*T_min ) )/T_max;

end