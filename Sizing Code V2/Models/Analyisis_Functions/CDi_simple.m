function CDi = CDi_simple(in)
    CDi = K1_basic(in) * in.condition.CL ^ 2 + K2_basic(in) * in.condition.CL;
end