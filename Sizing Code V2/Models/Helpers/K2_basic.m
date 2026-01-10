function K2 = K2_basic(in)

    % CL_min_D = CL_alpha_wing*-obj.a0/2;
    % k1_sub = 1 / (pi * obj.e_osw* obj.AR);
    % k2_sub = -2 * obj.k1_sub * CL_min_D;
    k2_sub = 0;

    K2 = transonicMerge(@(in) k2_sub, @(in) 0, in );
end
