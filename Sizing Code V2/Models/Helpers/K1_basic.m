function K1 = K1_basic(in)
    e_osw = 0.85; % *** update this
    k1_sub = 1 / (pi * e_osw * in.geometry.wing.AR.v); % can pass in directy since it does not have M
    K1 = transonicMerge(@(in) k1_sub, ... 
        @(in) in.geometry.wing.AR.v * (in.condition.M.^2 - 1) ./ (4*in.geometry.wing.AR.v * sqrt(in.condition.M.^2 - 1) -2) * cosd(in.geometry.wing.le_sweep.v) , ...
            in );
end
