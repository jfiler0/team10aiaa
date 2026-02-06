function K1 = K1_basic(in)
    e_osw = 0.85; % *** update this
    k1_sub = 1 / (pi * e_osw * in.geom.wing.AR.v); % can pass in directy since it does not have M
    K1 = transonicMerge(@(in) k1_sub, ... 
        @(in) in.geom.wing.AR.v * (in.cond.M.v.^2 - 1) ./ (4*in.geom.wing.AR.v * sqrt(in.cond.M.v.^2 - 1) -2) * cosd(in.geom.wing.le_sweep.v) , ...
            in );
end
