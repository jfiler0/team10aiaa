function CDW = CDW_basic(in)
    E_WD = in.geometry.fuselage.E_WD.v;
    M_CD0_max = 1/(cosd(in.geometry.wing.le_sweep.v))^0.2;

    % some imaginary values pop out sometimes
    CDW = real( transonicMerge(@(in) 0, ... 
        @(in) (4.5 * pi / in.geometry.ref_area.v) * ( in.geometry.fuselage.max_area.v / in.geometry.fuselage.length.v ) ^ 2 * ...
            E_WD * ( 0.74 + 0.37 * cosd(in.geometry.wing.le_sweep.v) ) * ( 1 - 0.3 * sqrt( in.condition.M - M_CD0_max )) , ...
            in ) );
end