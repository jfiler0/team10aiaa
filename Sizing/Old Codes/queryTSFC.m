function TSFC = queryTSFC(h, M, engine)
    if(isnan(h) || isnan(M)) % Needs to be robust
        TSFC = NaN;
    else
        TSFC = 1E-4; % kg/Ns
    end
end