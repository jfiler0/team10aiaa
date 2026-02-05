function CDi = CDi_simple(in)
    CDi = K1_basic(in) * in.cond.CL.v ^ 2 + K2_basic(in) * in.cond.CL.v;
end