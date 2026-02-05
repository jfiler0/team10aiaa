function CDW = CDW_basic(in)
    E_WD = in.geom.fuselage.E_WD.v;
    M_CD0_max = 1/(cosd(in.geom.wing.le_sweep.v))^0.2;

    % some imaginary values pop out sometimes
    CDW = real( transonicMerge(@(in) 0, ... 
        @(in) (4.5 * pi / in.geom.ref_area.v) * ( in.geom.fuselage.max_area.v / in.geom.fuselage.length.v ) ^ 2 * ...
            E_WD * ( 0.74 + 0.37 * cosd(in.geom.wing.le_sweep.v) ) * ( 1 - 0.3 * sqrt( in.cond.M.v - M_CD0_max )) , ...
            in ) );
end