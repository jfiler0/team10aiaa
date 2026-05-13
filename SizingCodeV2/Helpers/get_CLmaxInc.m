function dCLmax = get_CLmaxInc(le_code, te_code, settings)

    % from the raymer book. Estimated increase in the maximum lift coefficent
    codes = settings.codes;
    dCLmax = 0;

    switch te_code
        case codes.TE_DEVICE_PLAIN
            dCLmax = dCLmax + 0.9;
        case codes.TE_DEVICE_FOWLER
            dCLmax = dCLmax + 1.3; % raymer also has a scaler for the chord increase
        case codes.TE_DEVICE_SPLIT
            dCLmax = dCLmax + 0.9;
        case codes.TE_DEVICE_SLOTTED
            dCLmax = dCLmax + 1.3;
        case codes.TE_DEVICE_DOUBLE_SLOTTED
            dCLmax = dCLmax + 1.6; % raymer also has a scaler for the chord increase
        case codes.TE_DEVICE_TRIPLE_SLOTTED
            dCLmax = dCLmax + 1.9; % raymer also has a scaler for the chord increase
    end

    switch le_code
        case codes.LE_DEVICE_SLOT
            dCLmax = dCLmax + 0.2;
        case codes.LE_DEVICE_FLAP
            dCLmax = dCLmax + 0.3;
        case codes.LE_DEVICE_SLAT
            dCLmax = dCLmax + 0.4; % raymer also has a scaler for the chord increase
        case codes.LE_DEVICE_KRUGER
            dCLmax = dCLmax + 0.3;
    end
end